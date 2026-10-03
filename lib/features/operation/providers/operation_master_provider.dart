// features/operation/operation_master_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tebanashi/features/operation/models/daily_setup_model.dart';
import 'package:tebanashi/features/operation/models/todo_mapping_model.dart';
import 'package:tebanashi/features/operation/models/todo_mode_model.dart';
import 'package:tebanashi/features/operation/models/todo_model.dart';
import 'package:tebanashi/features/operation/models/worker_model.dart';
import '../operation_repository.dart';

part 'operation_master_provider.g.dart';

/// 営業画面で必要な静的データをまとめた型
typedef OperationMasterData = ({
  DailySetup setup,
  TodoMode mode,
  List<TodoMapping> mappings,
  Map<String, Todo> todoMap,
  Map<String, Worker> workerMap,
  int individualCapacity,
  DateTime openTime,
  DateTime closeTime,
});

@Riverpod(keepAlive: true)
Future<OperationMasterData> operationMasterData(
  Ref ref, {
  required String storeId,
  required DateTime date,
}) async {
  final repo = ref.read(operationRepositoryProvider);

  // 1. DailySetup取得
  final setup = await repo.fetchDailySetup(storeId, date);
  if (setup == null) {
    throw Exception('営業データ(DailySetup)が見つかりません。storeId: $storeId, date: $date');
  }

  // 2. TodoMode取得
  final mode = await repo.fetchTodoMode(storeId, setup.todoModeId);
  if (mode == null) throw Exception('Todoモードが見つかりません');

  // 3. 営業時間の計算
  final baseDateZero = DateTime(date.year, date.month, date.day);
  final openTime = baseDateZero.add(
    Duration(minutes: mode.operationStartClockMinute),
  );

  DateTime currentTzStart = openTime;
  for (final tz in mode.timezoneInfos) {
    currentTzStart = currentTzStart.add(Duration(minutes: tz.durationMinute));
  }
  final closeTime = currentTzStart;

  // 4. Mapping取得
  final mappings = await repo.fetchTodoMappings(
    storeId,
    mode.id,
    openTime,
    closeTime,
  );

  // 5. Todoマスタ取得
  final todoIds = mappings.map((e) => e.todoId).toList();
  final todos = await repo.fetchTodos(storeId, todoIds);
  final todoMap = {for (var t in todos) t.id: t};

  // 6. Workerマスタ全取得
  final allWorkers = await repo.fetchAllWorkers(storeId);
  final workerMap = {for (var w in allWorkers) w.id: w};

  // 7. 店舗設定(生産性基準)の取得
  final capacity = await repo.fetchStoreIndividualCapacity(storeId);

  return (
    setup: setup,
    mode: mode,
    mappings: mappings,
    todoMap: todoMap,
    workerMap: workerMap,
    individualCapacity: capacity,
    openTime: openTime,
    closeTime: closeTime,
  );
}
