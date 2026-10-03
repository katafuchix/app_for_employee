// features/operation/operation_statistics_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'operation_logic.dart';
import 'operation_master_provider.dart';
import 'operation_streams.dart';

part 'operation_statistics_provider.g.dart';

class StatisticsState {
  final int salesForecast;
  final int currentSales;

  final int totalTodoDurationMin;
  final int totalTaskDurationMin;

  final int individualCapacity;
  final int currentProductionPoints;
  final int targetProductionPoints;
  final double achievementRate;

  final Duration elapsedTime; // 経過時間
  final Duration totalWorkDuration; // 合計出勤時間

  final List<HourlyGraphData> hourlyGraphData;

  const StatisticsState({
    required this.salesForecast,
    required this.currentSales,
    required this.totalTodoDurationMin,
    required this.totalTaskDurationMin,
    required this.individualCapacity,
    required this.currentProductionPoints,
    required this.targetProductionPoints,
    required this.achievementRate,
    required this.elapsedTime,
    required this.totalWorkDuration,
    required this.hourlyGraphData,
  });
}

@riverpod
Future<StatisticsState> operationStatistics(
  Ref ref, {
  required String storeId,
  required DateTime date,
}) async {
  // 1. マスタデータ
  final master = await ref.watch(
    operationMasterDataProvider(storeId: storeId, date: date).future,
  );

  // 2. 全ての変動データストリーム
  final executions = await ref.watch(
    todoExecutionsStreamProvider(storeId: storeId, date: date).future,
  );
  final clocks = await ref.watch(
    workerClocksStreamProvider(storeId: storeId, date: date).future,
  );
  final taskExecutions = await ref.watch(
    taskExecutionsStreamProvider(storeId: storeId, date: date).future,
  );
  final dailySalesList = await ref.watch(
    dailySalesStreamProvider(storeId: storeId, date: date).future,
  );

  // 3. 時計 (グラフ更新用)
  ref.watch(minuteTickerProvider);

  // 4. 計算ロジック
  final now = DateTime.now();
  final openTime = master.openTime;
  final closeTime = master.closeTime;

  final effectiveEndTime = now.isBefore(closeTime) ? now : closeTime;
  Duration elapsedTime = Duration.zero;
  if (effectiveEndTime.isAfter(openTime)) {
    elapsedTime = effectiveEndTime.difference(openTime);
  }

  final currentSales = OperationLogic.calculateCurrentSales(
    dailySalesList: dailySalesList,
    openTime: openTime,
    closeTime: closeTime,
  );

  // 勤怠の合計時間はグラフ計算のために必要（AttendanceProviderとは別にここでも計算するか、再利用するか）
  // 整合性のためLogicを再利用して計算します。
  final attendanceResult = OperationLogic.aggregateAttendances(
    clocks: clocks,
    workerMap: master.workerMap,
  );

  final hourlyGraphData = OperationLogic.buildHourlyGraphData(
    openTime: openTime,
    closeTime: closeTime,
    setup: master.setup,
    dailySalesList: dailySalesList,
    clocks: clocks,
    executions: executions,
    taskExecutions: taskExecutions,
    currentSales: currentSales,
    individualCapacity: master.individualCapacity,
  );

  // 指標計算
  final salesForecast = master.setup.salesForecastInfos.fold(
    0,
    (sum, info) => sum + info.value,
  );

  final totalTodoDurationMin = executions.fold(
    0,
    (sum, e) => sum + e.executionMinute,
  );
  final totalTaskDurationMin = taskExecutions.fold(
    0,
    (sum, e) => sum + e.durationMinute,
  );
  final totalActivityMinutes = totalTodoDurationMin + totalTaskDurationMin;

  final activityPoints =
      (totalActivityMinutes / 60.0) * master.individualCapacity;
  final currentProductionPoints = activityPoints.toInt() + currentSales;

  final totalWorkMinutes = attendanceResult.totalDuration.inMinutes;
  final targetPoints = (totalWorkMinutes / 60.0) * master.individualCapacity;
  final targetProductionPoints = targetPoints.toInt();

  double achievementRate = 0.0;
  if (targetProductionPoints > 0) {
    achievementRate = currentProductionPoints / targetProductionPoints;
  }

  return StatisticsState(
    salesForecast: salesForecast,
    currentSales: currentSales,
    totalTodoDurationMin: totalTodoDurationMin,
    totalTaskDurationMin: totalTaskDurationMin,
    individualCapacity: master.individualCapacity,
    currentProductionPoints: currentProductionPoints,
    targetProductionPoints: targetProductionPoints,
    achievementRate: achievementRate,
    elapsedTime: elapsedTime,
    totalWorkDuration: attendanceResult.totalDuration,
    hourlyGraphData: hourlyGraphData,
  );
}
