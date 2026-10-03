import 'package:cloud_firestore/cloud_firestore.dart';
import 'meta_data_model.dart';

class TodoExecution {
  final String id;
  final String mappingId;
  final DateTime baseDate;
  final DateTime executionEndTime;
  final int executionMinute;
  final bool isImageSend;
  final bool isSkipped;
  final String? workerId;
  final Metadata metadata;

  final String todoId;
  final int? countableCount;
  final List<String> submissionImageIds;

  TodoExecution({
    required this.id,
    required this.mappingId,
    required this.baseDate,
    required this.executionEndTime,
    required this.executionMinute,
    required this.isImageSend,
    required this.isSkipped,
    this.workerId,
    required this.metadata,
    required this.todoId,
    this.countableCount,
    required this.submissionImageIds,
  });

  static TodoExecution? fromMap(Map<String, dynamic> data, String docId) {
    try {
      if (docId.isEmpty) {
        return null;
      }
      if (data['todo_id'] == null || (data['todo_id'] as String).isEmpty) {
        return null;
      }
      if (data['mapping_id'] == null || (data['mapping_id'] as String).isEmpty) {
        return null;
      }
      // base_date.date の取得
      final baseDateMap = data['base_date'] as Map<String, dynamic>? ?? {};
      final baseTimestamp = baseDateMap['date'] as Timestamp?;

      final executionEndTimeMap =
          data['execution_end_time'] as Map<String, dynamic>? ?? {};
      final executionEndTimestamp = executionEndTimeMap['date'] as Timestamp?;

      return TodoExecution(
        id: docId,
        mappingId: data['mapping_id'] as String,
        baseDate: baseTimestamp?.toDate() ?? DateTime.now(),
        executionEndTime: executionEndTimestamp?.toDate() ?? DateTime.now(),
        executionMinute: (data['execution_minute'] as num?)?.toInt() ?? 0,
        isImageSend: data['is_image_send'] ?? false,
        isSkipped: data['is_skipped'] as bool,
        workerId: data['worker_ids'] as String?,
        metadata: data['metadata'] != null
            ? Metadata.fromMap(data['metadata'] as Map<String, dynamic>)
            : Metadata.empty(),
        todoId: data['todo_id'] as String,
        countableCount: (data['countable_count'] as num?)?.toInt(),
        submissionImageIds: List<String>.from(
          data['submission_image_ids'] ?? data['submissionImageIds'] ?? const [],
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mapping_id': mappingId,
      'base_date': {'date': Timestamp.fromDate(baseDate)},
      'execution_end_time': {
        'date': Timestamp.fromDate(executionEndTime),
      }, // 構造を統一
      'execution_minute': executionMinute,
      'is_image_send': isImageSend,
      'is_skipped': isSkipped,
      'worker_ids': workerId,
      'metadata': metadata.toMap(),
      'todo_id': todoId,
      'countable_count': countableCount,
      'submission_image_ids': submissionImageIds,
    };
  }
}
