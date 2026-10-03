import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/task_models.dart';
import '../operation_repository.dart';

part 'operation_task_provider.g.dart';

/// 月次タスク (Temporary) のStream
@riverpod
Stream<List<TaskTemporary>> operationMonthlyTasks(
  Ref ref, {
  required String storeId,
  required DateTime date,
}) {
  final repo = ref.read(operationRepositoryProvider);

  return repo.watchTaskTemporaries(storeId, date).asyncMap((tasks) async {
    // Future.waitを使って、全タスクのカテゴリ取得を並列化（同時に通信を走らせる）
    final enrichedTasks = await Future.wait(
      tasks.map((task) async {
        if (task.categoryId != null) {
          final category = await repo.fetchMonthlyTaskCategory(
            storeId,
            task.categoryId!,
          );
          if (category != null) {
            return task.copyWith(category: category);
          }
        }
        return task;
      }),
    );

    // 日付順にソートして返す（リストをコピーしてからソート）
    final sortedTasks = enrichedTasks.toList()
      ..sort((a, b) => a.baseDate.compareTo(b.baseDate));
    return sortedTasks;
  });
}

/// 定期タスク (Schedule) のStream
@riverpod
Stream<List<RegularTaskNode>> operationRegularTasks(
  Ref ref, {
  required String storeId,
  required DateTime date,
}) {
  final repo = ref.read(operationRepositoryProvider);

  return repo.watchTaskSchedules(storeId, date).asyncMap((schedules) async {
    // Future.waitを使って、全スケジュールのタスク詳細とカテゴリ取得を並列化
    final nodes = await Future.wait(
      schedules.map((schedule) async {
        TaskInfo? taskInfo;
        TaskStepInfo? stepInfo;
        TaskCategory? category;
        String? targetCategoryId;

        if (schedule.isStepTask) {
          // stepデータの取得
          final stepData = await repo.fetchTaskStepData(storeId, schedule.taskId);
          if (stepData != null) {
            stepInfo = TaskStepInfo.fromJson(stepData, schedule.taskId);
            targetCategoryId = stepInfo.categoryId;
          }
        } else {
          // 従来通り task2データの取得
          final taskData = await repo.fetchTask2Data(storeId, schedule.taskId);
          if (taskData != null) {
            taskInfo = TaskInfo.fromJson(taskData, schedule.taskId);
            targetCategoryId = taskInfo.categoryId;
          }
        }

        // カテゴリの取得（データが取れた場合のみ）
        if (targetCategoryId != null && targetCategoryId.isNotEmpty) {
           category = await repo.fetchTaskCategory(storeId, targetCategoryId);
        }

        return RegularTaskNode(
          schedule: schedule,
          taskInfo: taskInfo,
          stepInfo: stepInfo,
          category: category,
        );
      }),
    );

    // taskDataが存在しなかった不正なスケジュールを除外（必要に応じて）
    final validNodes = nodes
        .where((n) => n.taskInfo != null || n.stepInfo != null)
        .toList();

    // 日付順にソートして返す
    validNodes.sort(
      (a, b) => a.schedule.baseDate.compareTo(b.schedule.baseDate),
    );
    return validNodes;
  });
}
