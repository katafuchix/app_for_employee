import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerClock {
  WorkerClock({
    required this.id,
    required this.baseDate,
    required this.inTime,
    required this.outTime,
  });

  final String id;
  final DateTime baseDate;
  final DateTime? inTime;
  final DateTime? outTime;

  static DateTime? _readDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is Map) {
      final inner = v['date'];
      if (inner is Timestamp) return inner.toDate();
      if (inner is DateTime) return inner;
    }
    return null;
  }

  static WorkerClock fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final baseRaw = data['base_date'];
    final baseDt = _readDate(baseRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final baseKey = DateTime(baseDt.year, baseDt.month, baseDt.day);

    return WorkerClock(
      id: doc.id,
      baseDate: baseKey,
      inTime: _readDate(data['in_time']),
      outTime: _readDate(data['out_time']),
    );
  }
}

class DailyWorkerScore {
  DailyWorkerScore({
    required this.id,
    required this.baseDate,
    required this.score,
    required this.todoExecutionMinute,
    required this.taskExecutionMinute,
  });

  final String id;
  final DateTime baseDate;

  final double score;

  // ✅ minute取得（ToDo / Task）
  final int todoExecutionMinute;
  final int taskExecutionMinute;

  static DateTime? _readDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is Map) {
      final inner = v['date'];
      if (inner is Timestamp) return inner.toDate();
      if (inner is DateTime) return inner;
    }
    return null;
  }

  static int _readInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    return 0;
  }

  static DailyWorkerScore fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final baseRaw = data['base_date'];
    final baseDt = _readDate(baseRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final baseKey = DateTime(baseDt.year, baseDt.month, baseDt.day);

    final rawScore = data['score'];
    final score = rawScore is num ? rawScore.toDouble() : 0.0;

    final todoMin = _readInt(data['todo_execution_minute']);
    final taskMin = _readInt(data['task_execution_minute']);

    return DailyWorkerScore(
      id: doc.id,
      baseDate: baseKey,
      score: score,
      todoExecutionMinute: todoMin,
      taskExecutionMinute: taskMin,
    );
  }
}

class DailyAttendance {
  DailyAttendance({
    required this.date,
    required this.minIn,
    required this.maxOut,
    required this.workDuration,
    required this.breakDuration,
    required this.score,
    required this.todoExecutionDuration,
    required this.taskExecutionDuration,
  });

  final DateTime date;
  final DateTime? minIn;
  final DateTime? maxOut;

  // 勤怠
  final Duration workDuration;
  final Duration breakDuration;

  // スコア（左の表示）
  final double? score;

  // ✅ 業務実績（minute → Duration）
  final Duration todoExecutionDuration;
  final Duration taskExecutionDuration;
}

class AttendanceMonthViewData {
  AttendanceMonthViewData({
    required this.days,
    required this.totalWorkDuration,
    required this.totalScore,
    required this.totalTodoExecutionDuration,
    required this.totalTaskExecutionDuration,
  });

  final List<DailyAttendance> days;

  // 勤怠合計
  final Duration totalWorkDuration;
  final double totalScore;

  // ✅ 業務実績合計
  final Duration totalTodoExecutionDuration;
  final Duration totalTaskExecutionDuration;
}
