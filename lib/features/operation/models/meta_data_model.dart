import 'package:cloud_firestore/cloud_firestore.dart';

class Metadata {
  final DateTime? deletedTime;
  final DateTime? firstInteractionTime;
  final bool isDeleted;
  final DateTime? lastInteractionTime;
  final int? interactionCount;

  Metadata({
    this.deletedTime,
    this.firstInteractionTime,
    required this.isDeleted,
    this.lastInteractionTime,
    this.interactionCount,
  });

  // 空のメタデータを生成するファクトリ（データが存在しない場合用）
  factory Metadata.empty() {
    return Metadata(
      deletedTime: DateTime(4001, 1, 1, 9), //4001/1/1 9:00 UTC+9
      firstInteractionTime: DateTime.fromMillisecondsSinceEpoch(0),
      isDeleted: false,
      lastInteractionTime: DateTime.fromMillisecondsSinceEpoch(0),
      interactionCount: 0,
    );
  }

  factory Metadata.create() {
    return Metadata(
      deletedTime: DateTime(4001, 1, 1, 9), //4001/1/1 9:00 UTC+9
      firstInteractionTime: DateTime.now(),
      isDeleted: false,
      lastInteractionTime: DateTime.now(),
      interactionCount: 1,
    );
  }

  factory Metadata.fromMap(Map<String, dynamic> map) {
    // ヘルパー: ネストされた {date: Timestamp} から DateTime を取得
    DateTime? parseNestedDate(String key) {
      final fieldMap = map[key] as Map<String, dynamic>?;
      final timestamp = fieldMap?['date'];
      return (timestamp is Timestamp) ? timestamp.toDate() : null;
    }

    return Metadata(
      deletedTime: parseNestedDate('deleted_time'),
      firstInteractionTime: parseNestedDate('first_interaction_time'),
      isDeleted: map['is_deleted'] ?? false,
      lastInteractionTime: parseNestedDate('last_interaction_time'),
      interactionCount: map['interaction_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    // ヘルパー: DateTime を {date: Timestamp} に変換
    Map<String, dynamic>? dateToNestedMap(DateTime? date) {
      if (date == null) return null;
      return {'date': Timestamp.fromDate(date)};
    }

    return {
      'deleted_time': dateToNestedMap(deletedTime),
      'first_interaction_time': dateToNestedMap(firstInteractionTime),
      'is_deleted': isDeleted,
      'last_interaction_time': dateToNestedMap(lastInteractionTime),
      'interaction_count': interactionCount,
    };
  }
}
