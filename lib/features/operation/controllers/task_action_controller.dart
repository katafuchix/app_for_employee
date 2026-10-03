import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../operation_repository.dart';
import '../models/task_models.dart';
import '../models/task_execution_model.dart'; // 作成したモデル
import '../models/meta_data_model.dart'; // 既存のMetadata
import '../providers/operation_attendance_provider.dart';
import '../utils/image_compress_helper.dart';

part 'task_action_controller.g.dart';

// 画像の一時保存用Provider
@Riverpod(keepAlive: true)
class TaskImageState extends _$TaskImageState {
  @override
  File? build() => null;

  void setImage(File file) => state = file;
  void clear() => state = null;
}

@Riverpod(keepAlive: true)
TaskActionController taskActionController(Ref ref) {
  return TaskActionController(ref);
}

class TaskActionController {
  final Ref _ref;

  TaskActionController(this._ref);

  /// 1. 月次タスク (Temporary) の実施
  Future<void> executeTemporaryTask({
    required String storeId,
    required DateTime operationDate,
    required TaskTemporary task,
  }) async {
    final repo = _ref.read(operationRepositoryProvider);
    final imageFile = _ref.read(taskImageStateProvider);
    final workerId = await _ref.read(currentStoreWorkerIdProvider.future);

    // 1. 画像チェック
    if (task.isImageRequired && imageFile == null) {
      throw Exception('画像の提出が必要です');
    }

    // 2. 画像アップロード
    if (imageFile != null) {
      final compressedFile = await ImageCompressHelper.compressImage(imageFile);
      await repo.uploadTaskTemporaryImage(
        storeId: storeId,
        taskId: task.id,
        imageFile: compressedFile,
      );
    }

    // 3. Execution Info作成 (Modelを使用)
    final executionId = const Uuid().v4();
    final execution = TaskExecution(
      id: executionId,
      baseDate: operationDate, // 営業日
      executionEndTime: DateTime.now(),
      taskId: task.id,
      stepId: null,
      scheduleId: task.id,
      isTemporary: true,
      durationMinute: task.durationMinute,
      workerId: workerId,
      metadata: Metadata.create(),
    );

    await repo.createTaskExecution(storeId: storeId, execution: execution);

    // 4. ステータス更新
    await repo.completeTaskTemporary(storeId: storeId, taskId: task.id);

    // 画像ステートクリア
    _ref.read(taskImageStateProvider.notifier).clear();
  }

  /// 2. 通常タスク (Regular - Task Info) の実施
  Future<void> executeRegularTask({
    required String storeId,
    required DateTime operationDate,
    required RegularTaskNode node,
  }) async {
    final repo = _ref.read(operationRepositoryProvider);
    final workerId = await _ref.read(currentStoreWorkerIdProvider.future);

    final schedule = node.schedule;
    final taskInfo = node.taskInfo!;

    // 1. Execution Info作成
    final executionId = const Uuid().v4();
    final execution = TaskExecution(
      id: executionId,
      baseDate: operationDate,
      executionEndTime: DateTime.now(),
      taskId: taskInfo.id,
      stepId: null,
      scheduleId: schedule.id,
      isTemporary: false,
      durationMinute: taskInfo.durationMinute,
      workerId: workerId,
      metadata: Metadata.create(),
    );

    await repo.createTaskExecution(storeId: storeId, execution: execution);

    // 2. ステータス更新
    await repo.completeTaskSchedule(storeId: storeId, scheduleId: schedule.id);
  }

  /// 3. ステップタスク (Regular - Step Task) の実施
  Future<bool> executeStepTask({
    required String storeId,
    required RegularTaskNode node,
    required StepInfo stepToExecute,
  }) async {
    final repo = _ref.read(operationRepositoryProvider);
    final workerId = await _ref.read(currentStoreWorkerIdProvider.future);

    final schedule = node.schedule;
    final stepInfo = node.stepInfo!;

    // 1. Execution Info作成
    final executionId = const Uuid().v4();
    final execution = TaskExecution(
      id: executionId,
      baseDate: schedule.baseDate,
      executionEndTime: DateTime.now(),
      taskId: stepInfo.id,
      stepId: stepToExecute.id,
      scheduleId: schedule.id,
      isTemporary: false,
      durationMinute: stepToExecute.durationMinute,
      workerId: workerId,
      metadata: Metadata.create(),
    );

    await repo.createTaskExecution(storeId: storeId, execution: execution);

    // 2. ステップ進捗更新
    await repo.updateTaskScheduleStep(
      storeId: storeId,
      scheduleId: schedule.id,
      stepId: stepToExecute.id,
    );

    // 3. 完了判定
    final executedIds = {...schedule.executedStepIds, stepToExecute.id};
    final allStepIds = stepInfo.stepInfos.map((e) => e.id).toSet();

    if (executedIds.containsAll(allStepIds)) {
       await repo.completeTaskSchedule(storeId: storeId, scheduleId: schedule.id);
       return true; // ★すべてのステップが完了した場合は true を返す
    }
    
    return false; // ★まだ未完了のステップがある場合は false を返す
  }
}
