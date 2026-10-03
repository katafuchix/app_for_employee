import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'message_models.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository();
});

class MessageRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  Future<String> fetchCurrentStoreWorkerId() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('未ログインです');

    final workerMapDoc = await _db
        .collection('worker_id_map')
        .doc(user.uid)
        .get();

    if (!workerMapDoc.exists) {
      throw Exception('worker_id_map にデータがありません');
    }

    final storeWorkerId = workerMapDoc.data()?['store_worker_id'] as String?;
    if (storeWorkerId == null) {
      throw Exception('store_worker_id が未設定です');
    }

    return storeWorkerId;
  }

  // -----------------------------------------------------------------------------
  // Collection References with Converters
  // -----------------------------------------------------------------------------

  CollectionReference<Message> _messageRef(String storeId) => _db
      .collection("store_data")
      .doc(storeId)
      .collection('message')
      .withConverter<Message>(
        fromFirestore: (snapshot, _) =>
            Message.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (message, _) => message.toMap(),
      );

  CollectionReference<MessageAction> _actionRef(String storeId) => _db
      .collection("store_data")
      .doc(storeId)
      .collection('message_action')
      .withConverter<MessageAction>(
        fromFirestore: (snapshot, _) =>
            MessageAction.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (action, _) => action.toMap(),
      );

  // -----------------------------------------------------------------------------
  // 1. Create / Delete (Basic CRUD)
  // -----------------------------------------------------------------------------

  /// メッセージの新規作成
  /// Logic: 1. メッセージ作成 (Create)
  Future<void> createMessage(Message message, String storeId) async {
    // ID指定で作成 (set)
    await _messageRef(storeId).doc(message.id).set(message);
  }

  /// メッセージの削除 (送信者のみ)
  /// Logic: 3. メッセージ更新操作 (Delete)
  Future<void> deleteMessage(String messageId, String storeId) async {
    await _messageRef(storeId).doc(messageId).delete();
  }

  // -----------------------------------------------------------------------------
  // 2. Update Operations (Kick, Read, Check)
  // -----------------------------------------------------------------------------

  /// 特定の従業員をメッセージの対象から外す (Kick)
  /// Logic: 3. メッセージ更新操作 (Kick)
  Future<void> kickWorkerFromMessage({
    required String messageId,
    required String workerId,
    required String storeId,
  }) async {
    await _messageRef(storeId).doc(messageId).update({
      'receiver_ids': FieldValue.arrayRemove([workerId]),
      'unread_worker_ids': FieldValue.arrayRemove([workerId]),
      'unchecked_worker_ids': FieldValue.arrayRemove([workerId]),
      'metadata.last_interaction_time.date': FieldValue.serverTimestamp(),
      'metadata.interaction_count': FieldValue.increment(1),
    });
  }

  /// メッセージを既読にする (ローカル処理またはControllerから呼ばれる)
  /// Logic: 2.B などに関連
  Future<void> markMessageAsRead({
    required String messageId,
    required String workerId,
    required String storeId,
  }) async {
    await _messageRef(storeId).doc(messageId).update({
      'unread_worker_ids': FieldValue.arrayRemove([workerId]),
      'read_time_map.$workerId': FieldValue.serverTimestamp(),
      'metadata.last_interaction_time.date': FieldValue.serverTimestamp(),
      'metadata.interaction_count': FieldValue.increment(1),
    });
  }

  /// 複数メッセージを一括で既読にする
  Future<void> markMessagesAsReadBatch({
    required List<String> messageIds,
    required String workerId,
    required String storeId,
  }) async {
    if (messageIds.isEmpty) return;

    final batch = _db.batch();
    for (final messageId in messageIds) {
      final docRef = _messageRef(storeId).doc(messageId);
      batch.update(docRef, {
        'unread_worker_ids': FieldValue.arrayRemove([workerId]),
        'read_time_map.$workerId': FieldValue.serverTimestamp(),
        'metadata.last_interaction_time.date': FieldValue.serverTimestamp(),
        'metadata.interaction_count': FieldValue.increment(1),
      });
    }
    await batch.commit();
  }

  /// アクションを一括で既読にする (is_read = true)
  Future<void> markActionsAsReadBatch({
    required List<String> actionIds,
    required String storeId,
  }) async {
    if (actionIds.isEmpty) return;

    final batch = _db.batch();
    for (final actionId in actionIds) {
      final docRef = _actionRef(storeId).doc(actionId);
      batch.update(docRef, {'is_read': true});
    }
    await batch.commit();
  }

  /// メッセージをチェック済みにする (アクション作成は別途行う想定)
  Future<void> markMessageAsChecked({
    required String messageId,
    required String workerId,
    required bool isSharedCheck,
    required String storeId,
  }) async {
    final docRef = _messageRef(storeId).doc(messageId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception("Message does not exist!");
      }

      final message = snapshot.data()!;

      // 更新用データの作成
      final Map<String, dynamic> updateData = {
        'unchecked_worker_ids': FieldValue.arrayRemove([workerId]),
        'checked_time_map.$workerId': FieldValue.serverTimestamp(),
        'metadata.last_interaction_time.date': FieldValue.serverTimestamp(),
        'metadata.interaction_count': FieldValue.increment(1),
      };

      if (isSharedCheck) {
        if (message.sharedCheckedWorkerId == null ||
            message.sharedCheckedWorkerId!.isEmpty) {
          updateData['shared_checked_worker_id'] = workerId;
        }
      }

      transaction.update(docRef, updateData);
    });
  }

  /// アナウンス済みリストに追加
  /// Logic: 2.C 音声アナウンス
  Future<void> markAsAnnounced({
    required String messageId,
    required String workerId,
    required String storeId,
  }) async {
    await _messageRef(storeId).doc(messageId).update({
      'announced_worker_ids': FieldValue.arrayUnion([workerId]),
      'announced_time_map.$workerId': FieldValue.serverTimestamp(),
    });
  }

  // -----------------------------------------------------------------------------
  // 3. Streams (Listeners)
  // -----------------------------------------------------------------------------

  /// 受信箱用リスナー
  /// Logic: 4. 受信箱リスナー (Inbox Listener)
  /// クエリ: receiver_ids contains my_id AND (unread contains my_id OR unchecked contains my_id OR schedule >= 3日前)
  Stream<List<Message>> streamInboxMessages({
    required String myId,
    required String storeId,
  }) {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));

    // --- Stream 1: 直近のメッセージ (全て) ---
    final recentStream = _messageRef(storeId)
        .where('receiver_ids', arrayContains: myId)
        .where('schedule_date', isGreaterThanOrEqualTo: threeDaysAgo)
        .snapshots()
        .map((q) => q.docs.map((d) => d.data()).toList());

    // --- Stream 2: 3日以上前の「未読」 ---
    // ※ unread_worker_ids に入っている時点で receiver_ids にも入っている前提
    final oldUnreadStream = _messageRef(storeId)
        .where('unread_worker_ids', arrayContains: myId)
        .where('schedule_date', isLessThan: threeDaysAgo)
        .limit(50) // 安全策: 溜まりすぎ防止のため上限を設ける
        .snapshots()
        .map((q) => q.docs.map((d) => d.data()).toList());

    // --- Stream 3: 3日以上前の「要確認」 ---
    final oldCheckRequiredStream = _messageRef(storeId)
        .where('is_check_required', isEqualTo: true)
        .where('shared_checked_worker_id', isEqualTo: "")
        .where('unchecked_worker_ids', arrayContains: myId)
        .where('schedule_date', isLessThan: threeDaysAgo)
        .snapshots()
        .map((q) => q.docs.map((d) => d.data()).toList());

    // --- 統合 (Merge) ---
    return Rx.combineLatest3(
      recentStream,
      oldUnreadStream,
      oldCheckRequiredStream,
      (List<Message> recent, List<Message> unread, List<Message> check) {
        // 1. 全リストを結合
        // 日付で区切っているのでIDの重複は理論上ないはずですが、
        // 念のため重複排除ロジックを入れておくと堅牢です。
        final allMessages = [...recent, ...unread, ...check];

        // 2. IDで重複排除 (Setを使う)
        final uniqueMessages = {
          for (var msg in allMessages) msg.id: msg,
        }.values.toList();

        // 3. 日付順に並び替え (新しい順)
        uniqueMessages.sort((a, b) => b.scheduleDate.compareTo(a.scheduleDate));

        return uniqueMessages;
      },
    );
  }

  /// 送信者用 アクションリスナー
  /// Logic: 5.A 送信者用リスナー (Sender Listener)
  Stream<List<MessageAction>> streamSenderActions({
    required String myId,
    required String storeId,
  }) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final timestampSevenDaysAgo = Timestamp.fromDate(sevenDaysAgo);

    return _actionRef(storeId)
        .where('message_sender_id', isEqualTo: myId)
        .where(
          'metadata.first_interaction_time.date',
          isGreaterThanOrEqualTo: timestampSevenDaysAgo,
        )
        .orderBy('metadata.first_interaction_time.date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// 単一メッセージの監視 (詳細画面用)
  /// Logic: 5.B メッセージ詳細閲覧時のリスナー
  Stream<Message?> streamMessage(String messageId, String storeId) {
    return _messageRef(
      storeId,
    ).doc(messageId).snapshots().map((doc) => doc.data());
  }

  // -----------------------------------------------------------------------------
  // 4. Fetch Once (Send History / All)
  // -----------------------------------------------------------------------------

  /// 送信済みメッセージ取得
  /// Logic: 6. 送信済み・全体メッセージ取得 (Sender)
  /// クエリ: sender_id == my_id AND schedule_date >= 10日前
  Future<List<Message>> fetchSentMessages({
    required String myId,
    required String storeId,
  }) async {
    final tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));

    final snapshot = await _messageRef(storeId)
        .where('sender_id', isEqualTo: myId)
        .where('schedule_date', isGreaterThanOrEqualTo: tenDaysAgo)
        .orderBy('schedule_date', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// 全体メッセージ取得
  /// Logic: 6. 送信済み・全体メッセージ取得 (All)
  /// クエリ: schedule_date >= 10日前
  Future<List<Message>> fetchAllMessages(String storeId) async {
    final tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));

    final snapshot = await _messageRef(storeId)
        .where('schedule_date', isGreaterThanOrEqualTo: tenDaysAgo)
        .orderBy('schedule_date', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> deleteUserFromRecieverList({
    required String messageId,
    required String workerId,
    required String storeId,
  }) async {
    await _messageRef(storeId).doc(messageId).update({
      'receiver_ids': FieldValue.arrayRemove([workerId]),
      'unread_worker_ids': FieldValue.arrayRemove([workerId]),
      'unchecked_worker_ids': FieldValue.arrayRemove([workerId]),
      'metadata.last_interaction_time.date': FieldValue.serverTimestamp(),
      'metadata.interaction_count': FieldValue.increment(1),
    });
  }

  // -----------------------------------------------------------------------------
  // 5. Message Action Operations
  // -----------------------------------------------------------------------------

  /// アクション（返信・チェック等）の作成
  Future<void> createMessageAction(MessageAction action, String storeId) async {
    await _actionRef(storeId).doc(action.id).set(action);
    await _messageRef(storeId).doc(action.messageId).update({
      'reply_count': FieldValue.increment(1),
      'metadata.last_interaction_time.date': FieldValue.serverTimestamp(),
      'metadata.interaction_count': FieldValue.increment(1),
    });
  }

  /// 送信者がアクションを既読にする
  /// Logic: 5.A 既読化処理
  Future<void> updateActionReadStatus({
    required String actionId,
    required bool isRead,
    required String storeId,
  }) async {
    await _actionRef(storeId).doc(actionId).update({
      'is_read': isRead,
      'metadata.last_interaction_time.date': FieldValue.serverTimestamp(),
      'metadata.interaction_count': FieldValue.increment(1),
    });
  }

  Future<void> uploadActionImage({
    required String filePath,
    required String storeId,
    required String messageId,
    required String actionId,
  }) async {
    final file = File(filePath);

    // パスの構築
    final ref = _storage
        .ref()
        .child('store_data')
        .child(storeId)
        .child('message_action')
        .child(actionId); // ファイル名としてactionIdを使用（拡張子を含める場合は適宜調整）

    // アップロード実行
    // 必要であればメタデータ（contentTypeなど）を設定してください
    final snapshot = await ref.putFile(file);

    // ダウンロードURLの取得
    await snapshot.ref.getDownloadURL();

    await _messageRef(
      storeId,
    ).doc(messageId).update({'image_count': FieldValue.increment(1)});
  }

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

  /// 従業員マスタ (Worker) の取得
  Future<List<Map<String, String>>> fetchWorkers(String storeId) async {
    final snapshot = await _db
        .collection('store_data')
        .doc(storeId)
        .collection('worker')
        .where('metadata.is_deleted', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final nameInfo = data['name_info'] as Map<String, dynamic>? ?? {};
      final familyName = nameInfo['family_name'] as String? ?? '';
      final givenName = nameInfo['given_name'] as String? ?? '';
      return {
        'id': data['id'] as String,
        'name': '$familyName $givenName'.trim(),
      };
    }).toList();
  }

  /// メッセージ詳細モーダル用 アクションリスナー
  /// Logic: メッセージ詳細画面で、そのメッセージに紐づく全てのアクション（返信、チェック、画像）をリアルタイム取得する
  /// Ref:  "message_actionコレクションでのmessage_idの一致でクエリして...ここはaction infoのリスナーにしたい"
  Stream<List<MessageAction>> streamActionsByMessageId(
    String messageId,
    String storeId,
  ) {
    return _actionRef(storeId)
        .where('message_id', isEqualTo: messageId)
        // 実際の表示順序に合わせてソート（例: 作成順など。metadata.created_atを想定）
        // .orderBy('metadata.created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// 特定の日のシフト有無を確認する
  /// Logic: 受信箱の日付ヘッダー等で、その日にシフトがあるかを表示するために使用
  /// Ref:  "shiftコレクションにあるドキュメントを探し...base_date.dateを...worker_idがまた一致するというクエリで検索"
  /// Note: 本来はShiftRepositoryにあるべき可能性がありますが、コミュニケーション機能の表示要件としてここに記載します。
  /// Shiftモデルが提供されていないため、`Map<String, dynamic>`として返します。
  Future<List<Map<String, dynamic>>> fetchWorkerShift({
    required String workerId,
    required DateTime targetDate,
    required String storeId,
  }) async {
    // 検索用の日付（0:00:00）を生成
    final startOfDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    // shiftコレクションへの参照 (モデルがないため直接Mapとして取得)
    final snapshot = await _db
        .collection('store_data')
        .doc(storeId)
        .collection('shift')
        .where('worker_id', isEqualTo: workerId)
        .where('base_date.date', isEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<UserProfile> fetchUserProfile(String workerId, String storeId) async {
    final snapshot = await _db
        .collection('store_data')
        .doc(storeId)
        .collection('worker')
        .where('id', isEqualTo: workerId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('ユーザープロフィールが見つかりませんでした。');
    }

    final data = snapshot.docs.first.data();
    final nameInfo = data['name_info'] as Map<String, dynamic>? ?? {};
    final familyName = nameInfo['family_name'] as String? ?? '';
    final givenName = nameInfo['given_name'] as String? ?? '';
    return UserProfile(
      id: data['id'] as String,
      displayName: '$familyName $givenName'.trim(),
    );
  }

  /// FCMトークンをworker_id_mapに保存・更新する
  Future<void> updateNotificationToken(String uid, String token) async {
    final docRef = _db.collection('worker_id_map').doc(uid);
    final doc = await docRef.get();

    if (doc.exists) {
      final currentToken = doc.data()?['notification_token'];
      // 端末のものと一致していれば何もせず、一致していなければupdateする
      if (currentToken != token) {
        await docRef.update({'notification_token': token});
      }
    }
  }

  /// バッジ数を絶対値で更新する (UIで減少を検知した際)
  Future<void> updateBadgeCount(String uid, int absoluteBadgeCount) async {
    // +1や-1ではなく、数字全体を取得してそのままupdateする
    await _db.collection('worker_id_map').doc(uid).update({
      'badge_number': absoluteBadgeCount, // サーバー側とフィールド名を合わせてください
    });
  }
}
