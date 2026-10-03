import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // print出力用
import 'package:app_badge_plus/app_badge_plus.dart';
import 'message_repository.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _repository = MessageRepository();

  Future<void> initialize() async {
    // 1. iOS向けの細かい権限設定を含めてリクエスト
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true, // 通知バナーの表示
      badge: true, // アプリアイコンのバッジ数の変更
      sound: true, // 通知音の再生
      provisional: false, // お試し通知（iOS 12以降）を利用するかどうか
    );

    // 2. ユーザーが通知を許可した場合（または仮許可した場合）のみ処理を進める
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('ユーザーがプッシュ通知を許可しました');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final token = await _messaging.getToken();
          if (token != null) {
            await _repository.updateNotificationToken(user.uid, token);
          }
        } catch (e) {
          if (kDebugMode) {
            print('トークンの取得に失敗しました: $e');
          }
        }

        _messaging.onTokenRefresh
            .listen((newToken) {
              _repository.updateNotificationToken(user.uid, newToken);
            })
            .onError((err) {
              if (kDebugMode) {
                print('トークンリフレッシュエラー: $err');
              }
            });
      }
    } else {
      if (kDebugMode) {
        print('ユーザーがプッシュ通知を拒否しました（権限がありません）');
      }
    }
  }

  Future<void> updateLocalBadge(int count) async {
    try {
      // app_badge_plus のメソッドに変更
      final isSupported = await AppBadgePlus.isSupported();
      if (!isSupported) return;

      if (count > 0) {
        await AppBadgePlus.updateBadge(count); // 🌟 変更
      } else {
        await AppBadgePlus.updateBadge(0); // 🌟 変更: 0を渡してバッジを消去
      }
    } catch (e) {
      if (kDebugMode) print('ローカルバッジの更新に失敗しました: $e');
    }
  }
}
