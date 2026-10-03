import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'message_controller.dart';
import 'message_models.dart';
import 'message_detail_modal.dart'; // 詳細モーダル表示用

class SentTab extends ConsumerWidget {
  const SentTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentMessagesAsync = ref.watch(sentMessagesProvider);

    return sentMessagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(child: Text('送信済みのメッセージはありません'));
        }

        // 1. 日付ごとのグループ化 (InboxTabと同様のロジック)
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

        // 昇順（古い日付順 -> 今日 -> 未来）にソート
        // ※画像のデザイン上、新しいものが下に来る時系列が一般的ですが、
        //  要件に合わせてInboxと同じ並び順（昇順）にしています。
        final sortedDates = groupedMessages.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dayMessages = groupedMessages[date]!;

            dayMessages.sort((a, b) => b.scheduleDate.compareTo(a.scheduleDate));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. 日付ヘッダー (送信済みタブ専用デザイン)
                SentDateHeader(
                  targetDate: date,
                  count: dayMessages.length,
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
                    return SentMessageCard(message: message);
                  },
                ),
                const SizedBox(height: 20), // グループ間の余白
              ],
            );
          },
        );
      },
    );
  }
}

/// 送信済みタブ用の日付ヘッダー
/// デザイン: 「2/8 ---------------- 3件」
class SentDateHeader extends StatelessWidget {
  final DateTime targetDate;
  final int count;

