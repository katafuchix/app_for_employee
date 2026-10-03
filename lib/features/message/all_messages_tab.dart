import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用に追加
import 'message_controller.dart';
import 'inbox_tab.dart'; // DateHeaderを利用するために残す
import 'message_models.dart';
import 'message_detail_modal.dart'; // 詳細モーダル用に追加

class AllMessagesTab extends ConsumerWidget {
  const AllMessagesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMessagesAsync = ref.watch(allMessagesProvider);
    // 日付ヘッダー表示のために自分のIDを取得
    final myIdAsync = ref.watch(currentStoreWorkerIdProvider);

    return allMessagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(child: Text('メッセージはありません'));
        }

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

        // 日付の昇順（古い日付順 -> 今日）にソート
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
                // 2. 日付ヘッダー (InboxTabのDateHeaderを再利用)
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
                    // 受信タブのInboxMessageCardではなく、全体用のAllMessageCardを使用する
                    return AllMessageCard(message: message);
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

/// 全体タブ用のメッセージカード
/// 個人の未読/既読ロジックや「あなた」という文言を排除し、全体視点でのステータスを表示する
class AllMessageCard extends ConsumerWidget {
  final Message message;

  const AllMessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isFuture = message.isScheduled && message.scheduleDate.isAfter(now);

    // 送信者情報の取得
    final senderProfileAsync = ref.watch(
      fetchUserProfileProvider(message.senderId),
    );

    return Opacity(
      opacity: isFuture ? 0.6 : 1.0, // 未来のスケジュールは少し薄く
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: Colors.white, // 全体ビューでは一律白背景（個人の未読状態に依存させない）
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
              builder: (context) => MessageDetailModal(messageId: message.id),
            );
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
                        // 時間
                        Text(
                          DateFormat('HH:mm').format(message.scheduleDate),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
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
                              color: const Color(0xFF858585),
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

                  // 右側: 送信者 -> 宛先の人数（全体ビュー用）
                  senderProfileAsync.when(
                    data: (profile) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: Colors.grey[400],
                          child: const Icon(
                            Icons.person,
                            size: 12,
                            color: Colors.white,
                          ),
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
                        Text(
                          '${message.receiverIds.length}人', // 「あなた」ではなく受信者数を表示
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

              // 全体ビュー用のステータス表示（進捗状況など）
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  spacing: 12,
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

                    if (message.isCheckRequired) ...[
                      // 全体の確認進捗状況を表示
                      if (message.isCheckShared &&
                          message.sharedCheckedWorkerId != null &&
                          message.sharedCheckedWorkerId!.isNotEmpty)
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
                        )
                      else if (!message.isCheckShared)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 修正箇所：全員完了しているか判定して色を変える
                            Icon(
                              Icons.check_box,
                              size: 18,
                              color:
                                  message.checkedTimeMap.length ==
                                      message.receiverIds.length
                                  ? const Color(0xFFFE8700)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${message.checkedTimeMap.length}/${message.receiverIds.length} 完了', // 個人ではなく全体の進捗
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                      if (message.checkDeadline != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('M/d HH:mm').format(message.checkDeadline!)} まで',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
