// manual_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'manual_models.dart';
import 'manual_repository.dart';

part 'manual_controller.g.dart';

@riverpod
ManualRepository manualRepository(Ref ref) {
  return const ManualRepository();
}

@riverpod
Future<String> manualStoreId(Ref ref) async {
  return ref.watch(manualRepositoryProvider).fetchStoreId();
}

// 単純なマニュアルリスト（内部利用）
@riverpod
Future<List<Manual>> manualList(Ref ref, String storeId) async {
  return ref.watch(manualRepositoryProvider).fetchManuals(storeId);
}

// カテゴリーリスト（内部利用）
@riverpod
Future<List<ManualCategory>> manualCategoryRawList(
  Ref ref,
  String storeId,
) async {
  return ref.watch(manualRepositoryProvider).fetchCategories(storeId);
}

// UI表示用に整形された階層データ
@riverpod
Future<List<CategoryWithContent>> manualCategoryList(
  Ref ref,
  String storeId,
) async {
  // 並列取得
  final manualsFuture = ref.watch(manualListProvider(storeId).future);
  final categoriesFuture = ref.watch(
    manualCategoryRawListProvider(storeId).future,
  );

  final results = await Future.wait([manualsFuture, categoriesFuture]);
  final manuals = results[0] as List<Manual>;
  final categories = results[1] as List<ManualCategory>;

  final List<CategoryWithContent> output = [];

  // ▼ 1. どのカテゴリーにも属していない（または空の）マニュアルを事前に抽出
  final validCategoryIds = categories.map((c) => c.id).toSet();
  final completelyUncategorized = manuals
      .where(
        (m) => m.categoryId.isEmpty || !validCategoryIds.contains(m.categoryId),
      )
      .toList();

  for (final cat in categories) {
    final folderContents = <FolderWithContent>[];

    // このカテゴリーに属する全マニュアルを抽出
    final catManuals = manuals.where((m) => m.categoryId == cat.id).toList();

    // フォルダごとにマニュアルを振り分け
    for (final folder in cat.folders) {
      final folderManuals = catManuals
          .where((m) => m.folderId == folder.id)
          .toList();
      folderContents.add(
        FolderWithContent(folder: folder, manuals: folderManuals),
      );
    }

    // どのフォルダにも属していないマニュアル
    final knownFolderIds = cat.folders.map((f) => f.id).toSet();
    final uncategorized = catManuals
        .where((m) => !knownFolderIds.contains(m.folderId))
        .toList();

    // ▼ 2. もし既存のカテゴリー名が「その他」なら、完全に未分類のマニュアルもここに合流させる
    if (cat.title == 'その他' && completelyUncategorized.isNotEmpty) {
      uncategorized.addAll(completelyUncategorized);
      completelyUncategorized.clear(); // 合流させたらリストを空にする
    }

    output.add(
      CategoryWithContent(
        category: cat,
        folders: folderContents,
        uncategorizedManuals: uncategorized,
      ),
    );
  }

  // ▼ 3. もし「その他」という名前のカテゴリーが存在しなかった場合、
  // 新しく「その他」タブ（カテゴリー）を作ってそこに表示する
  if (completelyUncategorized.isNotEmpty) {
    output.add(
      CategoryWithContent(
        category: const ManualCategory(
          id: 'uncategorized_others',
          title: 'その他',
          color: '#EEEEEE',
          folders: [],
        ),
        folders: [],
        uncategorizedManuals: completelyUncategorized,
      ),
    );
  }

  return output;
}

@riverpod
Future<String> manualImageUrl(
  Ref ref, {
  required String storeId,
  required String manualId,
  required String imageId,
}) async {
  return ref
      .watch(manualRepositoryProvider)
      .fetchManualImageUrl(
        storeId: storeId,
        manualId: manualId,
        imageId: imageId,
      );
}