  const SentDateHeader({
    super.key,
    required this.targetDate,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('M/d').format(targetDate);

    return Row(
      children: [
        // 日付
        Text(
          dateStr,
          style: const TextStyle(
            color: Color(0xFF858585),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(width: 12),
        // 中央の線
        Expanded(
          child: Container(
            height: 1.5,
            color: const Color(0xFFE0E0E0),
          ),
        ),
        const SizedBox(width: 12),
        // 件数
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Inter',
              ),
            ),
            const Text(
              '件',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 送信済みメッセージカード
/// 画像のデザインを再現
/// 送信済みメッセージカード
/// 画像のデザインを再現
class SentMessageCard extends ConsumerWidget {
  final Message message;

  const SentMessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 送信者（自分）のプロフィールを取得
    final senderProfileAsync = ref.watch(fetchUserProfileProvider(message.senderId));

    // 各種カウント・ステータスの計算
    final totalReceivers = message.receiverIds.length;
    final readCount = totalReceivers - message.unreadWorkerIds.length;
    final uncheckedCount = message.uncheckedWorkerIds.length;
    
    // 期限切れ判定
    final now = DateTime.now();
    final isDeadlinePassed = message.checkDeadline != null && message.checkDeadline!.isBefore(now);
    // 期限表示用フォーマット
    final deadlineStr = message.checkDeadline != null 
        ? DateFormat('M/d H:mmまで').format(message.checkDeadline!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
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
            // --- 1. Header Row (時間, スケジュール, 期限, スピーカー) ---
            Row(
              children: [
                // 時間
                Text(
                  DateFormat('HH:mm').format(message.scheduleDate),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 8),

                // スケジュールバッジ
                if (message.isScheduled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
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

                const Spacer(),

                // 期限表示
                if (message.checkDeadline != null) ...[
                  Container(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_box, size: 14, color: Color(0xFFFE8700)),
                        const SizedBox(width: 4),
                        Text(
                          deadlineStr!,
                          style: const TextStyle(
                            color: Color(0xFFFE8700),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 区切り線
                  Container(width: 1, height: 12, color: Colors.grey[300]),
                  const SizedBox(width: 8),
                ],

                // スピーカーアイコン
                if (message.isOperationAnnouncementRequired)
                  const Icon(Icons.volume_up_rounded, size: 20, color: Color(0xFF8A6FE6))
                else
                  const SizedBox.shrink(),
              ],
            ),

            const SizedBox(height: 12),

            // --- 2. Content ---
            Text(
              message.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            // --- 3. Footer Stats Row ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左側: 送信者情報
                Expanded(
                  flex: 3,
                  child: senderProfileAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (profile) => Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.black,
                          child: const Icon(Icons.person, size: 18, color: Colors.white)
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    profile.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.arrow_forward, size: 10, color: Colors.black),
                                      const SizedBox(width: 2),
                                      Text(
                                        '$totalReceivers',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Text(
                                        '人',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(width: 15),
                              // 縦線
                              Container(
                                width: 1,
                                height: 24,
                                color: Colors.grey[300],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 右側: 統計情報
                Expanded(
                  flex: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 既読
                      _buildStatColumn(
                        label: '既読',
                        content: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$readCount',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF858585),
                                fontFamily: 'Inter',
                              ),
                            ),
                            const Text(
                              '人',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF858585),
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle, size: 12, color: Color(0xFF1AD84C)),
                          ],
                        ),
                      ),

                      // チェック (修正したロジックを使用)
                      _buildCheckStatus(
                        message: message,
                        uncheckedCount: uncheckedCount,
                        totalCount: totalReceivers,
                        isDeadlinePassed: isDeadlinePassed
                      ),

                      // 画像
                      _buildStatColumn(
                        label: '画像',
                        content: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${message.imageCount}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: message.imageCount > 0 ? const Color(0xFFFE8700) : const Color(0xFF858585),
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              '件',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: message.imageCount > 0 ? const Color(0xFFFE8700) : const Color(0xFF858585),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 返信
                      _buildStatColumn(
                        label: '返信',
                        content: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${message.replyCount}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: message.replyCount > 0 ? const Color(0xFF0084FF) : const Color(0xFF858585),
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              '件',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: message.replyCount > 0 ? const Color(0xFF0084FF) : const Color(0xFF858585),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 統計情報の共通カラムビルダ
  Widget _buildStatColumn({required String label, required Widget content}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF858585),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 2),
        content,
      ],
    );
  }

  /// チェックステータスの表示ロジック
  /// チェックステータスの表示ロジック
  Widget _buildCheckStatus({
    required Message message,
    required int uncheckedCount,
    required int totalCount,
    required bool isDeadlinePassed,
  }) {
    Widget content;
    final checkedCount = totalCount - uncheckedCount;
    final isAllChecked = uncheckedCount == 0;

    // 1. チェック機能が不要 (isCheckRequired == false) の場合
    if (!message.isCheckRequired) {
      content = const Text(
        '-',
        style: TextStyle(
          color: Color(0xFF858585),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    // 2. 共有チェック (isCheckShared == true) の場合
    //    -> 誰か一人でもチェックしていれば「共有完了」
    else if (message.isCheckShared && checkedCount > 0) {
      content = const Text(
        '共有完了',
        style: TextStyle(
          color: Color(0xFFFE8700), // オレンジ
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    // 3. 通常チェック (isCheckShared == false) で全員完了した場合
    else if (isAllChecked && totalCount > 0) {
      content = const Text(
        '全員完了',
        style: TextStyle(
          color: Color(0xFFFE8700), // オレンジ
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    // 4. それ以外（未完了・進行中）
    else {
      // 期限切れの場合
      if (isDeadlinePassed) {
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 変更点: 残り人数ではなく「完了数/全体数」を表示
            Text(
              '$checkedCount/$totalCount', 
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold, // 数字を強調
                color: Color(0xFFFF3232),    // 赤文字で注意喚起
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3232), // 赤背景
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '遅延中',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      } else {
        // 通常進行中
        content = Text(
          '$checkedCount/$totalCount', // ここは「人」をつけずシンプルに比率のみ
          style: const TextStyle(
            color: Color(0xFF858585),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'チェック',
          style: TextStyle(
            color: Color(0xFF858585),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 2),
        content,
      ],
    );
  }
}