import 'package:flutter/material.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 戻る操作を無効化して画面をロックする
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 画像の破線アイコンに近い標準アイコンを使用
              const Icon(
                Icons.crop_free, 
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 32),
              const Text(
                '新規バージョンがあります',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'アプリケーションをアップデートしてください',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // 必要に応じてストアへ遷移するボタンなどを追加できます
            ],
          ),
        ),
      ),
    );
  }
}