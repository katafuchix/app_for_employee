// lib/LoginPage.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLogin = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 画面のどこかをタップしたらキーボードを閉じる
  void _hideKeyboardIfNeeded() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.unfocus();
    }
  }

  Future<void> _submitAuth() async {
    _hideKeyboardIfNeeded();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'ログインに失敗しました';

      if (e.code == 'user-not-found') {
        msg = 'このメールアドレスのユーザーが見つかりません';
      } else if (e.code == 'wrong-password') {
        msg = 'パスワードが違います';
      } else if (e.code == 'invalid-email') {
        msg = 'メールアドレスの形式が正しくありません';
      } else if (e.code == 'user-disabled') {
        msg = 'このユーザーは無効化されています';
      }

      setState(() {
        _errorMessage = msg;
      });
    } catch (_) {
      setState(() {
        _errorMessage = '通信エラーが発生しました。時間をおいて再度お試しください。';
      });
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
    return GestureDetector(
      onTap: _hideKeyboardIfNeeded,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.teal, // ← 元のまま（変更なし）
        body: SafeArea(
          child: Column(
            children: [
              // ヘッダー（緑）
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 35, bottom: 28),
                color: AppColors.teal,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'TEBANASHI',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'アカウントにログインしてください',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // グレーのカード部分（角丸は元のまま）
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32), // 左上だけ丸く
                      topRight: Radius.circular(0), // 右上は直角
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        const _SectionLabel(text: 'メールアドレス'),
                        const SizedBox(height: 18),
                        _RoundedTextField(
                          controller: _emailController,
                          hintText: 'メールアドレスを入力してください',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 44),
                        const _SectionLabel(text: 'パスワード'),
                        const SizedBox(height: 18),
                        _RoundedTextField(
                          controller: _passwordController,
                          hintText: 'パスワードを入力してください',
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // エラーメッセージ表示
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else
                          const SizedBox(height: 44),

                        const SizedBox(height: 24),
                        Center(
                          child: SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? 'サインイン' : 'アカウント作成',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _errorMessage = null;
                              });
                            },
                            child: Text(
                              _isLogin
                                  ? 'アカウントをお持ちでない方はこちら'
                                  : 'すでにアカウントをお持ちの方はこちら',
                              style: const TextStyle(color: AppColors.teal),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
        // ★ 下端に「同じ色のボックス」を置いてグレーにする
        // ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
        bottomNavigationBar: Builder(
          builder: (context) {
            final bottom = MediaQuery.of(context).padding.bottom;
            return Container(
              height: bottom == 0 ? 8 : bottom, // 端末により下端分を確保
              color: AppColors.backgroundLight, // グレー箱
            );
          },
        ),
      ),
    );
  }
}

/// 「● メールアドレス」みたいなラベル
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.teal,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// 丸いテキストフィールド（高さ48で中身をセンター寄せ）
class _RoundedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const _RoundedTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48, // 枠の高さを固定
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            minLines: 1,
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: '',
              hintStyle: TextStyle(
                fontSize: 11,
                color: AppColors.textHint, // 濃いめグレー
              ),
            ).copyWith(hintText: hintText, suffixIcon: suffixIcon),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textInput, // 入力文字も濃いグレー
            ),
          ),
        ),
      ),
    );
  }
}
