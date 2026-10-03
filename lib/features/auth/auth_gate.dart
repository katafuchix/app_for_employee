// lib/auth_gate.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 既存ファイルをインポート
import 'login_page.dart';
import '../home/home_page.dart';

/// 1. ログイン状態を監視するゲート
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ロード中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 未ログイン -> ログイン画面
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // ログイン済み -> 連携チェックへ
        return const _AccountLinkingGate();
      },
    );
  }
}

/// 2. worker_id_map の有無を確認して振り分けるゲート
class _AccountLinkingGate extends StatelessWidget {
  const _AccountLinkingGate();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('worker_id_map')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // worker_id_map が存在する -> 通常のホーム画面へ [cite: 13]
        if (snapshot.hasData && snapshot.data!.exists) {
          return const HomePage();
        }

        // worker_id_map が存在しない -> 連結フロー画面へ [cite: 13, 14]
        return const _LinkingFlowPage();
      },
    );
  }
}

/// 3. worker_on_hold (待機状態) の有無を監視し、画面を切り替える
class _LinkingFlowPage extends StatelessWidget {
  const _LinkingFlowPage();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('worker_on_hold') // PDF指示により _data 削除
          .doc(uid) // auth_id (uid) でドキュメントを探す
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final doc = snapshot.data;

        // ドキュメントが存在する -> コード表示画面
        if (doc != null && doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          return _CodeDisplayScreen(
            code: data['code'] ?? '---',
            message: data['message'] ?? '',
          );
        }

        // ドキュメントが存在しない -> メッセージ入力・作成画面
        return const _MessageInputScreen();
      },
    );
  }
}

// ==========================================
// 以下、UI部分 (分離しやすいように同ファイル内または別ファイルでも可)
// ==========================================

/// メッセージ入力・コード生成画面
class _MessageInputScreen extends StatefulWidget {
  const _MessageInputScreen();

  @override
  State<_MessageInputScreen> createState() => _MessageInputScreenState();
}

class _MessageInputScreenState extends State<_MessageInputScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _generateCodeAndSubmit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('メッセージを入力してください')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      String code = '';
      bool isUnique = false;

      // ユニークなコードを生成
      while (!isUnique) {
        // 6桁の数字生成
        code = (Random().nextInt(900000) + 100000).toString();
        // 重複チェック
        final query = await firestore
            .collection('worker_on_hold')
            .where('code', isEqualTo: code)
            .get();
        if (query.docs.isEmpty) {
          isUnique = true;
        }
      }

      // データの保存 (onHold)
      await firestore.collection('worker_on_hold').doc(user.uid).set({
        'auth_id': user.uid,
        'message': _messageController.text.trim(),
        'code': code,
        'matching_code': code,
        'created_at': FieldValue.serverTimestamp(), // 作成日
      });

      // StreamBuilderが検知して自動で画面遷移するため、ここでは何もしない
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('店舗への連携申請'),
        backgroundColor: const Color(0xFF02A493),
        elevation: 0,
        actions: [
          // ログアウト用（テスト時などに詰まないように）
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '店舗管理者に申請を送ります。\nあなたが誰かわかるようなメッセージを入力してください。',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'メッセージ',
                hintText: '例：山田太郎です！',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateCodeAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02A493),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('申請コードを発行する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// コード表示画面 [cite: 14, 17]
class _CodeDisplayScreen extends StatelessWidget {
  final String code;
  final String message;

  const _CodeDisplayScreen({required this.code, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      appBar: AppBar(
        title: const Text('連携コード'),
        backgroundColor: const Color(0xFF02A493),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '以下のコードを店舗管理者に\n伝えてください',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 40,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Color(0xFF02A493),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '送信メッセージ:\n$message',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              const Text(
                '店舗側で承認されると、\n自動的にホーム画面へ切り替わります。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
