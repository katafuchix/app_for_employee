import 'dart:math';
import 'package:collection/collection.dart';

import '../models/daily_sales_model.dart';
import '../models/daily_setup_model.dart';
import '../models/task_execution_model.dart';
import '../models/todo_execution_model.dart';
import '../models/todo_mapping_model.dart';
import '../models/todo_mode_model.dart';
import '../models/todo_model.dart';
import '../models/worker_clock_model.dart';
import '../models/worker_model.dart';

// Controllerで定義するクラスを参照するために仮定義、もしくはController側でLogicをimportする
// ここでは循環参照を防ぐため、データ保持用のクラスはController側、あるいは別ファイル定義が望ましいですが、
// 便宜上、戻り値は Record 型 ({...}) や List を中心に使用し、特定のStateクラスへの依存を減らします。

// グラフ描画用データクラス（Controllerでも使用）
class HourlyGraphData {
  final int hour;
  final DateTime startTime;
  final DateTime endTime;
  final int salesActual;
  final int salesForecast;
  final int productionTarget;
  final int productionActual;
  final int productionFromSales;
  final int productionFromTodo;
  final int productionFromTask;

  HourlyGraphData({
    required this.hour,
    required this.startTime,
    required this.endTime,
    required this.salesActual,
    required this.salesForecast,
    required this.productionTarget,
    required this.productionActual,
    required this.productionFromSales,
    required this.productionFromTodo,
    required this.productionFromTask,
  });
}

// タイムゾーン集計クラス
class TimezoneSummary {
  final TimezoneInfo info;
  final DateTime startTime;
  final DateTime endTime;
  final int totalItemCount;
  final int doneCount;
  final int skippedCount;
  final Duration remainingDuration;
  final bool isRemaining;
  final bool isEnded;

  double get progressRate =>
      totalItemCount > 0 ? (doneCount + skippedCount) / totalItemCount : 0.0;

  TimezoneSummary({
    required this.info,
    required this.startTime,
    required this.endTime,
    required this.totalItemCount,
    required this.doneCount,
    required this.skippedCount,
    required this.remainingDuration,
    required this.isRemaining,
    required this.isEnded,
  });
}

// タイムゾーングループ
class TimezoneGroup {
  final TimezoneInfo info;
  final DateTime startTime;
  final DateTime endTime;
  final List<PositionGroup> positionGroups;

  TimezoneGroup({
    required this.info,
    required this.startTime,
    required this.endTime,
    required this.positionGroups,
  });
}

// ポジショングループ
class PositionGroup {
  final PositionInfo info;
  final List<OperationTodoItem> items;

  DateTime? get completedAt {
    if (items.isEmpty) return null;
    DateTime? maxTime;
    for (final item in items) {
      if (!item.isDone) return null;
      final time = item.execution?.executionEndTime ?? item.execution?.baseDate;
      if (time != null) {
        if (maxTime == null || time.isAfter(maxTime)) {
          maxTime = time;
        }
      }
    }
    return maxTime;
  }

  PositionGroup({required this.info, required this.items});
}

// Todoアイテムラッパー
class OperationTodoItem {
  final TodoMapping mapping;
  final Todo? todoMaster;
  final TodoExecution? execution;

  OperationTodoItem({required this.mapping, this.todoMaster, this.execution});

  bool get isDone => execution != null;
  bool get isSkipped => execution?.isSkipped ?? false;
}

// 勤怠集計クラス
class WorkerAttendance {
  final Worker worker;
  final List<WorkerClock> clocks;
  final Duration totalWorkDuration;
  final bool isWorking;
  final String positionTitle;
  final String positionColorHex;

  WorkerAttendance({
    required this.worker,
    required this.clocks,
    required this.totalWorkDuration,
    required this.isWorking,
    required this.positionTitle,
    required this.positionColorHex,
  });
}

