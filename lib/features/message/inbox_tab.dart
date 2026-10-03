import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'message_controller.dart';
import 'message_detail_modal.dart';
import 'message_models.dart';

// -------------------------------------------------------

class InboxTab extends ConsumerStatefulWidget {
  const InboxTab({super.key});

  @override
  ConsumerState<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends ConsumerState<InboxTab> {
  // セッション開始時の未読メッセージIDを保持（新規バッジの表示判定用）
  Set<String> _initialUnreadMessageIds = {};
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // 初期化処理は最初のbuildでメッセージが取得された後に行う
  }

  void _initializeUnreadState(List<Message> messages, String myId) {
    if (_hasInitialized) return;
    _hasInitialized = true;

    // スケジュール時間が来ている未読メッセージのIDを保持
    final now = DateTime.now();
    final unreadIds = messages
        .where((m) => m.unreadWorkerIds.contains(myId) && !m.scheduleDate.isAfter(now))
        .map((m) => m.id)
        .toSet();

    setState(() {
      _initialUnreadMessageIds = unreadIds;
    });

    // 一括既読処理を実行
    if (unreadIds.isNotEmpty) {
      ref.read(messageControllerProvider.notifier).markMessagesAsReadBatch(unreadIds.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(inboxMessagesProvider);
    final myIdAsync = ref.watch(currentStoreWorkerIdProvider);

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(child: Text('メッセージはありません'));
        }

        // myIdが取得できたら初期化処理を実行
        myIdAsync.whenData((myId) {
          _initializeUnreadState(messages, myId);
        });

        // 1. 日付ごとのグループ化
        final Map<DateTime, List<Message>> groupedMessages = {};
        for (final message in messages) {
          final date = DateTime(
            message.scheduleDate.year,
            message.scheduleDate.month,
            message.scheduleDate.day,
          );
          if (!groupedMessages.containsKey(date)) {
            groupedMessages[date] = [];
          }
          groupedMessages[date]!.add(message);
        }

        // 画像の時系列に合わせて昇順（古い日付順 -> 今日）にソート
        final sortedDates = groupedMessages.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dayMessages = groupedMessages[date]!;

            dayMessages.sort(
              (a, b) => b.scheduleDate.compareTo(a.scheduleDate),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. 日付ヘッダー
                myIdAsync.when(
                  data: (myId) => DateHeader(targetDate: date, myId: myId),
                  loading: () => const SizedBox(height: 20),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 10),

                // メッセージリスト
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: dayMessages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, msgIndex) {
                    final message = dayMessages[msgIndex];
                    return InboxMessageCard(
                      message: message,
                      showNewBadge: _initialUnreadMessageIds.contains(message.id),
                    );
                  },
                ),
                const SizedBox(height: 20), // 日付グループ間の余白
              ],
            );
          },
        );
      },
    );
  }
}

/// 日付＆シフトヘッダー
/// 「今日」の場合は青い特別なデザインにする
class DateHeader extends ConsumerWidget {
  final DateTime targetDate;
  final String myId;

