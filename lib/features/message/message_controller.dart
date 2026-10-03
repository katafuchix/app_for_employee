import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../operation/models/meta_data_model.dart';
import 'message_models.dart';
import 'message_repository.dart';

part 'message_controller.g.dart';

// -----------------------------------------------------------------------------
// Providers
// -----------------------------------------------------------------------------

@riverpod
Future<String> storeId(Ref ref) async {
  final repository = ref.watch(messageRepositoryProvider);
  return await repository.fetchStoreId();
}

/// Provides the current user's ID.
/// NOTE: Replace this with your actual Auth provider.
@riverpod
Future<String> currentStoreWorkerId(Ref ref) async {
  return ref.read(messageRepositoryProvider).fetchCurrentStoreWorkerId();
}

@riverpod
Future<UserProfile> fetchUserProfile(Ref ref, String workerId) async {
  final repository = ref.watch(messageRepositoryProvider);
  final storeIdAsync = ref.watch(storeIdProvider);
  return await repository.fetchUserProfile(workerId, storeIdAsync.value!);
}

/// 4. 受信箱リスナー (Inbox Listener)
@riverpod
Stream<List<Message>> inboxMessages(Ref ref) {
  final myIdAsync = ref.watch(currentStoreWorkerIdProvider);
  final storeIdAsync = ref.watch(storeIdProvider);

  // 両方のAsyncValueがデータを持っている場合のみストリームを返す
  if (myIdAsync is AsyncData<String> && storeIdAsync is AsyncData<String>) {
    return ref.watch(messageRepositoryProvider).streamInboxMessages(
      myId: myIdAsync.value,
      storeId: storeIdAsync.value,
    );
  }

  return const Stream.empty();
}

@riverpod
Future<List<Message>> allMessages(Ref ref) {
  final storeIdAsync = ref.watch(storeIdProvider);

  return storeIdAsync.when(
    data: (storeId) =>
        ref.watch(messageRepositoryProvider).fetchAllMessages(storeId),
    loading: () => Future.value([]),
    error: (_, __) => Future.value([]),
  );
}

// -----------------------------------------------------------------------------
// Timer Provider
// -----------------------------------------------------------------------------

/// 1分ごとに現在時刻を更新して通知するプロバイダー
/// UI側でこれを watch すると、1分ごとに再描画が走ります。
@riverpod
Stream<DateTime> currentMinute(Ref ref) {
  // 即座に現在時刻を返し、その後1分おきに新しい時刻を流す
  return Stream.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  ).startWith(DateTime.now());
}

/// 5. 送信済みメッセージ取得 (Sent Messages) - 追加部分
/// Retrieves the list of messages sent by the current user.
@riverpod
Future<List<Message>> sentMessages(Ref ref) async {
  // ID取得を待つ (FutureProviderなので await が必要)
  final myId = await ref.watch(currentStoreWorkerIdProvider.future);
  final storeId = await ref.watch(storeIdProvider.future);

  // Repositoryから取得
  final repository = ref.watch(messageRepositoryProvider);
  return repository.fetchSentMessages(myId: myId, storeId: storeId);
}

