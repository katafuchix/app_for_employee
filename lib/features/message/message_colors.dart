import 'package:flutter/material.dart';

/// Figmaデザインシステムの色定義
class MessageColors {
  // Primary Colors
  static const Color primary = Color(0xFF0084FF); // 基本選択色（青）
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Functional Colors
  static const Color deleteRed = Color(0xFFF30909); // 削除ボタン
  static const Color checkOrange = Color(0xFFFF8800); // チェック関連
  static const Color announcePurple = Color(0xFF8B20DC); // アナウンス
  static const Color delayRed = Color(0xFFFF3232); // 遅延・警告

  // Background Colors
  static const Color background1 = Color(0xFFF5F5F5); // 入力フィールド等の背景
  static const Color cardBackground = Colors.white; // カード背景

  // Text Colors
  static const Color subtitle = Color(0xFF858585); // サブタイトル・補足情報
  static const Color placeholder = Color(0xFFB8B8B8); // プレースホルダー

  // Status Colors
  static const Color badStatus = Color(0xFFF30909); // エラー・悪い状態
  static const Color goodStatus = Color(0xFF00C853); // 成功・良い状態
}

/// Figmaデザインシステムのテキストスタイル定義
class MessageTextStyles {
  // 共通フォントファミリー
  static const String fontFamily = 'Inter';

  // ヘッダー
  static const TextStyle header = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: MessageColors.black,
    fontFamily: fontFamily,
  );

  // 小見出し（From:, To: など）
  static const TextStyle labelSmall = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: MessageColors.black,
    fontFamily: fontFamily,
  );

  // ユーザー名
  static const TextStyle userName = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: MessageColors.black,
    fontFamily: fontFamily,
  );

  // ユーザー名（小）
  static const TextStyle userNameSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: MessageColors.black,
    fontFamily: fontFamily,
  );

  // 本文
  static const TextStyle bodyText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: MessageColors.black,
    height: 1.4,
    fontFamily: fontFamily,
  );

  // 日時（通常）
  static const TextStyle datetime = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: MessageColors.black,
    fontFamily: fontFamily,
  );

  // 日時（サブタイトル）
  static const TextStyle datetimeSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: MessageColors.subtitle,
    fontFamily: fontFamily,
  );

  // ラベル（サブタイトル）
  static const TextStyle labelSubtitle = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: MessageColors.subtitle,
    fontFamily: fontFamily,
  );

  // バッジテキスト
  static const TextStyle badgeText = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: MessageColors.white,
    fontFamily: fontFamily,
  );

  // ボタンテキスト
  static const TextStyle buttonText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: MessageColors.white,
    fontFamily: fontFamily,
  );

  // プレースホルダー
  static const TextStyle placeholder = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: MessageColors.placeholder,
    fontFamily: fontFamily,
  );

  // 返信テキスト
  static const TextStyle replyText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: MessageColors.black,
    fontFamily: fontFamily,
  );

  // 単位付き数字（大）
  static const TextStyle numberLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: MessageColors.black,
    fontFamily: fontFamily,
  );

  // 単位付き数字（中）
  static const TextStyle numberMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: MessageColors.subtitle,
    fontFamily: fontFamily,
  );

  // 単位テキスト
  static const TextStyle unitText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: MessageColors.black,
    fontFamily: fontFamily,
  );

  // 単位テキスト（小）
  static const TextStyle unitTextSmall = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: MessageColors.subtitle,
    fontFamily: fontFamily,
  );

  // 警告テキスト（小）
  static const TextStyle warningTextSmall = TextStyle(
    fontSize: 7.5,
    fontWeight: FontWeight.w600,
    color: MessageColors.delayRed,
    fontFamily: fontFamily,
  );

  // アクション時刻（オレンジ）
  static const TextStyle actionTime = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: MessageColors.checkOrange,
    fontFamily: fontFamily,
  );

  // アクション時刻（赤・遅延）
  static const TextStyle actionTimeDelay = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: MessageColors.delayRed,
    fontFamily: fontFamily,
  );
}
