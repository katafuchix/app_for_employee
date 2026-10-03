import 'package:cloud_firestore/cloud_firestore.dart';
import 'meta_data_model.dart'; // 既存のMetadata定義をインポート

class TaskExecution {
  final String id;
  final DateTime baseDate;
  final DateTime executionEndTime;
  final String taskId;
  final String? stepId;
  final String scheduleId;
  final bool isTemporary;
  final int durationMinute;
  final String workerId;
  final Metadata metadata;

  TaskExecution({
    required this.id,
    required this.baseDate,
    required this.executionEndTime,
    required this.taskId,
    this.stepId,
    required this.scheduleId,
    required this.isTemporary,
    required this.durationMinute,
    required this.workerId,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'base_date': {'date': Timestamp.fromDate(baseDate)}, // PDF仕様のTime型構造に合わせる
      'execution_end_time': {'date': Timestamp.fromDate(executionEndTime)},
      'task_id': taskId,
      'step_id': stepId,
      'schedule_id': scheduleId,
      'is_temporary': isTemporary,
      'duration_minute': durationMinute,
      'worker_id': workerId,
      'metadata': metadata.toMap(),
    };
  }

  static TaskExecution? fromMap(Map<String, dynamic> map, String id) {
    try {
      if (id.isEmpty) {
        return null;
      }
      if (map['task_id'] == null || (map['task_id'] as String).isEmpty) {
        return null;
      }
      if (map['schedule_id'] == null || (map['schedule_id'] as String).isEmpty) {
        return null;
      }
      if (map['worker_id'] == null || (map['worker_id'] as String).isEmpty) {
        return null;
      }
      // base_date.date の構造を考慮
      final baseDateMap = map['base_date'] as Map<String, dynamic>?;
      final baseDateTs = baseDateMap?['date'] as Timestamp?;

      final endTimeMap = map['execution_end_time'] as Map<String, dynamic>?;
      final endTimeTs = endTimeMap?['date'] as Timestamp?;

      return TaskExecution(
        id: id,
        baseDate: baseDateTs?.toDate() ?? DateTime.now(),
        executionEndTime: endTimeTs?.toDate() ?? DateTime.now(),
        taskId: map['task_id'] as String,
        stepId: map['step_id'],
        scheduleId: map['schedule_id'] as String,
        isTemporary: map['is_temporary'] ?? false,
        durationMinute: map['duration_minute'] ?? 0,
        workerId: map['worker_id'] as String,
        metadata: Metadata.fromMap(map['metadata'] ?? {}),
      );
    } catch (_) {
      return null;
    }
  }
}