  const DateHeader({super.key, required this.targetDate, required this.myId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentMinuteProvider);

    // Shift情報を取得
    final shiftAsync = ref.watch(
      workerShiftFamilyProvider(workerId: myId, targetDate: targetDate),
    );

    final now = DateTime.now();
    final isToday =
        targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;

    final dateStr = DateFormat('M/d').format(targetDate);
    // 今日の場合は現在時刻を表示 (画像の「10:41」部分)
    final timeStr = DateFormat('H:mm').format(now);

    // --- 今日のデザイン (青色強調) ---
    if (isToday) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 青い「今日」バッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0084FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '今日',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 青い時刻テキスト
            Text(
              timeStr,
              style: const TextStyle(
                color: Color(0xFF0084FF),
                fontSize: 18, // 少し大きめ
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),

            const SizedBox(width: 10),

            // 右側のグレーの線
            Expanded(
              child: Container(height: 1.5, color: const Color(0xFFE0E0E0)),
            ),
          ],
        ),
      );
    }

    // --- 通常の日付デザイン ---
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 日付 (2/7など)
          Text(
            dateStr,
            style: const TextStyle(
              color: Color(0xFF858585),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 15),

          // 線とシフト情報
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 背景の線
                Container(height: 1.5, color: const Color(0xFFE0E0E0)),
                // シフト情報 (右寄せ)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    color: Colors.white, // 線を隠すための背景色
                    padding: const EdgeInsets.only(left: 10),
                    child: shiftAsync.when(
                      loading: () => const SizedBox(width: 10),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (shifts) {
                        if (shifts.isEmpty) return const SizedBox.shrink();

                        // シフト時間整形
                        final shift = shifts.first;
                        final inTimeTs = shift['in_time'];
                        final outTimeTs = shift['out_time'];
                        String shiftTimeStr = "";
                        if (inTimeTs is Timestamp && outTimeTs is Timestamp) {
                          shiftTimeStr =
                              "${DateFormat('H:mm').format(inTimeTs.toDate())} ~ ${DateFormat('H:mm').format(outTimeTs.toDate())}";
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'シフト',
                              style: TextStyle(
                                color: Color(0xFF1AD84C), // 緑
                                fontSize: 9,
                                fontFamily: 'Noto Sans JP',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              shiftTimeStr,
                              style: const TextStyle(
                                color: Color(0xFF1AD84C), // 緑
                                fontSize: 11,
                                fontFamily: 'Noto Sans JP',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InboxMessageCard extends ConsumerWidget {
  final Message message;
  final bool showNewBadge;

  const InboxMessageCard({super.key, required this.message, this.showNewBadge = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentMinuteProvider);

    final myIdAsync = ref.watch(currentStoreWorkerIdProvider);

    return myIdAsync.when(
      loading: () => const SizedBox(height: 100),
      error: (_, __) => const SizedBox.shrink(),
      data: (myId) {
        // ステータス判定
        final isUnread = message.unreadWorkerIds.contains(myId);
        final isChecked =
            message.isCheckRequired &&
            (message.isCheckShared
                ? (message.sharedCheckedWorkerId != null &&
                      message.sharedCheckedWorkerId!.isNotEmpty)
                : message.receiverIds.contains(myId) &&
                      message.checkedTimeMap.containsKey(myId));

        final now = DateTime.now();
        final isLate =
            !isChecked &&
            message.checkDeadline != null &&
            message.checkDeadline!.isBefore(now);
        final isFuture =
            message.isScheduled && message.scheduleDate.isAfter(now);

        // 🌟 追加: スケジュール前ではない、本当に未読として扱うべき状態か判定
        final isEffectivelyUnread = isUnread && !isFuture;

        // 🌟 変更: 新規バッジ表示対象のみ薄い緑背景にする（ローカル保持状態を使用）
        final backgroundColor = showNewBadge ? const Color(0xFFE8FCEF) : Colors.white;

        // 送信者情報の取得 (仮実装のProviderを使用)
        final senderProfileAsync = ref.watch(fetchUserProfileProvider(message.senderId));
        // 自分のプロフィールを取得
        final myProfileAsync = ref.watch(fetchUserProfileProvider(myId));

        return Opacity(
          opacity: isFuture ? 0.6 : 1.0, // 未来のスケジュールは少し薄く
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              color: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: const Color(0xFFE0E0E0).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      MessageDetailModal(messageId: message.id),
                );
                // 🌟 変更: 未来のスケジュールでない場合のみ既読処理を行う
                if (isEffectivelyUnread) {
                  ref
                      .read(messageControllerProvider.notifier)
                      .markAsRead(message.id);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // 🌟 変更: 新規バッジはローカルに保持した初期未読状態を使用
                            if (showNewBadge) ...[
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1AD84C),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '新規',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],

                            // 時間
                            Flexible(
                              child: Text(
                                DateFormat('HH:mm').format(message.scheduleDate),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // スケジュールバッジ
                            if (message.isScheduled) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF858585), // グレー
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'スケジュール',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],

                            // スピーカーアイコン
                            if (message.isOperationAnnouncementRequired) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.volume_up_rounded,
                                size: 18,
                                color: Color(0xFF8A6FE6),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // 右側: 送信者情報
                      senderProfileAsync.when(
                        data: (profile) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: const Color(0xFF9E9E9E),
                              child: const Icon(Icons.person, size: 12, color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile.displayName,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              size: 10,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            myProfileAsync.when(
                              data: (myProfile) => Text(
                                myProfile.displayName,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              loading: () => const Text(
                                '...',
                                style: TextStyle(fontSize: 11),
                              ),
                              error: (_, __) => const Text(
                                'あなた',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (message.receiverIds.length > 1) ...[
                              const SizedBox(width: 2),
                              Text(
                                ' 他${message.receiverIds.length - 1}人',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ],
                        ),
                        loading: () => const SizedBox(width: 20),
                        error: (_, __) =>
                            const Text('Error', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        message.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (message.isCheckShared)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFE8700),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '共有',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        if (isChecked) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_box,
                                size: 18,
                                color: Color(0xFFFE8700),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '完了',
                                style: TextStyle(
                                  color: Color(0xFFFE8700),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ] else if (message.isCheckRequired) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_box_outline_blank,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              if (message.checkDeadline != null)
                                Text(
                                  '${DateFormat('M/d HH:mm').format(message.checkDeadline!)} まで',
                                  style: TextStyle(
                                    color: isLate
                                        ? const Color(0xFFFF3232)
                                        : Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              if (message.checkDeadline == null)
                                const Text(
                                  '未完了',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                            ],
                          ),
                        ],

                        if (isLate)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3232),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '遅れ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