class OperationLogic {
  /// 現在の売上金額を算出する
  static int calculateCurrentSales({
    required List<DailySales> dailySalesList, // リスナーからはListで来る想定
    required DateTime openTime,
    required DateTime closeTime,
  }) {
    if (dailySalesList.isEmpty) return 0;
    // 最新のドキュメントを使用（通常1つだが念のため）
    final dailySales = dailySalesList.first;

    final validStart = openTime;
    final validEnd = closeTime.add(const Duration(hours: 3));

    SalesInfo? getLatestValidSales(List<SalesInfo> infos) {
      final validInfos = infos.where((info) {
        return info.sales != 0 &&
            (info.date.isAtSameMomentAs(validStart) ||
                info.date.isAfter(validStart)) &&
            (info.date.isAtSameMomentAs(validEnd) ||
                info.date.isBefore(validEnd));
      }).toList();

      if (validInfos.isEmpty) return null;
      validInfos.sort((a, b) => b.date.compareTo(a.date));
      return validInfos.first;
    }

    final latestInput = getLatestValidSales(dailySales.inputSalesInfos);
    final latestScraped = getLatestValidSales(dailySales.salesInfos);

    if (dailySales.isInputPriority) {
      return latestInput?.sales ?? latestScraped?.sales ?? 0;
    } else {
      return latestScraped?.sales ?? latestInput?.sales ?? 0;
    }
  }

  /// 勤怠情報の集計
  static ({List<WorkerAttendance> attendances, Duration totalDuration})
  aggregateAttendances({
    required List<WorkerClock> clocks,
    required Map<String, Worker> workerMap,
  }) {
    final now = DateTime.now();
    final clockGroups = groupBy(clocks, (WorkerClock c) => c.workerId);
    List<WorkerAttendance> attendances = [];
    Duration totalWorkDuration = Duration.zero;

    for (final entry in clockGroups.entries) {
      final workerId = entry.key;
      final workerClocks = entry.value;
      final worker = workerMap[workerId];

      if (worker != null) {
        Duration workerTotal = Duration.zero;
        bool isWorking = false;

        // 時計順にソートして計算
        final sortedClocks = [...workerClocks]
          ..sort(
            (a, b) =>
                (a.inTime ?? DateTime(0)).compareTo(b.inTime ?? DateTime(0)),
          );

        for (final clock in sortedClocks) {
          if (clock.inTime != null) {
            final end = clock.outTime ?? now;
            if (end.isAfter(clock.inTime!)) {
              workerTotal += end.difference(clock.inTime!);
            }
            if (clock.outTime == null) isWorking = true;
          }
        }
        totalWorkDuration += workerTotal;

        attendances.add(
          WorkerAttendance(
            worker: worker,
            clocks: sortedClocks,
            totalWorkDuration: workerTotal,
            isWorking: isWorking,
            positionTitle: worker.positionTitle,
            positionColorHex: worker.positionColorHex,
          ),
        );
      }
    }
    // ポジション順にソート
    attendances.sort((a, b) => Worker.compareByPosition(a.worker, b.worker));

    return (attendances: attendances, totalDuration: totalWorkDuration);
  }

