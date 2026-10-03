/// JST（日本標準時）ユーティリティ
/// すべての日付処理をJST（UTC+9）に統一する
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// 日本標準時のオフセット（UTC+9時間）
const Duration _jstOffset = Duration(hours: 9);

/// 現在時刻をJSTで取得
///
/// デバイスのタイムゾーン設定に関係なく、常にJSTの現在時刻を返します。
///
/// Example:
/// ```dart
/// final now = jstNow(); // 2024-03-15 14:30:00 (JST)
/// ```
DateTime jstNow() {
  return DateTime.now().toUtc().add(_jstOffset);
}

/// FirestoreのTimestampをJSTのDateTimeに変換
///
/// Firestoreから取得したTimestampを、デバイスのタイムゾーンに依存せず
/// 常にJSTとして解釈します。
///
/// Example:
/// ```dart
/// final timestamp = Timestamp.fromDate(DateTime.utc(2024, 3, 14, 15, 0, 0));
/// final jst = timestampToJST(timestamp); // 2024-03-15 00:00:00 (JST)
/// ```
DateTime timestampToJST(Timestamp timestamp) {
  return timestamp.toDate().toUtc().add(_jstOffset);
}

/// DateTimeをJSTの日付のみ（年月日）に正規化
///
/// 時刻情報を00:00:00にリセットし、JST基準の日付のみを取得します。
/// Firestore保存時やbaseDateキーの生成に使用します。
///
/// Example:
/// ```dart
/// final dateTime = DateTime(2024, 3, 15, 14, 30, 0);
/// final jstDate = toJSTDateOnly(dateTime); // 2024-03-15 00:00:00 (JST)
/// ```
DateTime toJSTDateOnly(DateTime dateTime) {
  final jst = dateTime.toUtc().add(_jstOffset);
  // UTC基準で年月日のみ抽出し、再度JSTオフセットを加える
  return DateTime.utc(jst.year, jst.month, jst.day).add(_jstOffset);
}

/// 年月日を指定してJSTのDateTimeを生成
///
/// 時刻は00:00:00に設定されます。
/// DateTime(year, month, day)の代替として使用します。
///
/// Example:
/// ```dart
/// final date = jstDate(2024, 3, 15); // 2024-03-15 00:00:00 (JST)
/// ```
DateTime jstDate(int year, int month, int day) {
  return DateTime.utc(year, month, day).add(_jstOffset);
}

/// Nullable版のtimestampToJST
///
/// nullの場合はnullを返します。
DateTime? timestampToJSTNullable(Timestamp? timestamp) {
  return timestamp != null ? timestampToJST(timestamp) : null;
}
