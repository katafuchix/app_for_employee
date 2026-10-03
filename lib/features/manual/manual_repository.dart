// manual_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'manual_models.dart';

class ManualRepository {
  const ManualRepository();

  /// ストアIDを取得する
  Future<String> fetchStoreId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('未ログインです。');
    }

    final uid = user.uid;
    final mapSnap = await FirebaseFirestore.instance
        .collection('worker_id_map')
        .doc(uid)
        .get();

    if (!mapSnap.exists) {
      throw Exception('worker_id_map にデータがありません。');
    }

    final data = mapSnap.data() as Map<String, dynamic>;
    final storeIdObj = data['store_id'];
    final storeId = (storeIdObj is String) ? storeIdObj.trim() : '';

    if (storeId.isEmpty) {
      throw Exception('store_id が未設定です。');
    }

    return storeId;
  }

  /// カテゴリー（と内部のフォルダ情報）を取得する
  Future<List<ManualCategory>> fetchCategories(String storeId) async {
    final col = FirebaseFirestore.instance
        .collection('store_data')
        .doc(storeId)
        .collection('manual_category');

    final qs = await col.get();

    final categories = <ManualCategory>[];

    for (final doc in qs.docs) {
      final data = doc.data();
      final title = (data['title'] is String) ? data['title'] as String : '';
      final color = (data['color'] is String) ? data['color'] as String : '';

      // ソート用日付取得
      final firstInteraction = _parseDate(
        _getNested(data, const ['metadata', 'first_interaction_time', 'date']),
      );

      // フォルダ情報のパース
      final folderInfosObj = data['folder_infos'];
      final folderInfos = (folderInfosObj is List) ? folderInfosObj : [];

      final folders = <ManualFolder>[];
      for (final raw in folderInfos) {
        final m = _toStringKeyMap(raw);
        final fId = (m['id'] is String) ? m['id'] as String : '';
        final fTitle = (m['title'] is String) ? m['title'] as String : '';
        // フォルダごとのソート用日付
        final fDate = _parseDate(
          _getNested(m, const ['metadata', 'first_interaction_time', 'date']),
        );

        if (fId.isNotEmpty) {
          folders.add(
            ManualFolder(id: fId, title: fTitle, firstInteractionTime: fDate),
          );
        }
      }

      // フォルダを新しい順にソート (PDF要件)
      folders.sort((a, b) {
        final dA = a.firstInteractionTime ?? DateTime(1900);
        final dB = b.firstInteractionTime ?? DateTime(1900);
        return dB.compareTo(dA); // 降順
      });

      categories.add(
        ManualCategory(
          id: doc.id,
          title: title,
          color: color,
          folders: folders,
          firstInteractionTime: firstInteraction,
        ),
      );
    }

    // カテゴリーを新しい順にソート (PDF要件)
    categories.sort((a, b) {
      final dA = a.firstInteractionTime ?? DateTime(1900);
      final dB = b.firstInteractionTime ?? DateTime(1900);
      return dB.compareTo(dA); // 降順
    });

    return categories;
  }

  /// マニュアル一覧（詳細含む）を取得する
  Future<List<Manual>> fetchManuals(String storeId) async {
    final manualCol = FirebaseFirestore.instance
        .collection('store_data')
        .doc(storeId)
        .collection('manual');

    // 基本的に全件取得してクライアント側で振り分ける
    final qs = await manualCol.orderBy('index', descending: false).get();

    // indexソートが効かない場合のフォールバックは省略（必要なら元のコード参照）
    final docs = qs.docs;

    final items = <Manual>[];
    for (final d in docs) {
      final data = d.data();

      final title = (data['title'] is String) ? (data['title'] as String) : '';
      final index = _toInt(data['index']);
      final viewCount = _toInt(data['view_count']);

      // カテゴリー・フォルダIDの取得
      final categoryId = (data['category_id'] is String)
          ? (data['category_id'] as String)
          : '';
      final folderId = (data['folder_id'] is String)
          ? (data['folder_id'] as String)
          : '';

      final createdObj = _getNested(data, const [
        'metadata',
        'first_interaction_time',
        'date',
      ]);
      final updatedObj = _getNested(data, const [
        'metadata',
        'last_interaction_time',
        'date',
      ]);

      final isAuto =
          _toBool(data['auto']) ||
          _toBool(data['is_auto']) ||
          _toBool(_getNested(data, const ['metadata', 'is_auto']));

      // Step情報のパース
      final stepInfosObj = data['step_infos'];
      final stepInfos = (stepInfosObj is List) ? stepInfosObj : <Object?>[];
      final steps = <StepItem>[];

      for (int i = 0; i < stepInfos.length; i++) {
        final raw = stepInfos[i];
        final m = _toStringKeyMap(raw);
        final useTitle = _toBool(m['use_title']) || _toBool(m['useTitle']);
        final stepTitle = (m['title'] is String) ? (m['title'] as String) : '';
        final content = (m['content'] is String)
            ? (m['content'] as String)
            : '';
        final useUrl = _toBool(m['use_url']) || _toBool(m['useUrl']);
        final url = (m['url'] is String) ? (m['url'] as String) : '';
        final imageIdsObj = m['image_ids'];
        final imageIds = <String>[];
        if (imageIdsObj is List) {
          for (final it in imageIdsObj) {
            if (it is String && it.trim().isNotEmpty) imageIds.add(it.trim());
          }
        }
        steps.add(
          StepItem(
            stepNo: i + 1,
            useTitle: useTitle,
            title: stepTitle,
            content: content,
            useUrl: useUrl,
            url: url,
            imageIds: imageIds,
          ),
        );
      }

      items.add(
        Manual(
          manualId: d.id,
          title: title,
          index: index,
          viewCount: viewCount,
          createdDate: _formatDate(createdObj),
          updatedDate: _formatDate(updatedObj),
          isAuto: isAuto,
          steps: steps,
          categoryId: categoryId,
          folderId: folderId,
        ),
      );
    }

    return items;
  }

  /// 画像URLを取得する
  Future<String> fetchManualImageUrl({
    required String storeId,
    required String manualId,
    required String imageId,
  }) async {
    final id = imageId.trim();
    if (id.isEmpty) return '';
    final path = 'store_data/$storeId/manual/$manualId/$id';
    try {
      return await FirebaseStorage.instance.ref(path).getDownloadURL();
    } catch (_) {
      return '';
    }
  }
}

