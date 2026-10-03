// lib/shift_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // debugPrint用

import 'shift_models.dart';

class ShiftRepository {
  final FirebaseFirestore _firestore;

  ShiftRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 指定された月（month）のシフトデータを取得し、集計して返す
  Future<MonthlyShiftData> fetchMonthlyShiftSummaries({
    required String storeId,
    required String workerId,
    required DateTime month,
  }) async {
    try {
      final start = DateTime(month.year, month.month, 1);
      final nextMonth = DateTime(month.year, month.month + 1, 1);

      final col = _firestore
          .collection('store_data')
          .doc(storeId)
          .collection('shift');

      final snap = await col
          .where('worker_id', isEqualTo: workerId)
          .where('metadata.is_deleted', isEqualTo: false)
          .where(
            'base_date.date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('base_date.date', isLessThan: Timestamp.fromDate(nextMonth))
          .get();

      // --- 生データのパース ---
      final records = <ShiftRecord>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        try {
          final baseTs =
              (data['base_date']?['date'] as Timestamp?) ?? Timestamp.now();
          final inTs =
              (data['in_time']?['date'] as Timestamp?) ?? Timestamp.now();
          final outTs =
              (data['out_time']?['date'] as Timestamp?) ?? Timestamp.now();

          records.add(
            ShiftRecord(
              id: data['id'] as String? ?? doc.id,
              baseDate: baseTs.toDate(),
              inTime: inTs.toDate(),
              outTime: outTs.toDate(),
              hourlyWage: (data['hourly_wage'] as num?)?.toDouble() ?? 0,
            ),
          );
        } catch (e) {
          debugPrint('ShiftRecord parse error for doc ${doc.id}: $e');
        }
      }

      // --- 集計処理 ---

      // baseDate（日）ごとにまとめる
      final Map<int, List<ShiftRecord>> byDay = {};
      for (final r in records) {
        final keyDay = r.baseDate.day;
        byDay.putIfAbsent(keyDay, () => []).add(r);
      }

      final Map<int, DailyShiftSummary> daySummaries = {};
      Duration monthlyTotalWork = Duration.zero;
      int monthlyWorkingDays = 0;

      for (final entry in byDay.entries) {
        final day = entry.key;
        final list = [...entry.value];

        // 時間順にソート
        list.sort((a, b) => a.inTime.compareTo(b.inTime));

        final firstIn = list.first.inTime;
        final lastOut = list
            .map((e) => e.outTime)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        Duration totalWork = Duration.zero;
        for (final r in list) {
          final w = r.outTime.difference(r.inTime);
          if (!w.isNegative) {
            totalWork += w;
          }
        }

        final totalSpan = lastOut.difference(firstIn);
        Duration totalBreak = totalSpan - totalWork;
        if (totalBreak.isNegative) {
          totalBreak = Duration.zero;
        }

        // 休憩セグメントの計算
        final breaks = <BreakSegment>[];
        for (var i = 0; i < list.length - 1; i++) {
          final current = list[i];
          final next = list[i + 1];
          final gap = next.inTime.difference(current.outTime);
          if (!gap.isNegative && gap.inMinutes > 0) {
            breaks.add(
              BreakSegment(
                start: current.outTime,
                end: next.inTime,
                duration: gap,
              ),
            );
          }
        }

        final summary = DailyShiftSummary(
          date: DateTime(month.year, month.month, day),
          segments: list,
          firstIn: firstIn,
          lastOut: lastOut,
          totalWork: totalWork,
          totalBreak: totalBreak,
          breaks: breaks,
        );

        daySummaries[day] = summary;
        monthlyTotalWork += totalWork;
        monthlyWorkingDays++;
      }

      return MonthlyShiftData(
        daySummaries: daySummaries,
        monthlyTotalWork: monthlyTotalWork,
        monthlyWorkingDays: monthlyWorkingDays,
      );
    } catch (e) {
      debugPrint('ShiftRepository fetch error: $e');
      rethrow; // UI側でエラーハンドリングさせるため再スロー
    }
  }
}