  /// 時間別グラフデータの生成
  static List<HourlyGraphData> buildHourlyGraphData({
    required DateTime openTime,
    required DateTime closeTime,
    required DailySetup setup,
    required List<DailySales> dailySalesList,
    required List<WorkerClock> clocks,
    required List<TodoExecution> executions,
    required List<TaskExecution> taskExecutions,
    required int currentSales,
    required int individualCapacity,
  }) {
    List<HourlyGraphData> hourlyGraphData = [];
    final now = DateTime.now();
    final dailySales = dailySalesList.isNotEmpty ? dailySalesList.first : null;

    final baseHourStart = DateTime(
      openTime.year,
      openTime.month,
      openTime.day,
      openTime.hour,
    );

    int loopCount = 0;
    DateTime tempTime = baseHourStart;
    while (tempTime.isBefore(closeTime)) {
      loopCount++;
      tempTime = tempTime.add(const Duration(hours: 1));
    }

    for (int i = 0; i < loopCount; i++) {
      final hourStart = baseHourStart.add(Duration(hours: i));
      final hourEnd = hourStart.add(const Duration(hours: 1));
      final currentHour = hourStart.hour;

      // A. 売上予測
      final forecastInfo = setup.salesForecastInfos.firstWhereOrNull((info) {
        return info.date.hour == currentHour &&
            info.date.year == hourStart.year &&
            info.date.month == hourStart.month &&
            info.date.day == hourStart.day;
      });
      final hourlyForecast = forecastInfo?.value ?? 0;

      // B. 売上実績
      int hourlySales = 0;
      if (dailySales != null) {
        int getCumulativeSalesAt(DateTime targetTime, List<SalesInfo> infos) {
          final validInfos = infos.where((info) {
            return info.date.isBefore(targetTime) ||
                info.date.isAtSameMomentAs(targetTime);
          }).toList();

          if (validInfos.isEmpty) return 0;
          validInfos.sort((a, b) => b.date.compareTo(a.date));
          return min(validInfos.first.sales, currentSales);
        }

        int? calculateHourlyDelta(List<SalesInfo> infos) {
          final hasUpdateInHour = infos.any((info) {
            return (info.date.isAtSameMomentAs(hourStart) ||
                    info.date.isAfter(hourStart)) &&
                info.date.isBefore(hourEnd);
          });
          if (!hasUpdateInHour) return null;

          final endValue = getCumulativeSalesAt(
            hourEnd.subtract(const Duration(seconds: 1)),
            infos,
          );
          final startValue = getCumulativeSalesAt(
            hourStart.subtract(const Duration(seconds: 1)),
            infos,
          );
          return endValue - startValue;
        }

        final hourlyInputDelta = calculateHourlyDelta(
          dailySales.inputSalesInfos,
        );
        final hourlyScrapedDelta = calculateHourlyDelta(dailySales.salesInfos);

        if (dailySales.isInputPriority) {
          hourlySales = hourlyInputDelta ?? hourlyScrapedDelta ?? 0;
        } else {
          hourlySales = hourlyScrapedDelta ?? hourlyInputDelta ?? 0;
        }
      }

      // C. 生産性目標 (労働時間ベース)
      double hourlyTotalWorkMinutes = 0.0;
      for (final clock in clocks) {
        if (clock.inTime == null) continue;
        final clockIn = clock.inTime!;
        final clockOut = clock.outTime ?? now;

        final overlapStart = clockIn.isAfter(hourStart) ? clockIn : hourStart;
        final overlapEnd = clockOut.isBefore(hourEnd) ? clockOut : hourEnd;

        if (overlapEnd.isAfter(overlapStart)) {
          hourlyTotalWorkMinutes += overlapEnd
              .difference(overlapStart)
              .inMinutes;
        }
      }
      final hourlyProductionTarget =
          ((hourlyTotalWorkMinutes / 60.0) * individualCapacity).toInt();

      // D. Todo実績
      double hourlyTodoMinutes = 0.0;
      for (final exec in executions) {
        final finishTime = exec.executionEndTime;
        final duration = exec.executionMinute;
        if (duration <= 0) continue;
        final startTime = finishTime.subtract(Duration(minutes: duration));
        final overlapStart = startTime.isAfter(hourStart)
            ? startTime
            : hourStart;
        final overlapEnd = finishTime.isBefore(hourEnd) ? finishTime : hourEnd;

        if (overlapEnd.isAfter(overlapStart)) {
          hourlyTodoMinutes += overlapEnd.difference(overlapStart).inMinutes;
        }
      }
      final hourlyPointsFromTodo =
          ((hourlyTodoMinutes / 60.0) * individualCapacity).toInt();

      // E. Task実績
      double hourlyTaskMinutes = 0.0;
      for (final task in taskExecutions) {
        final finishTime = task.executionEndTime;
        final duration = task.durationMinute;
        if (duration <= 0) continue;
        final startTime = finishTime.subtract(Duration(minutes: duration));
        final overlapStart = startTime.isAfter(hourStart)
            ? startTime
            : hourStart;
        final overlapEnd = finishTime.isBefore(hourEnd) ? finishTime : hourEnd;

        if (overlapEnd.isAfter(overlapStart)) {
          hourlyTaskMinutes += overlapEnd.difference(overlapStart).inMinutes;
        }
      }
      final hourlyPointsFromTask =
          ((hourlyTaskMinutes / 60.0) * individualCapacity).toInt();

      final hourlyPointsFromSales = hourlySales;
      final hourlyProductionActual =
          hourlyPointsFromSales + hourlyPointsFromTodo + hourlyPointsFromTask;

      hourlyGraphData.add(
        HourlyGraphData(
          hour: currentHour,
          startTime: hourStart,
          endTime: hourEnd,
          salesActual: hourlySales,
          salesForecast: hourlyForecast,
          productionTarget: hourlyProductionTarget,
          productionActual: hourlyProductionActual,
          productionFromSales: hourlyPointsFromSales,
          productionFromTodo: hourlyPointsFromTodo,
          productionFromTask: hourlyPointsFromTask,
        ),
      );
    }
    return hourlyGraphData;
  }

