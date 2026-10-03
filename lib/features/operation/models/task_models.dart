import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------
// 1. 共通・基本クラス
// ---------------------------------------------------------

/// FirestoreのTimestampなどを扱うための簡易クラス
class Time {
  final DateTime date;
  Time(this.date);

  // FirestoreのTimestampから変換
  factory Time.fromTimestamp(Timestamp timestamp) {
    return Time(timestamp.toDate());
  }
}

/// タスクのカテゴリー情報
///
class TaskCategory {
  final String id;
  final String title;
  final String colorHex;
  final String? detail; // Monthlyのみにある可能性があるためOptional

  TaskCategory({
    required this.id,
    required this.title,
    required this.colorHex,
    this.detail,
  });

  factory TaskCategory.fromJson(Map<String, dynamic> json, String id) {
    return TaskCategory(
      id: id,
      title: json['title'] ?? '',
      colorHex: json['color_hex'] ?? '#CCCCCC',
      detail: json['detail'],
    );
  }
}

// ---------------------------------------------------------
// 2. 月次タスク (Temporary Task)
// ---------------------------------------------------------

/// 月次タスク (Task Temporary)
///
class TaskTemporary {
  final String id;
  final String? categoryId;
  final DateTime baseDate;
  final String title;
  final bool useAim;
  final String aim;
  final bool useDetail;
  final String detail;
  final int priority;
  final bool isImageRequired;
  final int durationMinute;
  final bool isExecuted;
  final bool isSkipped;
  final List<String> manualIds;

  // UI結合用: カテゴリ情報
  final TaskCategory? category;

  TaskTemporary({
    required this.id,
    this.categoryId,
    required this.baseDate,
    required this.title,
    required this.useAim,
    required this.aim,
    required this.useDetail,
    required this.detail,
    required this.priority,
    required this.isImageRequired,
    required this.durationMinute,
    required this.isExecuted,
    required this.isSkipped,
    required this.manualIds,
    this.category,
  });

  static TaskTemporary? fromJson(Map<String, dynamic> json, String id) {
    try {
      if (id.isEmpty) {
        return null;
      }
      if ((json['category_id'] as String?) == null ||
          (json['category_id'] as String?)!.isEmpty) {
        return null;
      }
      final baseDateMap = json['base_date'] as Map<String, dynamic>? ?? {};
      final baseTimestamp = baseDateMap['date'] as Timestamp?;

      return TaskTemporary(
        id: id,
        categoryId: json['category_id'],
        baseDate: baseTimestamp?.toDate() ?? DateTime.now(),
        title: json['title'] ?? '',
        useAim: json['use_aim'] ?? false,
        aim: json['aim'] ?? '',
        useDetail: json['use_detail'] ?? false,
        detail: json['detail'] ?? '',
        priority: json['priority'] ?? 0,
        isImageRequired: json['is_image_required'] ?? false,
        durationMinute: json['duration_minute'] ?? 0,
        isExecuted: json['is_executed'] ?? false,
        isSkipped: json['is_skipped'] ?? false,
        manualIds: List<String>.from(json['manual_ids'] ?? []),
      );
    } catch (_) {
      return null;
    }
  }

  TaskTemporary copyWith({TaskCategory? category}) {
    return TaskTemporary(
      id: id,
      categoryId: categoryId,
      baseDate: baseDate,
      title: title,
      useAim: useAim,
      aim: aim,
      useDetail: useDetail,
      detail: detail,
      priority: priority,
      isImageRequired: isImageRequired,
      durationMinute: durationMinute,
      isExecuted: isExecuted,
      isSkipped: isSkipped,
      manualIds: manualIds,
      category: category,
    );
  }
}

// ---------------------------------------------------------
// 3. 定期タスク (Task Schedule & Task Info/Step)
// ---------------------------------------------------------

/// 定期タスクのスケジュール情報 (Task Schedule)
///
class TaskSchedule {
  final String id;
  final DateTime baseDate;
  final String taskId; // 実際のタスク内容への参照ID
  final bool isStepTask;
  final bool isExecuted;
  final bool isSkipped;
  final List<String> executedStepIds; // Stepタスクの場合の進捗