@riverpod
Stream<List<MessageAction>> senderActions(Ref ref) {
  final myIdAsync = ref.watch(currentStoreWorkerIdProvider);
  final storeIdAsync = ref.watch(storeIdProvider);

  return myIdAsync.when(
    data: (myId) => ref
        .watch(messageRepositoryProvider)
        .streamSenderActions(myId: myId, storeId: storeIdAsync.value!),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
}

/// メッセージ詳細モーダル用 アクションリスナー
@riverpod
Stream<List<MessageAction>> messageActionsFamily(Ref ref, String messageId) {
  final repository = ref.watch(messageRepositoryProvider);
  final storeIdAsync = ref.watch(storeIdProvider);
  return repository.streamActionsByMessageId(messageId, storeIdAsync.value!);
}

/// 単一メッセージの監視
@riverpod
Stream<Message?> messageDetailFamily(Ref ref, String messageId) {
  final repository = ref.watch(messageRepositoryProvider);
  final storeIdAsync = ref.watch(storeIdProvider);
  return repository.streamMessage(messageId, storeIdAsync.value!);
}

@riverpod
Future<List<Map<String, String>>> storeWorkers(Ref ref) async {
  final repository = ref.watch(messageRepositoryProvider);
  final storeId = await repository.fetchStoreId();
  return repository.fetchWorkers(storeId);
}

@riverpod
Future<List<Map<String, String>>> selectableStoreWorkers(Ref ref) async {
  // 1. 全従業員リストを取得
  final allWorkers = await ref.watch(storeWorkersProvider.future);
  // 2. 自分のIDを取得
  final myId = await ref.watch(currentStoreWorkerIdProvider.future);

  // 3. 自分を除外して返す
  return allWorkers.where((worker) => worker['id'] != myId).toList();
}

/// シフト確認用
@riverpod
Future<List<Map<String, dynamic>>> workerShiftFamily(
  Ref ref, {
  required String workerId,
  required DateTime targetDate,
}) {
  final repository = ref.watch(messageRepositoryProvider);
  final storeIdAsync = ref.watch(storeIdProvider);
  return repository.fetchWorkerShift(
    workerId: workerId,
    targetDate: targetDate,
    storeId: storeIdAsync.value!,
  );
}

/// Calculate Badge Count for Inbox
@riverpod
int inboxBadgeCount(Ref ref) {
  // 時間経過でスケジュール時刻が来た際にバッジを自動更新させる
  ref.watch(currentMinuteProvider);

  final messagesAsync = ref.watch(inboxMessagesProvider);
  final myIdAsync = ref.watch(currentStoreWorkerIdProvider);

  if (messagesAsync is AsyncData<List<Message>> &&
      myIdAsync is AsyncData<String>) {
    final messages = messagesAsync.value;
    final myId = myIdAsync.value;
    final now = DateTime.now();

    int count = 0;
    for (final msg in messages) {
      // 未来のスケジュールの場合は未読/未完了としてカウントしない
      final isFuture = msg.isScheduled && msg.scheduleDate.isAfter(now);
      if (isFuture) continue;

      final isUnread = msg.unreadWorkerIds.contains(myId);
      final isCheckIncomplete =
          msg.isCheckRequired &&
          (msg.uncheckedWorkerIds.contains(myId) ||
              (msg.isCheckShared && msg.sharedCheckedWorkerId == null));

      if (isUnread || isCheckIncomplete) count++;
    }
    return count;
  }

  return 0;
}

@riverpod
int totalBadgeCount(Ref ref) {
  // 1. 受信箱の未読バッジ数
  final inboxCount = ref.watch(inboxBadgeCountProvider);

  // 2. 送信者のアクション未読バッジ数
  final actionsAsync = ref.watch(senderActionsProvider);
  final actionCount = actionsAsync.maybeWhen(
    data: (actions) => actions.where((a) => !a.isRead).length,
    orElse: () => 0,
  );

  // 3. 合計値を返す
  return inboxCount + actionCount;
}

// -----------------------------------------------------------------------------
// Controller (Business Logic)
// -----------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class MessageController extends _$MessageController {
  @override
  FutureOr<void> build() {
    // Initial state is void (idle)
  }

  MessageRepository get _repository => ref.read(messageRepositoryProvider);

  /// Helper to get My ID safely
  Future<String> get _fetchMyId =>
      ref.read(currentStoreWorkerIdProvider.future);
  Future<String> get _fetchStoreId => ref.read(storeIdProvider.future);

  /// 1. メッセージ作成と送信
  Future<void> sendMessage({
    required List<String> receiverIds,
    required String content,
    required bool isScheduled,
    required DateTime scheduleDate,
    required bool isCheckRequired,
    required bool isCheckShared,
    DateTime? checkDeadline,
    required bool isImageRequiredWhileCheck,
    required bool isOperationAnnouncementRequired,
  }) async {
    state = const AsyncLoading();
    try {
      final myId = await _fetchMyId;
      final storeId = await _fetchStoreId;
      final now = DateTime.now();

      // --- Validation ---
      if (isScheduled && scheduleDate.isBefore(now)) {
        throw Exception("Scheduled date must be in the future.");
      }
      if (content.trim().isEmpty) {
        throw Exception("Content cannot be empty.");
      }

      if (isCheckRequired) {
        if (checkDeadline == null) {
          throw Exception("Check deadline is required when check is required.");
        }
        final effectiveStartDate = isScheduled ? scheduleDate : now;
        if (checkDeadline.isBefore(effectiveStartDate)) {
          throw Exception("Check deadline must be after the start date.");
        }
      }

      // --- Model Creation ---
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: myId,
        receiverIds: receiverIds,
        unreadWorkerIds: [...receiverIds],
        uncheckedWorkerIds: isCheckRequired ? [...receiverIds] : [],
        isScheduled: isScheduled,
        scheduleDate: isScheduled ? scheduleDate : now,
        content: content,
        isCheckRequired: isCheckRequired,
        isCheckShared: isCheckShared,
        checkDeadline: checkDeadline,
        isImageRequiredWhileCheck: isImageRequiredWhileCheck,
        isOperationAnnouncementRequired: isOperationAnnouncementRequired,
        readTimeMap: {},
        checkedTimeMap: {},
        sharedCheckedWorkerId: null,
        announcedWorkerIds: [],
        announcedTimeMap: {},
        imageCount: 0,
        replyCount: 0,
        metadata: Metadata.create(),
      );

      await _repository.createMessage(newMessage, storeId);

      // 送信成功時に送信済みリストをリフレッシュする場合は以下を実行
      // ref.invalidate(sentMessagesProvider);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// 2. メッセージ削除 (送信者のみ)
  Future<void> deleteMessage(String messageId) async {
    state = const AsyncLoading();
    try {
      final storeIdAsync = ref.watch(storeIdProvider);
      await _repository.deleteMessage(messageId, storeIdAsync.value!);
      // 削除後に送信済みリストをリフレッシュ
      ref.invalidate(sentMessagesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// 3. メッセージを開封する (既読にする)
  Future<void> markAsRead(String messageId) async {
    try {
      final myId = await _fetchMyId;
      final storeIdAsync = ref.watch(storeIdProvider);
      await _repository.markMessageAsRead(
        messageId: messageId,
        workerId: myId,
        storeId: storeIdAsync.value!,
      );
    } catch (e) {
      debugPrint('Failed to mark as read: $e');
    }
  }

  /// 3.5 複数メッセージを一括で既読にする
  Future<void> markMessagesAsReadBatch(List<String> messageIds) async {
    try {
      if (messageIds.isEmpty) return;
      final myId = await _fetchMyId;
      final storeId = await _fetchStoreId;
      await _repository.markMessagesAsReadBatch(
        messageIds: messageIds,
        workerId: myId,
        storeId: storeId,
      );
    } catch (e) {
      print('Failed to mark messages as read batch: $e');
    }
  }

  /// 3.6 アクションを一括で既読にする (is_read = true)
  Future<void> markActionsAsReadBatch(List<String> actionIds) async {
    try {
      if (actionIds.isEmpty) return;
      final storeId = await _fetchStoreId;
      await _repository.markActionsAsReadBatch(
        actionIds: actionIds,
        storeId: storeId,
      );
    } catch (e) {
      print('Failed to mark actions as read batch: $e');
    }
  }

  /// 4. アクションの送信 (返信・チェック・画像)
  Future<void> sendAction({
    required Message message,
    String? replyContent,
    String? imagePath,
    bool isCheckAction = false,
  }) async {
    state = const AsyncLoading();
    try {
      final myId = await _fetchMyId;
      final storeId = await _fetchStoreId;
      final actionTypes = <String>[];
      final actionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Check Logic
      if (isCheckAction) {
        actionTypes.add('check');
        if (message.isImageRequiredWhileCheck &&
            (imagePath == null || imagePath.isEmpty)) {
          throw Exception("Image is required for this check.");
        }
      }

      // Reply Logic
      if (replyContent != null && replyContent.isNotEmpty) {
        actionTypes.add('reply');
      }

      // Image Logic
      if (imagePath != null && imagePath.isNotEmpty) {
        actionTypes.add('image');

        await _repository.uploadActionImage(
          filePath: imagePath,
          storeId: storeId,
          messageId: message.id,
          actionId: actionId,
        );
      }

      if (actionTypes.isEmpty) {
        throw Exception("No action performed.");
      }

      final newAction = MessageAction(
        id: actionId,
        messageId: message.id,
        messageSenderId: message.senderId,
        actorId: myId,
        actionTypes: actionTypes,
        replyFromReceiver: replyContent,
        isRead: false,
        metadata: Metadata.create(),
      );

      await _repository.createMessageAction(newAction, storeId);

      if (isCheckAction) {
        await _repository.markMessageAsChecked(
          messageId: message.id,
          workerId: myId,
          isSharedCheck: message.isCheckShared,
          storeId: storeId,
        );
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// 5. 送信者がアクションを既読にする
  Future<void> markActionAsRead(String actionId) async {
    try {
      final storeId = await _fetchStoreId;
      await _repository.updateActionReadStatus(
        actionId: actionId,
        isRead: true,
        storeId: storeId,
      );
    } catch (e) {
      debugPrint('Failed to mark action as read: $e');
    }
  }

  /// 6. アナウンス完了を記録
  Future<void> markAsAnnounced(String messageId) async {
    try {
      final myId = await _fetchMyId;
      final storeId = await _fetchStoreId;
      await _repository.markAsAnnounced(
        messageId: messageId,
        workerId: myId,
        storeId: storeId,
      );
    } catch (e) {
      debugPrint('Failed to mark as announced: $e');
    }
  }

  Future<void> deleteUserFromReceiverList(
    String messageId,
    String workerId,
  ) async {
    try {
      final storeId = await _fetchStoreId;
      await _repository.deleteUserFromRecieverList(
        messageId: messageId,
        workerId: workerId,
        storeId: storeId,
      );
    } catch (e) {
      debugPrint('Failed to delete user from receivers: $e');
    }
  }

  Future<List<Message>> checkNewArrivals() async {
    // 1. 現在の受信箱の状態を取得
    final inboxState = ref.read(inboxMessagesProvider);
    if (!inboxState.hasValue) return [];
    final messages = inboxState.value!;

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    const key = 'message_last_notification_schedule_date';

    // 2. 最後に通知した日時を取得 (保存がない場合は、現在時刻をデフォルトとして過去の通知を防ぐ)
    final lastStr = prefs.getString(key);
    final lastNotificationDate = lastStr != null
        ? DateTime.parse(lastStr)
        : DateTime(2000, 1, 1);

    // 3. 条件に合うメッセージを抽出
    // 条件A: スケジュール時刻 <= 現在 (時間が来ている)
    // 条件B: スケジュール時刻 > 前回通知日時 (まだ通知していない)
    final newArrivals = messages.where((msg) {
      return msg.scheduleDate.isBefore(now) &&
          msg.scheduleDate.isAfter(lastNotificationDate);
    }).toList();

    if (newArrivals.isEmpty) {
      return [];
    }

    // 4. 最新のスケジュール日時を特定して保存 (次回以降の重複防止)
    // リストの中から一番新しい scheduleDate を探す
    newArrivals.sort(
      (a, b) => b.scheduleDate.compareTo(a.scheduleDate),
    ); // 降順ソート
    final newestDate = newArrivals.first.scheduleDate;

    await prefs.setString(key, newestDate.toIso8601String());

    // 5. 通知すべきメッセージのリストを返す
    return newArrivals;
  }
}

@riverpod
bool inboxHasLateMessage(Ref ref) {
  // ★ 1分ごとの再計算トリガー
  ref.watch(currentMinuteProvider);

  final messagesAsync = ref.watch(inboxMessagesProvider);
  final myIdAsync = ref.watch(currentStoreWorkerIdProvider);

  if (messagesAsync is AsyncData && myIdAsync is AsyncData) {
    final messages = messagesAsync.value!;
    final myId = myIdAsync.value!;
    final now = DateTime.now();

    for (final msg in messages) {
      // 1. チェックが必要ない、または既に完了している場合はスキップ
      final isCheckRequired = msg.isCheckRequired;
      final isChecked =
          isCheckRequired &&
          (msg.isCheckShared
              ? (msg.sharedCheckedWorkerId != null &&
                    msg.sharedCheckedWorkerId!.isNotEmpty)
              : msg.receiverIds.contains(myId) &&
                    msg.checkedTimeMap.containsKey(myId));

      if (!isCheckRequired || isChecked) {
        continue;
      }

      // 2. 未完了 かつ 期限設定あり かつ 現在時刻が期限を過ぎている場合
      if (msg.checkDeadline != null && msg.checkDeadline!.isBefore(now)) {
        return true; // 1つでもあれば警告
      }
    }
  }
  return false;
}
