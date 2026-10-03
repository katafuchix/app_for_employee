// features/operation/operation_attendance_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:collection/collection.dart';
import 'operation_logic.dart';
import '../operation_repository.dart';
import 'operation_master_provider.dart';
import 'operation_streams.dart';

part 'operation_attendance_provider.g.dart';

class AttendanceState {
  final List<WorkerAttendance> workerAttendances;
  final int totalWorkerCount;
  final Duration totalWorkDuration;

  const AttendanceState({
    required this.workerAttendances,
    required this.totalWorkerCount,
    required this.totalWorkDuration,
  });
}

@riverpod
Future<AttendanceState> operationAttendance(
  Ref ref, {
  required String storeId,
  required DateTime date,
}) async {
  // 1. マスタデータ (キャッシュ利用)
  final master = await ref.watch(
    operationMasterDataProvider(storeId: storeId, date: date).future,
  );

  // 2. 勤怠ストリームのみ監視
  final clocks = await ref.watch(
    workerClocksStreamProvider(storeId: storeId, date: date).future,
  );

  // 3. ロジック計算
  final result = OperationLogic.aggregateAttendances(
    clocks: clocks,
    workerMap: master.workerMap,
  );

  return AttendanceState(
    workerAttendances: result.attendances,
    totalWorkerCount: result.attendances.length,
    totalWorkDuration: result.totalDuration,
  );
}

@riverpod
Future<String> currentStoreWorkerId(Ref ref) async {
  return ref.read(operationRepositoryProvider).fetchCurrentStoreWorkerId();
}

@riverpod
Future<bool> isCurrentUserWorking(
  Ref ref, {
  required String storeId,
  required DateTime date,
}) async {
  // 自分のID
  final myId = await ref.watch(currentStoreWorkerIdProvider.future);

  // 勤怠ステータス (計算済み)
  final attendanceState = await ref.watch(
    operationAttendanceProvider(storeId: storeId, date: date).future,
  );

  final myAttendance = attendanceState.workerAttendances.firstWhereOrNull(
    (a) => a.worker.id == myId,
  );

  return myAttendance?.isWorking ?? false;
}