  /// Todo/タイムゾーン情報の構築
  static ({List<TimezoneSummary> summaries, List<TimezoneGroup> groups})
  buildTimezoneData({
    required TodoMode mode,
    required List<TodoMapping> mappings,
    required List<TodoExecution> executions,
    required Map<String, Todo> todoMap,
    required DateTime openTime,
  }) {
    List<TimezoneSummary> timezoneSummaries = [];
    List<TimezoneGroup> timezoneGroups = [];
    final now = DateTime.now();

    DateTime currentTzStart = openTime;
    List<({TimezoneInfo info, DateTime start, DateTime end})> tzTimeRanges = [];
    for (final tz in mode.timezoneInfos) {
      final end = currentTzStart.add(Duration(minutes: tz.durationMinute));
      tzTimeRanges.add((info: tz, start: currentTzStart, end: end));
      currentTzStart = end;
    }

    for (final tzRange in tzTimeRanges) {
      List<PositionGroup> positionGroups = [];
      final allTzMappings = mappings
          .where((m) => m.timezoneId == tzRange.info.id)
          .toList();

      for (final position in mode.positionInfos) {
        final targetMappings = allTzMappings
            .where((m) => m.positionId == position.id)
            .toList();
        targetMappings.sort((a, b) => a.index.compareTo(b.index));

        final items = targetMappings.map((mapping) {
          // Worker側でもTodoExecutionはリストで来るので、最新のExecutionを探すロジックが必要ならここで実装
          // 今回はMapping IDで紐づく有効なExecutionを探す
          final execution = executions.firstWhereOrNull(
            (e) => e.mappingId == mapping.id,
          );
          return OperationTodoItem(
            mapping: mapping,
            todoMaster: todoMap[mapping.todoId],
            execution: execution,
          );
        }).toList();

        positionGroups.add(PositionGroup(info: position, items: items));
      }

      timezoneGroups.add(
        TimezoneGroup(
          info: tzRange.info,
          startTime: tzRange.start,
          endTime: tzRange.end,
          positionGroups: positionGroups,
        ),
      );

      int doneCount = 0;
      int skippedCount = 0;
      int remainingMinutes = 0;

      for (final mapping in allTzMappings) {
        final execution = executions.firstWhereOrNull(
          (e) => e.mappingId == mapping.id,
        );
        final isDone = execution != null;
        final isSkipped = execution?.isSkipped ?? false;

        if (isDone) {
          if (isSkipped) {
            skippedCount++;
          } else {
            doneCount++;
          }
        } else {
          final todo = todoMap[mapping.todoId];
          remainingMinutes += todo?.durationMinute ?? 0;
        }
      }

      final isRemaining = remainingMinutes > 0;
      final isEnded = now.isAfter(tzRange.end);

      timezoneSummaries.add(
        TimezoneSummary(
          info: tzRange.info,
          startTime: tzRange.start,
          endTime: tzRange.end,
          totalItemCount: allTzMappings.length,
          doneCount: doneCount,
          skippedCount: skippedCount,
          remainingDuration: Duration(minutes: remainingMinutes),
          isRemaining: isRemaining,
          isEnded: isEnded,
        ),
      );
    }

    return (summaries: timezoneSummaries, groups: timezoneGroups);
  }
}
