import 'meta_data_model.dart';

class TodoMode {
  final String id;
  final String title;
  final int operationStartClockMinute; // 営業開始時間（0:00からの経過分数）
  final List<TimezoneInfo> timezoneInfos;
  final List<PositionInfo> positionInfos;
  final Metadata metadata;

  TodoMode({
    required this.id,
    required this.title,
    required this.operationStartClockMinute,
    required this.timezoneInfos,
    required this.positionInfos,
    required this.metadata,
  });

  factory TodoMode.fromMap(Map<String, dynamic> data, String docId) {
    return TodoMode(
      id: docId,
      title: data['title'] ?? '',
      operationStartClockMinute:
          (data['operation_start_clock_minute'] as num?)?.toInt() ?? 0,
      timezoneInfos:
          (data['timezone_infos'] as List<dynamic>?)
              ?.map((e) => TimezoneInfo.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      positionInfos:
          (data['position_infos'] as List<dynamic>?)
              ?.map((e) => PositionInfo.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: data['metadata'] != null
          ? Metadata.fromMap(data['metadata'] as Map<String, dynamic>)
          : Metadata.empty(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'operation_start_clock_minute': operationStartClockMinute,
      'timezone_infos': timezoneInfos.map((e) => e.toMap()).toList(),
      'position_infos': positionInfos.map((e) => e.toMap()).toList(),
      'metadata': metadata.toMap(),
    };
  }
}

class TimezoneInfo {
  final String id;
  final String title;
  final int durationMinute;

  TimezoneInfo({
    required this.id,
    required this.title,
    required this.durationMinute,
  });

  factory TimezoneInfo.fromMap(Map<String, dynamic> data) {
    return TimezoneInfo(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      durationMinute: (data['duration_minute'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'duration_minute': durationMinute};
  }
}

class PositionInfo {
  final String id;
  final String title;
  final String colorHex;
  final int peopleCount;

  PositionInfo({
    required this.id,
    required this.title,
    required this.colorHex,
    required this.peopleCount,
  });

  factory PositionInfo.fromMap(Map<String, dynamic> data) {
    return PositionInfo(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      colorHex: data['color_hex'] ?? '000000',
      peopleCount: (data['people_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'color_hex': colorHex,
      'people_count': peopleCount,
    };
  }
}
