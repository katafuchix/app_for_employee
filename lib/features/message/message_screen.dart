import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'message_models.dart';
import 'package:tebanashi/features/message/action_tab.dart';
import 'package:tebanashi/features/message/sent_tab.dart';
import 'inbox_tab.dart';
import 'message_controller.dart';
import 'message_creation_modal.dart';
import 'all_messages_tab.dart';

class MessageScreen extends ConsumerStatefulWidget {
  const MessageScreen({super.key});

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showArrivalNotification(List<Message> newMessages) {
    if (!mounted) return;

    // 文言作成: "〇〇さん他X名からのメッセージが届きました"
    final count = newMessages.length;

    // プロフィール取得は非同期になるため、簡易的に件数通知とするか、
    // ここで ref.read を使ってキャッシュから名前を取ることも可能
    // 今回はシンプルに件数表示
    final text = '$count件のメッセージが届きました';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF0084FF), // ブランドカラー
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '確認',
          textColor: Colors.white,
          onPressed: () {
            // 受信箱タブに移動するなど
            _tabController.animateTo(0);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. 既存の処理：1分ごとのスケジュールメッセージチェック
    ref.listen(currentMinuteProvider, (previous, next) async {
      final newArrivals = await ref
          .read(messageControllerProvider.notifier)
          .checkNewArrivals();
      if (newArrivals.isNotEmpty) {
        _showArrivalNotification(newArrivals);
      }
    });

    // 2. 追加の処理：リアルタイムでの新規メッセージ（非スケジュール）受信チェック
    ref.listen<AsyncValue<List<Message>>>(inboxMessagesProvider, (
      previous,
      next,
    ) {
      // 初期ロード時(previous == null)は通知を出さないようにする
      if (previous != null && previous.hasValue && next.hasValue) {
        final previousMessages = previous.value!;
        final nextMessages = next.value!;

        // 以前のリストのIDをSetにして検索を高速化
        final previousIds = previousMessages.map((m) => m.id).toSet();

        // 以前のリストに含まれていない新しいメッセージを抽出
        final newlyAddedMessages = nextMessages
            .where((m) => !previousIds.contains(m.id))
            .toList();

        // スケジュールされていない（即時送信の）メッセージのみに絞り込む
        final immediateNewMessages = newlyAddedMessages
            .where((msg) => !msg.isScheduled)
            .toList();

        if (immediateNewMessages.isNotEmpty) {
          _showArrivalNotification(immediateNewMessages);
        }
      }
    });
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildHeader(context),

            const SizedBox(height: 24),

            // --- Custom Tab Bar (Figma Modified) ---
            _buildCustomTabBar(ref),

            // TabBarとコンテンツの間の余白は不要、あるいは最小限にする（画像のデザインに合わせる）
            // const SizedBox(height: 10),

            // --- Tab Content ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  InboxTab(),
                  ActionTab(),
                  SentTab(),
                  AllMessagesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      'コミュニケーション',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 21,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text(
                  '従業員間のやりとりを作成・確認',
                  style: TextStyle(
                    color: Color(0xFF858585),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const MessageCreationModal(),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: ShapeDecoration(
                color: const Color(0xFF0084FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.edit, color: Colors.white, size: 15),
                  SizedBox(width: 9),
                  Text(
                    '作成',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(WidgetRef ref) {
    // Badge Counts
    final inboxCount = ref.watch(inboxBadgeCountProvider);
    final hasLateMessage = ref.watch(inboxHasLateMessageProvider);
    final actionListAsync = ref.watch(senderActionsProvider);
    final actionCount = actionListAsync.maybeWhen(
      data: (actions) => actions.where((a) => !a.isRead).length,
      orElse: () => 0,
    );

    // Figma Styles
    const selectedTextColor = Color(0xFF0A0A0A);
    const unselectedTextColor = Color(0xFF858585);
    const indicatorColor = Color(0xFF0A0A0A);
    const dividerColor = Color(0xFFE0E0E0); // 薄いグレー

    return Container(
      width: double.infinity,
      // 横のパディングはデザインに合わせて調整してください
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. 下層：全体に伸びる灰色の線 (Divider)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1.0, // 細い線
              color: dividerColor,
            ),
          ),

          // 2. 上層：TabBar (選択時の黒い線を含む)
          TabBar(
            controller: _tabController,
            isScrollable: true, // タブ幅を中身に合わせる
            tabAlignment: TabAlignment.center, // 左寄せ (Flutter 3.13+)
            // バージョンによっては tabAlignment がない場合があるので、その場合は isScrollable: true のみでOK
            labelPadding: const EdgeInsets.symmetric(horizontal: 12), // タブ間の余白
            labelColor: selectedTextColor,
            unselectedLabelColor: unselectedTextColor,

            // インジケーター（選択時の黒線）の設定
            indicatorColor: indicatorColor,
            indicatorWeight: 3.0, // 少し太くして灰色の線の上に被せる
            indicatorSize: TabBarIndicatorSize.tab, // 線をタブの幅に合わせる

            labelStyle: const TextStyle(
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),

            // dividerColor: Colors.transparent, // TabBar標準のdividerを消す(Flutter 3.13以降)
            tabs: [
              Tab(height: 32, child: _buildTabContent('受信', inboxCount, hasWarning: hasLateMessage)),
              Tab(height: 32, child: _buildTabContent('アクション', actionCount)),
              Tab(height: 32, child: _buildTabContent('送信済み', 0)),
              Tab(height: 32, child: _buildTabContent('全体', 0)),
            ],
          ),
        ],
      ),
    );
  }

  // 引数に hasWarning = false を追加
  Widget _buildTabContent(
    String label,
    int badgeCount, {
    bool hasWarning = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label),
        if (badgeCount > 0) ...[
          const SizedBox(width: 6),

          // --- バッジのデザイン分岐 ---
          if (hasWarning)
            // 警告ありの場合: 赤色 + 「!」アイコン
            Container(
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              constraints: const BoxConstraints(minWidth: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3232), // 赤色 (遅れの色)
                borderRadius: BorderRadius.circular(10), // 丸みのある四角
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.priority_high,
                    size: 10,
                    color: Colors.white,
                  ), // ビックリマーク
                  const SizedBox(width: 1),
                  Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            )
          else
            // 通常の場合: 黒色正円 (既存のデザイン)
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
