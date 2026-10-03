import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tebanashi/features/operation/models/todo_model.dart';

class TodoModeDoc {
  TodoModeDoc({
    required this.id,
    required this.title,
    required this.operationStartClockMinute,
    required this.timezones,
    required this.positions,
    required this.summaryInfos,
  });

  final String id;
  final String title;
  final int operationStartClockMinute;
  final List<TimezoneInfo> timezones;
  final List<PositionInfo> positions;
  final List<SummaryInfo> summaryInfos;

  static TodoModeDoc fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final title = (data['title'] ?? '').toString();
    final startMinRaw = data['operation_start_clock_minute'];
    final startMin = startMinRaw is num ? startMinRaw.toInt() : 0;

    final tzArr = data['timezone_infos'];
    final posArr = data['position_infos'];
    final sumArr = data['summary_infos'];

    final tzs = <TimezoneInfo>[];
    if (tzArr is List) {
      for (final e in tzArr) {
        if (e is Map<String, dynamic>) tzs.add(TimezoneInfo.fromMap(e));
      }
    }

    final poss = <PositionInfo>[];
    if (posArr is List) {
      for (final e in posArr) {
        if (e is Map<String, dynamic>) poss.add(PositionInfo.fromMap(e));
      }
    }

    final sums = <SummaryInfo>[];
    if (sumArr is List) {
      for (final e in sumArr) {
        if (e is Map<String, dynamic>) sums.add(SummaryInfo.fromMap(e));
      }
    }

    return TodoModeDoc(
      id: doc.id,
      title: title,
      operationStartClockMinute: startMin,
      timezones: tzs,
      positions: poss,
      summaryInfos: sums,
    );
  }
}

class TimezoneInfo {
  TimezoneInfo({
    required this.id,
    required this.title,
    required this.durationMinute,
  });

  final String id;
  final String title;
  final int durationMinute;

  static TimezoneInfo fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? '').toString();
    final title = (map['title'] ?? '').toString();

    final dRaw = map['duration_minute'];
    final d = dRaw is num ? dRaw.toInt() : 0;

    return TimezoneInfo(id: id, title: title, durationMinute: d);
  }
}

class PositionInfo {
  PositionInfo({
    required this.id,
    required this.title,
    required this.peopleCount,
  });

  final String id;
  final String title;
  final int peopleCount;

  static PositionInfo fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? map['position_id'] ?? map['title'] ?? '')
        .toString();
    final title = (map['title'] ?? '').toString();

    final pRaw = map['people_count'];
    final pc = pRaw is num ? pRaw.toInt() : 1;

    return PositionInfo(id: id, title: title, peopleCount: pc);
  }
}

class SummaryInfo {
  SummaryInfo({required this.timezoneId, required this.totalDurationMinute});

  final String timezoneId;
  final int totalDurationMinute;

  static SummaryInfo fromMap(Map<String, dynamic> map) {
    final tzId = (map['timezone_id'] ?? '').toString();
    final raw = map['total_duration_minute'];
    final total = raw is num ? raw.toInt() : 0;
    return SummaryInfo(timezoneId: tzId, totalDurationMinute: total);
  }
}

class TodoMappingDoc {
  TodoMappingDoc({
    required this.id,
    required this.modeId,
    required this.timezoneId,
    required this.positionId,
    required this.todoId,
    required this.index,
  });

  final String id;
  final String modeId;
  final String timezoneId;
  final String positionId;
  final String todoId;
  final int index;

  static TodoMappingDoc fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final modeId = (data['mode_id'] ?? '').toString();
    final timezoneId = (data['timezone_id'] ?? '').toString();
    final positionId = (data['position_id'] ?? '').toString();
    final todoId = (data['todo_id'] ?? '').toString();

    final idxRaw = data['index'];
    final idx = idxRaw is num ? idxRaw.toInt() : 0;

    return TodoMappingDoc(
      id: doc.id,
      modeId: modeId,
      timezoneId: timezoneId,
      positionId: positionId,
      todoId: todoId,
      index: idx,
    );
  }
}

class Todo2Doc {
  Todo2Doc({
    required this.id,
    required this.title,
    required this.detail,
    required this.durationMinute,
    required this.difficulty,
    // required this.isShared,
    required this.isSkippable,
    required this.manualIds,
    required this.useDetail,
    required this.checklistItems,
  });

  final String id;
  final String title;
  final String detail;
  final int durationMinute;
  final int difficulty;
  // final bool isShared;
  final bool isSkippable;
  final List<String> manualIds;
  final bool useDetail;
  final List<ChecklistItem> checklistItems;

  static Todo2Doc fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final title = (data['title'] ?? '').toString();
    final detail = (data['detail'] ?? '').toString();

    final durRaw = data['duration_minute'];
    final dur = durRaw is num ? durRaw.toInt() : 0;

    final diffRaw = data['difficulty'];
    final diff = diffRaw is num ? diffRaw.toInt() : 1;

    final isSkippable = data['is_skippable'] == true;

    final manualRaw = data['manual_ids'];
    final manualIds = <String>[];
    if (manualRaw is List) {
      for (final e in manualRaw) {
        if (e != null) manualIds.add(e.toString());
      }
    }

    final useDetail = data['use_detail'] == true;

    final checklistRawList =
        data['completion_checklist'] as List<dynamic>? ?? [];

    final checklist = checklistRawList.asMap().entries.map((entry) {
      final int index = entry.key;
      final Map<String, dynamic> itemData =
          entry.value as Map<String, dynamic>? ?? {};

      // IDを取得。もしnullまたは空文字なら、フォールバック用IDを生成
      String id = itemData['id'] as String? ?? '';
      if (id.isEmpty) {
        // "fallback_0", "fallback_1" のように一意なIDを付与
        id = 'fallback_index_$index';
      }

      // ChecklistItemを生成 (Mapを再構築して渡す)
      return ChecklistItem.fromMap({...itemData, 'id': id});
    }).toList();

    return Todo2Doc(
      id: doc.id,
      title: title,
      detail: detail,
      durationMinute: dur,
      difficulty: diff,
      // isShared: isShared,
      isSkippable: isSkippable,
      manualIds: manualIds,
      useDetail: useDetail,
      checklistItems: checklist,
    );
  }
}

class TodoRowVM {
  TodoRowVM({required this.displayIndex, required this.todo});

  final int displayIndex;
  final Todo2Doc todo;
}
