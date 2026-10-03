import 'meta_data_model.dart';

class TodoMapping {
  final String id;
  final String todoModeId; // mode_id
  final String positionId;
  final String timezoneId;
  final String todoId;
  final int index;
  final Metadata metadata;

  final int? countableDefault;

  TodoMapping({
    required this.id,
    required this.todoModeId,
    required this.positionId,
    required this.timezoneId,
    required this.todoId,
    required this.index,
    required this.metadata,
    this.countableDefault,
  });

  static TodoMapping? fromMap(Map<String, dynamic> data, String docId) {
    if (data['todo_id'] == null || (data['todo_id'] as String).isEmpty) {
      return null;
    }
    if (data['mode_id'] == null || (data['mode_id'] as String).isEmpty) {
      return null;
    }
    if (data['position_id'] == null ||
        (data['position_id'] as String).isEmpty) {
      return null;
    }
    if (data['timezone_id'] == null ||
        (data['timezone_id'] as String).isEmpty) {
      return null;
    }

    return TodoMapping(
      id: docId,
      todoModeId: data['mode_id'],
      positionId: data['position_id'],
      timezoneId: data['timezone_id'],
      todoId: data['todo_id'],
      index: (data['index'] as num?)?.toInt() ?? 0,
      metadata: data['metadata'] != null
          ? Metadata.fromMap(data['metadata'] as Map<String, dynamic>)
          : Metadata.empty(),
      countableDefault: (data['countable_default'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mode_id': todoModeId,
      'position_id': positionId,
      'timezone_id': timezoneId,
      'todo_id': todoId,
      'index': index,
      'metadata': metadata.toMap(),
      'countable_default': countableDefault,
    };
  }
}
