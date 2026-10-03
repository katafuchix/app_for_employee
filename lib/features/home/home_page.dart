import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../message/message_controller.dart';
import '../../core/theme/app_colors.dart';
import '../manual/manual_page.dart';
import '../message/message_screen.dart';
import '../operation/operation_page.dart';
import '../shift/shift_page.dart';
import '../attendance/attendance_screen.dart';
import '../todo/todo_page.dart';
import 'home_models.dart';
import 'home_repository.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final HomeRepository _repository = HomeRepository();
  HomeWorkerProfile? _profile;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWorkerInfo();
  }

  Future<void> _loadWorkerInfo() async {
    try {
      final profile = await _repository.fetchCurrentWorkerProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ログアウト・アカウント削除メソッドは省略（変更なし）
  Future<void> _logout() async {
    try {
      await _repository.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ログアウトしました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ログアウトに失敗しました: $e')));
    }
  }

  Future<void> _confirmDeleteAccount() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('アカウント削除'),
          content: const Text(
            '本当にアカウントを削除しますか？\nこの操作は取り消せません。\n\n'
            '※削除には直近でのログインが必要です。エラーが出る場合は一度ログアウトして再ログインしてください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: const Text('削除する', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _loading = true);
    try {
      await _repository.deleteAccount();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('アカウントを削除しました')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'アカウント削除に失敗しました: ${e.message}';
      if (e.code == 'requires-recent-login') {
        msg = 'セキュリティのため、一度ログアウトして再ログインしてから実行してください。';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _profile?.displayName ?? '名前未登録';
    final photoUrl = _profile?.photoUrl;

    // --- 追加: 未読数の計算 ---
    final inboxCount = ref.watch(inboxBadgeCountProvider);
    final actionListAsync = ref.watch(senderActionsProvider);
    final actionCount = actionListAsync.maybeWhen(
      data: (actions) => actions.where((a) => !a.isRead).length,
      orElse: () => 0,
    );
    final totalUnread = inboxCount + actionCount;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                // 画面が長くなる可能性があるためScroll可能な形へ
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- 右上メニュー ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16, top: 8),
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.settings, color: Colors.grey),
                          tooltip: '設定',
                          onSelected: (value) {
                            if (value == 'logout') {
                              _logout();
                            } else if (value == 'delete') {
                              _confirmDeleteAccount();
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text('ログアウト'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_forever,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'アカウント削除',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _MessageCard(
                        unreadCount: totalUnread, // 追加
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MessageScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 36),

                    // --- ユーザー情報表示 ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 42,
                                    color: Colors.grey.shade700,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 18),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'こんにちは！',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$displayName さん',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 38),

                    // --- [追加] Operationボタン (リスナー監視) ---
                    // プロファイル取得済みでstoreIdがある場合のみ監視開始
                    if (_profile != null && _profile!.storeId != null)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _repository.streamOperationStatus(
                          _profile!.storeId!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            // エラー時は非表示にするか、ログを出す
                            return const SizedBox.shrink();
                          }

                          // データが無い、または空の場合は非表示 [cite: 7]
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          // 複数ある場合はbase_dateが小さい方(OrderByで先頭)を使用
                          final activeSetupDoc = snapshot.data!.docs.first;
                          // 必要であればドキュメントIDを取得して次の画面へ渡す
                          final dailySetupId = activeSetupDoc.id;
                          final operationDateTimestamp =
                              activeSetupDoc.data()['base_date']?['date']
                                  as Timestamp?;
                          if (operationDateTimestamp == null) {
                            return const SizedBox.shrink();
                          }
                          final operationDate = operationDateTimestamp.toDate();

                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            child: _OperationCard(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => OperationPage(
                                      dailySetupId: dailySetupId,
                                      storeId: _profile!.storeId!,
                                      storeWorkerId: _profile!.storeWorkerId!,
                                      operationDate: operationDate,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                    // --- シフトカード ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ShiftCard(
                        onTap: () {
                          if (_profile == null ||
                              _profile!.storeId == null ||
                              _profile!.storeWorkerId == null) {
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ShiftPage(
                                uid: _profile!.uid,
                                authId: _profile!.authId ?? '',
                                storeId: _profile!.storeId!,
                                storeWorkerId: _profile!.storeWorkerId!,
                                fullName: _profile!.displayName,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- 勤怠表カード ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _HomeMenuCard(
                        onTap: () {
                          if (_profile?.storeId == null ||
                              _profile?.storeWorkerId == null) {
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AttendanceScreen(
                                storeId: _profile!.storeId!,
                                storeWorkerId: _profile!.storeWorkerId!,
                                uid: _profile!.uid,
                                authId: _profile!.authId,
                                fullName: _profile!.displayName,
                              ),
                            ),
                          );
                        },
                        title: '勤怠表',
                        subtitle: '勤怠記録を確認できます',
                        accentColor: AppColors.orange,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- マニュアルカード ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _HomeMenuCard(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ManualPage(),
                            ),
                          );
                        },
                        title: 'マニュアル',
                        subtitle: '店舗のマニュアルを確認できます',
                        accentColor: const Color(0xFFFF2FB3),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Todoカード ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _HomeMenuCard(
                        onTap: () {
                          if (_profile?.storeId == null ||
                              _profile?.storeWorkerId == null) {
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TodoPage(
                                storeId: _profile!.storeId!,
                                storeWorkerId: _profile!.storeWorkerId!,
                                uid: _profile!.uid,
                                authId: _profile!.authId,
                                fullName: _profile!.displayName,
                              ),
                            ),
                          );
                        },
                        title: 'Todo',
                        subtitle: '店舗のTodoを確認できます',
                        accentColor: AppColors.orange,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- エラー表示 ---
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 40), // 下部余白
                  ],
                ),
              ),
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _OperationCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    // 営業中のボタンは目立つように、あるいは他のカードと統一感を出しつつ差別化
    return Container(
      height: 95,
      decoration: BoxDecoration(
        // 少し目立たせるために色を変えるか、枠をつける等のデザイン調整が可能
        // ここでは他と統一しつつアイコンを目立たせます
        color: Colors.white,
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.3),
          width: 1.5,
        ), // 青い枠線で強調
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.store_outlined, // お店アイコン
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '業務モード',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '現在営業中です。タップして開始します。',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _ShiftCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 95,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
          const BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            spreadRadius: -2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'シフト',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '出勤日を確認することができます',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: AppColors.orange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeMenuCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _HomeMenuCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 95,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
          const BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            spreadRadius: -2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 22, color: accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final VoidCallback? onTap;
  final int unreadCount; // 追加

  const _MessageCard({this.onTap, this.unreadCount = 0}); // 変更

  @override
  Widget build(BuildContext context) {
    const accentColor = Colors.blue;

    return Container(
      height: 95,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
          const BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            spreadRadius: -2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.forum_outlined,
                    size: 20,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'コミュニケーション',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'メッセージやアクションを確認できます',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                // --- 追加: 未読バッジ ---
                if (unreadCount > 0)
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3232), // 赤色
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 22, color: accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
