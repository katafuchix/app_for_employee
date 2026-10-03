// lib/shift_models.dart

class ShiftRecord {
  final String id;
  final DateTime baseDate;
  final DateTime inTime;
  final DateTime outTime;
  final double hourlyWage;

  ShiftRecord({
    required this.id,
    required this.baseDate,
    required this.inTime,
    required this.outTime,
    required this.hourlyWage,
  });
}

class BreakSegment {
  final DateTime start;
  final DateTime end;
  final Duration duration;

  BreakSegment({
    required this.start,
    required this.end,
    required this.duration,
  });
}

class DailyShiftSummary {
  final DateTime date;
  final List<ShiftRecord> segments;
  final DateTime firstIn;
  final DateTime lastOut;
  final Duration totalWork;
  final Duration totalBreak;
  final List<BreakSegment> breaks;

  DailyShiftSummary({
    required this.date,
    required this.segments,
    required this.firstIn,
    required this.lastOut,
    required this.totalWork,
    required this.totalBreak,
    required this.breaks,
  });
}

/// リポジトリから返却する月間の集計データ
class MonthlyShiftData {
  final Map<int, DailyShiftSummary> daySummaries;
  final Duration monthlyTotalWork;
  final int monthlyWorkingDays;

  MonthlyShiftData({
    required this.daySummaries,
    required this.monthlyTotalWork,
    required this.monthlyWorkingDays,
  });

  // データがない場合の初期値
  factory MonthlyShiftData.empty() {
    return MonthlyShiftData(
      daySummaries: {},
      monthlyTotalWork: Duration.zero,
      monthlyWorkingDays: 0,
    );
  }
}
