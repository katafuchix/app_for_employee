import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🌟 追加

import 'core/theme/app_colors.dart';
import 'features/auth/auth_gate.dart';
import 'features/message/notification_service.dart';
import 'features/message/message_controller.dart'; // 🌟 追加 (パスは適宜合わせてください)
import 'features/message/message_repository.dart'; // 🌟 追加 (パスは適宜合わせてください)
import 'firebase_options.dart';
import 'features/force_update/app_version_controller.dart';
import 'features/force_update/force_update_screen.dart';

// バージョンの文字列比較（'1.10' と '1.8' 等）を安全に行うための関数
bool _shouldForceUpdate({required String currentVersion, required String storeVersion}) {
  final currentParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final storeParts = storeVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

  final maxLength = currentParts.length > storeParts.length 
      ? currentParts.length 
      : storeParts.length;

  for (var i = 0; i < maxLength; i++) {
    final c = i < currentParts.length ? currentParts[i] : 0;
    final s = i < storeParts.length ? storeParts[i] : 0;

    if (c < s) return true;  // 現在のバージョンの方が古い -> アップデート必須
    if (c > s) return false; // 現在のバージョンの方が新しい -> アップデート不要
  }
  return false; // 全く同じバージョン
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService().initialize();
  runApp(const ProviderScope(child: MyApp()));
}

// 🌟 StatelessWidget から ConsumerWidget に変更
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🌟 アプリ起動中、常に合計バッジ数を監視するリスナー
    ref.listen<int>(totalBadgeCountProvider, (previous, next) async {
      // 値が変わっていない場合はスキップ（初期化時などの無駄な処理を防ぐ）
      if (previous == next) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        // 1. OSのバッジを更新
        await NotificationService().updateLocalBadge(next);

        // 2. Firestoreのバッジを絶対値で更新（バックグラウンド通知用）
        final repo = ref.read(messageRepositoryProvider);
        await repo.updateBadgeCount(user.uid, next);

        debugPrint('バッジを自動同期しました: $next');
      } catch (e) {
        debugPrint('バッジ同期エラー: $e');
      }
    });

    return MaterialApp(
      title: 'TEBANASHI Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        primaryColor: AppColors.teal,
        fontFamily: 'Roboto',
      ),
            builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) {
            final versionState = ref.watch(ownerAppVersionStreamProvider);

            // when() の戻り値をそのまま return します
            return versionState.when(
              loading: () {
                // アプリ起動時のチラつきを防ぐため、ローディング中はそのままchild(本来の画面)を見せておくか、
                // あるいはスプラッシュ画面を維持するのがUX上おすすめです。
                return child ?? const SizedBox.shrink(); 
              },
              error: (error, stack) {
                // エラーでアプリが使えなくなるのを防ぐため、一旦は通すなどのフォールバック設計も検討してください。
                return child ?? const SizedBox.shrink();
              },
              data: (versionModel) {
                if (versionModel == null) {
                  return child ?? const SizedBox.shrink();
                }

                // 現在のバージョンとFirestoreのバージョンを比較
                final isUpdateRequired = _shouldForceUpdate(
                  currentVersion: currentOwnerAppVersion,
                  storeVersion: versionModel.ownerVersion2,
                );

                if (isUpdateRequired) {
                  // アップデートが必要な場合のみ、元のUIを上書きして強制アップデート画面を表示
                  return const ForceUpdateScreen();
                }
                
                // 最新版の場合は本来のUIを表示
                return child ?? const SizedBox.shrink();
              },
            );
          },
        );
      },
      home: const AuthGate(),
    );
  }
}