// -----------------------------------------------------------------------------
// Helper Functions
// -----------------------------------------------------------------------------
Map<String, dynamic> _toStringKeyMap(Object? v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) {
    final out = <String, dynamic>{};
    v.forEach((k, val) {
      if (k is String) out[k] = val;
    });
    return out;
  }
  return <String, dynamic>{};
}

Object? _getNested(Map<String, dynamic> root, List<String> path) {
  Object? cur = root;
  for (final key in path) {
    if (cur is Map) {
      cur = cur[key];
    } else {
      return null;
    }
  }
  return cur;
}

int _toInt(Object? v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

bool _toBool(Object? v) {
  if (v is bool) return v;
  if (v is String) {
    final s = v.trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes' || s == 'on';
  }
  return false;
}

// ソート用 DateParse
DateTime? _parseDate(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) {
    // PDFにある "4001年1月1日..." のような日本語フォーマットやISO形式に対応する必要がある場合
    // 簡易的にISOのみ対応し、失敗したらnull
    return DateTime.tryParse(v);
  }
  return null;
}

String _formatDate(Object? v) {
  if (v == null) return '';
  DateTime? dt;
  if (v is Timestamp) {
    dt = v.toDate();
  } else if (v is DateTime) {
    dt = v;
  } else if (v is String) {
    dt = DateTime.tryParse(v.replaceAll('/', '-')); // 簡易
  }

  if (dt != null) return '${dt.year}/${dt.month}/${dt.day}';
  return v.toString();
}
