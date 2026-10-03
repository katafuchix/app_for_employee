import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'message_controller.dart';
import 'message_detail_modal.dart';
import 'message_models.dart';

class ActionTab extends ConsumerStatefulWidget {
  const ActionTab({super.key});

  @override
  ConsumerState<ActionTab> createState() => _ActionTabState();
}

class _ActionTabState extends ConsumerState<ActionTab> {
  // セッション開始時の未読アクションIDを保持（新規バッジの表示判定用）
  Set<String> _initialUnreadActionIds = {};
  bool _hasInitialized = false;

  void _initializeUnreadState(List<MessageAction> actions) {
    if (_hasInitialized) return;
    _hasInitialized = true;

    // 未読アクションのIDを保持
    final unreadIds = actions
        .where((a) => !a.isRead)
        .map((a) => a.id)
        .toSet();

    setState(() {
      _initialUnreadActionIds = unreadIds;
    });

    // 一括既読処理を実行
    if (unreadIds.isNotEmpty) {
      ref.read(messageControllerProvider.notifier).markActionsAsReadBatch(unreadIds.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentMinuteProvider);

    final actionsAsync = ref.watch(senderActionsProvider);

    return actionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('エラー: $err')),
      data: (actions) {
        if (actions.isEmpty) {
          return const Center(child: Text('アクションはありません'));
        }

        // 初期化処理を実行
        _initializeUnreadState(actions);

        // 1. 日付ごとのグループ化
        final Map<DateTime, List<MessageAction>> groupedActions = {};
        for (final action in actions) {
          if (action.metadata.firstInteractionTime == null) continue;

          final date = DateTime(
            action.metadata.firstInteractionTime!.year,
            action.metadata.firstInteractionTime!.month,
            action.metadata.firstInteractionTime!.day,
          );
          if (!groupedActions.containsKey(date)) {
            groupedActions[date] = [];
          }
          groupedActions[date]!.add(action);
        }

        final sortedDates = groupedActions.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dayActions = groupedActions[date]!;

            dayActions.sort(
              (a, b) => b.metadata.firstInteractionTime!.compareTo(
                a.metadata.firstInteractionTime!,
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日付ヘッダー (例: 2/8 ──── 3件)
                _buildDateHeader(date, dayActions.length),

                // その日のアクションリスト
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: dayActions.length,
                  itemBuilder: (context, i) {
                    final action = dayActions[i];
                    return ActionListTile(
                      action: action,
                      showNewBadge: _initialUnreadActionIds.contains(action.id),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date, int count) {
    // 現在時刻と「今日」かどうかの判定
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final timeStr = DateFormat('H:mm').format(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // --- 日付部分の表示分岐 ---
          if (isToday) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0084FF), // 青色
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
            Text(
              timeStr,
              style: const TextStyle(
                color: Color(0xFF0084FF), // 青色
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ] else ...[
            Text(
              DateFormat('M/d').format(date),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF666666),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(width: 12),

          // 中央の線
          Expanded(
            child: Container(
              height: 1.5,
              color: const Color(0xFFE0E0E0),
            ),
          ),

          const SizedBox(width: 12),

          // 件数表示 (ここは共通)
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
      ),
    );
  }
}

class ActionListTile extends ConsumerWidget {
  final MessageAction action;
  final bool showNewBadge;

  const ActionListTile({super.key, required this.action, this.showNewBadge = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageAsync = ref.watch(
      messageDetailFamilyProvider(action.messageId),
    );
    // ユーザー情報の取得
    final actorProfileAsync = ref.watch(
      fetchUserProfileProvider(action.actorId),
    );

    // ★ 背景色の設定（ローカル保持の初期未読状態を使用）
    final backgroundColor = showNewBadge ? const Color(0xFFE8FCEF) : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor, // ★ 背景色を未読状態に合わせて変更
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                MessageDetailModal(messageId: action.messageId),
          );
          if (!action.isRead) {
            ref
                .read(messageControllerProvider.notifier)
                .markActionAsRead(action.id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 上段: 元メッセージの抜粋と時刻 ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ★ 新規バッジ表示（ローカル保持の初期未読状態を使用）
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
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                  const Icon(Icons.reply, size: 16, color: Color(0xFF858585)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: messageAsync.when(
                      data: (msg) => Text(
                        msg?.content ?? 'メッセージが見つかりません',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF858585),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                      loading: () => const SizedBox(height: 10, width: 50),
                      error: (_, __) => const SizedBox(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat(
                      'HH:mm',
                    ).format(action.metadata.firstInteractionTime!),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- 中段: アバター、名前、アクション内容 ---
              actorProfileAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => const Text(
                  'ユーザー情報の取得に失敗しました',
                  style: TextStyle(fontSize: 10),
                ),
                data: (profile) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // アバター
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black,
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 「名前 さんが」
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.black,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text: profile.displayName,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            const TextSpan(
                              text: 'さんが',
                              style: TextStyle(
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // アクションの縦並びリスト
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (action.actionTypes.contains('check'))
                            _buildActionRow(Icons.check_box_rounded, const Color(0xFFFE8700), 'チェック'),
                          if (action.actionTypes.contains('image'))
                            _buildActionRow(Icons.camera_alt_rounded, const Color(0xFFFE8700), '画像提出'),
                          if (action.replyFromReceiver != null && action.replyFromReceiver!.isNotEmpty)
                            _buildActionRow(Icons.chat_bubble_rounded, const Color(0xFF0084FF), '返信'),
                        ],
                      ),

                      const SizedBox(width: 12),

                      // 「を実施しました。」
                      const Expanded(
                        child: Text(
                          'を実施しました。',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // --- 下段: 全員のチェック完了メッセージ ---
              messageAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (message) {
                  if (message == null) return const SizedBox.shrink();

                  // そもそもチェックが必要ないメッセージなら何も表示しない
                  if (!message.isCheckRequired) return const SizedBox.shrink();

                  String? statusText;

                  if (message.isCheckShared) {
                    // 共有チェック（誰か1人がやればOK）の場合
                    // checkedTimeMapに記録があれば完了とみなす
                    if (message.checkedTimeMap.isNotEmpty) {
                      statusText = 'チェックが完了しました！';
                    }
                  } else {
                    // 全員チェック（全員やる必要あり）の場合
                    // 未チェック者がおらず、かつ受信者が存在すれば完了とみなす
                    if (message.receiverIds.isNotEmpty &&
                        message.uncheckedWorkerIds.isEmpty) {
                      statusText = '全員のチェックが完了しました！';
                    }
                  }

                  if (statusText == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Center(
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Color(0xFFFE8700), // オレンジ
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // アイコン部分を少し四角い印象に
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
