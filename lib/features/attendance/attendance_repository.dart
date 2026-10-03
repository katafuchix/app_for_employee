import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'attendance_models.dart';

class AttendanceRepository {
  AttendanceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _workerClockCol(String storeId) {
    return _firestore
        .collection('store_data')
        .doc(storeId)
        .collection('worker_clock');
  }

  CollectionReference<Map<String, dynamic>> _scoreCol(String storeId) {
    return _firestore
        .collection('store_data')
        .doc(storeId)
        .collection('daily_worker_score');
  }

  bool _matchUser(
    Map<String, dynamic> data,
    String storeWorkerId,
    String? authId,
    String? uid,
  ) {
    bool eq(dynamic v, String? target) {
      if (v == null || target == null) return false;
      if (v is String) return v == target;
      return false;
    }

    if (eq(data['store_worker_id'], storeWorkerId)) return true;
    if (eq(data['worker_id'], storeWorkerId)) return true;
    if (eq(data['auth_id'], authId)) return true;
    if (eq(data['uid'], uid)) return true;

    return false;
  }

  Future<List<WorkerClock>> fetchWorkerClocksForMonth({
    required String storeId,
    required DateTime monthStart,
    required DateTime monthEnd,
    required String storeWorkerId,
    String? uid,
    String? authId,
  }) async {
    final snap = await _workerClockCol(storeId)
        .where(
          'base_date.date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
        )
        .where('base_date.date', isLessThan: Timestamp.fromDate(monthEnd))
        .get();

    final filtered = snap.docs.where((d) {
      return _matchUser(d.data(), storeWorkerId, authId, uid);
    }).toList();

    return filtered.map(WorkerClock.fromDoc).toList();
  }

  Future<List<DailyWorkerScore>> fetchDailyScoresForMonth({
    required String storeId,
    required DateTime monthStart,
    required DateTime monthEnd,
    required String storeWorkerId,
    String? uid,
    String? authId,
  }) async {
    final snap = await _scoreCol(storeId)
        .where(
          'base_date.date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
        )
        .where('base_date.date', isLessThan: Timestamp.fromDate(monthEnd))
        .get();

    final filtered = snap.docs.where((d) {
      return _matchUser(d.data(), storeWorkerId, authId, uid);
    }).toList();

    return filtered.map(DailyWorkerScore.fromDoc).toList();
  }
}

class AttendanceAggregator {
  static AttendanceMonthViewData buildMonthViewData({
    required DateTime monthStart,
    required List<WorkerClock> workerClocks,
    required List<DailyWorkerScore> dailyScores,
  }) {
    final daysInMonth = DateUtils.getDaysInMonth(
      monthStart.year,
      monthStart.month,
    );

    final Map<DateTime, List<WorkerClock>> clocksByDay = {};
    for (final c in workerClocks) {
      clocksByDay.putIfAbsent(c.baseDate, () => []).add(c);
    }

    final Map<DateTime, double> scoreByDay = {};
    final Map<DateTime, int> todoMinByDay = {};
    final Map<DateTime, int> taskMinByDay = {};

    for (final s in dailyScores) {
      scoreByDay[s.baseDate] = (scoreByDay[s.baseDate] ?? 0.0) + s.score;
      todoMinByDay[s.baseDate] =
          (todoMinByDay[s.baseDate] ?? 0) + s.todoExecutionMinute;
      taskMinByDay[s.baseDate] =
          (taskMinByDay[s.baseDate] ?? 0) + s.taskExecutionMinute;
    }

    Duration monthTotalWork = Duration.zero;
    double monthTotalScore = 0.0;

    int monthTodoMin = 0;
    int monthTaskMin = 0;

    final List<DailyAttendance> dayList = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final d = DateTime(monthStart.year, monthStart.month, day);
      final clocks = clocksByDay[d] ?? const <WorkerClock>[];

      DateTime? minIn;
      DateTime? maxOut;

      int totalWorkMs = 0;

      for (final c in clocks) {
        final inT = c.inTime;
        final outT = c.outTime;

        if (inT != null) {
          if (minIn == null || inT.isBefore(minIn)) minIn = inT;
        }
        if (outT != null) {
          if (maxOut == null || outT.isAfter(maxOut)) maxOut = outT;
        }

        if (inT != null && outT != null) {
          final diff = outT.difference(inT);
          if (!diff.isNegative) {
            totalWorkMs += diff.inMilliseconds;
          }
        }
      }

      final workDur = Duration(milliseconds: totalWorkMs);

      Duration breakDur = Duration.zero;
      if (minIn != null && maxOut != null) {
        final span = maxOut.difference(minIn);
        final rawBreak = span - workDur;
        breakDur = rawBreak.isNegative ? Duration.zero : rawBreak;
      }

      final score = scoreByDay.containsKey(d) ? scoreByDay[d] : null;

      final todoMin = todoMinByDay[d] ?? 0;
      final taskMin = taskMinByDay[d] ?? 0;

      final todoDur = Duration(minutes: todoMin);
      final taskDur = Duration(minutes: taskMin);

      monthTotalWork += workDur;
      monthTotalScore += (score ?? 0.0);

      monthTodoMin += todoMin;
      monthTaskMin += taskMin;

      dayList.add(
        DailyAttendance(
          date: d,
          minIn: minIn,
          maxOut: maxOut,
          workDuration: workDur,
          breakDuration: breakDur,
          score: score,
          todoExecutionDuration: todoDur,
          taskExecutionDuration: taskDur,
        ),
      );
    }

    return AttendanceMonthViewData(
      days: dayList,
      totalWorkDuration: monthTotalWork,
      totalScore: monthTotalScore,
      totalTodoExecutionDuration: Duration(minutes: monthTodoMin),
      totalTaskExecutionDuration: Duration(minutes: monthTaskMin),
    );
  }
}
