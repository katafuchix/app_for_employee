// features/operation/operation_streams.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../operation_repository.dart';
import '../models/daily_sales_model.dart';
import '../models/daily_setup_model.dart';
import '../models/task_execution_model.dart';
import '../models/todo_execution_model.dart';
import '../models/worker_clock_model.dart';

part 'operation_streams.g.dart';

@riverpod
Stream<DailySetup?> operationStatusStream(
  Ref ref, {
  required String storeId,
  required String dailySetupId,
}) {
  return ref
      .read(operationRepositoryProvider)
      .watchDailySetup(storeId, dailySetupId);
}

@riverpod
Stream<List<TodoExecution>> todoExecutionsStream(
  Ref ref, {
  required String storeId,
  required DateTime date,
}) {
  return ref
      .read(operationRepositoryProvider)
      .watchTodoExecutions(storeId, date);
}

@riverpod
Stream<List<WorkerClock>> workerClocksStream(
  Ref ref, {
  required String storeId,
  required DateTime date,
}) {
  return ref.read(operationRepositoryProvider).watchWorkerClocks(storeId, date);
}

@riverpod
Stream<List<TaskExecution>> taskExecutionsStream(
  Ref ref, {
  required String storeId,
  required DateTime date,
}) {
  return ref
      .read(operationRepositoryProvider)
      .watchTaskExecutions(storeId, date);
}

@riverpod
Stream<List<DailySales>> dailySalesStream(
  Ref ref, {
  required String storeId,
  required DateTime date,
}) {
  return ref.read(operationRepositoryProvider).watchDailySales(storeId, date);
}

@riverpod
Stream<DateTime> minuteTicker(Ref ref) {
  return Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
}