  TaskSchedule({
    required this.id,
    required this.baseDate,
    required this.taskId,
    required this.isStepTask,
    required this.isExecuted,
    required this.isSkipped,
    required this.executedStepIds,
  });

  static TaskSchedule? fromJson(Map<String, dynamic> json, String id) {
    try {
      if (id.isEmpty) {
        return null;
      }
      if (json['task_id'] == null || (json['task_id'] as String).isEmpty) {
        return null;
      }
      final baseDateMap = json['base_date'] as Map<String, dynamic>? ?? {};
      final baseTimestamp = baseDateMap['date'] as Timestamp?;

      return TaskSchedule(
        id: id,
        baseDate: baseTimestamp?.toDate() ?? DateTime.now(),
        taskId: json['task_id'] as String,
        isStepTask: json['is_step_task'] ?? false,
        isExecuted: json['is_executed'] ?? false,
        isSkipped: json['is_skipped'] ?? false,
        executedStepIds: List<String>.from(json['executed_step_ids'] ?? []),
      );
    } catch (_) {
      return null;
    }
  }
}

/// 通常タスク情報 (Task Info)
///
class TaskInfo {
  final String id;
  final String categoryId;
  final String title;
  final String detail;
  final bool useDetail;
  final int durationMinute;
  final int priority;
  final List<String> manualIds;

  TaskInfo({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.detail,
    required this.useDetail,
    required this.durationMinute,
    required this.priority,
    required this.manualIds,
  });

  factory TaskInfo.fromJson(Map<String, dynamic> json, String id) {
    return TaskInfo(
      id: id,
      categoryId: json['category_id'] ?? '',
      title: json['title'] ?? '',
      detail: json['detail'] ?? '',
      useDetail: json['use_detail'] ?? false,
      durationMinute: json['duration_minute'] ?? 0,
      priority: json['priority'] ?? 0,
      manualIds: List<String>.from(json['manual_ids'] ?? []),
    );
  }
}

/// ステップ詳細情報 (StepCodable)
///
class StepInfo {
  final String id;
  final String title;
  final String detail;
  final bool useDetail;
  final int durationMinute;

  StepInfo({
    required this.id,
    required this.title,
    required this.detail,
    required this.useDetail,
    required this.durationMinute,
  });

  factory StepInfo.fromJson(Map<String, dynamic> json) {
    return StepInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      detail: json['detail'] ?? '',
      useDetail: json['use_detail'] ?? false,
      durationMinute: json['duration_minute'] ?? 0,
    );
  }
}

/// ステップタスク情報 (Task Step Info)
///
class TaskStepInfo {
  final String id;
  final String categoryId;
  final String title;
  final List<StepInfo> stepInfos;
  final int priority;
  final List<String> manualIds;

  TaskStepInfo({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.stepInfos,
    required this.priority,
    required this.manualIds,
  });

  factory TaskStepInfo.fromJson(Map<String, dynamic> json, String id) {
    var list = json['step_infos'] as List? ?? [];
    List<StepInfo> stepsList = list.map((i) => StepInfo.fromJson(i)).toList();

    return TaskStepInfo(
      id: id,
      categoryId: json['category_id'] ?? '',
      title: json['title'] ?? '',
      stepInfos: stepsList,
      priority: json['priority'] ?? 0,
      manualIds: List<String>.from(json['manual_ids'] ?? []),
    );
  }
}

/// 定期タスクのUI表示用結合モデル
/// のSwift構造をDartで表現
class RegularTaskNode {
  final TaskSchedule schedule;
  final TaskInfo? taskInfo; // 通常タスクの場合
  final TaskStepInfo? stepInfo; // ステップタスクの場合
  final TaskCategory? category; // カテゴリ

  RegularTaskNode({
    required this.schedule,
    this.taskInfo,
    this.stepInfo,
    this.category,
  });
}
