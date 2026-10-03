// features/operation/operation_todo_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tebanashi/features/operation/models/todo_execution_model.dart';
import 'package:tebanashi/features/operation/models/worker_model.dart';
import 'operation_logic.dart';
import '../operation_repository.dart';
import 'operation_master_provider.dart';
import 'operation_streams.dart';

part 'operation_todo_provider.g.dart';

class TodoListState {
  final List<TimezoneSummary> timezoneSummaries;
  final List<TimezoneGroup> timezoneGroups;
  final DateTime openTime;
  final DateTime closeTime;

  const TodoListState({
    required this.timezoneSummaries,
    required this.timezoneGroups,
    required this.openTime,
    required this.closeTime,
  });
}

@riverpod
Future<TodoListState> operationTodoList(
  Ref ref, {
  required String storeId,
  required DateTime date,
}) async {
  final master = await ref.watch(
    operationMasterDataProvider(storeId: storeId, date: date).future,
  );

  final executions = await ref.watch(
    todoExecutionsStreamProvider(storeId: storeId, date: date).future,
  );

  // 現在のタイムゾーン判定のために時計が必要
  ref.watch(minuteTickerProvider);

  final timezoneData = OperationLogic.buildTimezoneData(
    mode: master.mode,
    mappings: master.mappings,
    executions: executions,
    todoMap: master.todoMap,
    openTime: master.openTime,
  );

  return TodoListState(
    timezoneSummaries: timezoneData.summaries,
    timezoneGroups: timezoneData.groups,
    openTime: master.openTime,
    closeTime: master.closeTime,
  );
}

// 個別のTodo関連データ取得プロバイダー

@riverpod
Future<({TodoExecution? execution, String? workerName, String? workerPhotoUrl})>
latestTodoExecution(
  Ref ref, {
  required String storeId,
  required String todoId,
}) async {
  final repo = ref.read(operationRepositoryProvider);

  final execution = await repo.fetchLatestTodoExecution(
    storeId: storeId,
    todoId: todoId,
  );

  if (execution == null) {
    return (execution: null, workerName: null, workerPhotoUrl: null);
  }

  String? name;
  String? photoUrl;

  if (execution.workerId != null && execution.workerId!.isNotEmpty) {
    final results = await Future.wait([
      repo.fetchWorker(storeId, execution.workerId!),
      repo.fetchWorkerPhotoUrl(storeId: storeId, workerId: execution.workerId!),
    ]);

    final worker = results[0] as Worker?;
    photoUrl = results[1] as String?;

    if (worker != null) {
      name = '${worker.familyName} ${worker.givenName}';
    } else {
      name = '不明な担当者';
    }
  }

  return (execution: execution, workerName: name, workerPhotoUrl: photoUrl);
}

@riverpod
Future<String?> todoExecutionImageUrl(
  Ref ref, {
  required String storeId,
  required String executionId,
  required String submissionImageId,
}) {
  return ref
      .read(operationRepositoryProvider)
      .fetchTodoExecutionImageUrl(
        storeId: storeId,
        executionId: executionId,
        submissionImageId: submissionImageId,
      );
}
