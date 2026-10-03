import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../models/meta_data_model.dart';
import '../models/todo_execution_model.dart';
import '../models/todo_model.dart';
import '../operation_repository.dart';
import '../providers/operation_attendance_provider.dart';
import '../providers/operation_logic.dart';
import '../utils/image_compress_helper.dart';

part 'todo_action_controller.g.dart';

typedef TodoImageDraftMap = Map<String, Map<String, File>>;

class TodoImageDraftScope {
  final String storeId;
  final DateTime baseDate;
  final String mappingId;

  const TodoImageDraftScope({
    required this.storeId,
    required this.baseDate,
    required this.mappingId,
  });

  String get key {
    final dateText =
        '${baseDate.year.toString().padLeft(4, '0')}-'
        '${baseDate.month.toString().padLeft(2, '0')}-'
        '${baseDate.day.toString().padLeft(2, '0')}';
    return '$storeId/$dateText/$mappingId';
  }
}

@Riverpod(keepAlive: true)
class TodoImageDraft extends _$TodoImageDraft {
  @override
  TodoImageDraftMap build() {
    return {};
  }

  void saveDraft({
    required TodoImageDraftScope scope,
    required String submissionId,
    required File file,
  }) {
    final draftByMapping = Map<String, File>.from(state[scope.key] ?? const {});
    draftByMapping[submissionId] = file;
    state = {...state, scope.key: draftByMapping};
  }

  void removeDraft({
    required TodoImageDraftScope scope,
    required String submissionId,
  }) {
    final next = Map<String, Map<String, File>>.from(state);
    final draftByMapping = Map<String, File>.from(next[scope.key] ?? const {});
    draftByMapping.remove(submissionId);

    if (draftByMapping.isEmpty) {
      next.remove(scope.key);
    } else {
      next[scope.key] = draftByMapping;
    }

    state = next;
  }

  void clearDrafts(TodoImageDraftScope scope) {
    final next = Map<String, Map<String, File>>.from(state);
    next.remove(scope.key);
    state = next;
  }
}

@Riverpod(keepAlive: true)
TodoActionController todoActionController(Ref ref) {
  return TodoActionController(ref);
}

class TodoActionController {
  final Ref _ref;

  TodoActionController(this._ref);

  Future<void> completeTodo({
    required String storeId,
    required OperationTodoItem item,
    required DateTime baseDate,
    required int? inputCount,
    required Map<String, File> imageFiles,
  }) async {
    final repo = _ref.read(operationRepositoryProvider);
    final uuid = const Uuid().v4();
    final todo = item.todoMaster!;
    final currentWorkerId = await _ref.read(
      currentStoreWorkerIdProvider.future,
    );

    var executionMinute = 0;
    if (todo.durationType == TodoDurationType.fixed) {
      executionMinute = todo.durationMinute;
    } else if (todo.durationType == TodoDurationType.countable) {
      executionMinute = (inputCount ?? 0) * todo.countableDurationPerOne;
    }

    final requiredSubmissionIds = todo.imageSubmissionInfos
        .where((info) => info.isRequired)
        .map((info) => info.id)
        .toSet();
    if (!imageFiles.keys.toSet().containsAll(requiredSubmissionIds)) {
      throw Exception('必須画像が不足しています');
    }

    final submissionImageIds = imageFiles.keys.toList()..sort();
    final isImageSend = submissionImageIds.isNotEmpty;

    final execution = TodoExecution(
      id: uuid,
      baseDate: baseDate,
      mappingId: item.mapping.id,
      todoId: todo.id,
      workerId: currentWorkerId,
      executionMinute: executionMinute,
      executionEndTime: DateTime.now(),
      countableCount: todo.durationType == TodoDurationType.countable
          ? inputCount
          : null,
      isSkipped: false,
      isImageSend: isImageSend,
      metadata: Metadata.create(),
      submissionImageIds: submissionImageIds,
    );

    for (final entry in imageFiles.entries) {
      final compressedFile = await ImageCompressHelper.compressImage(
        entry.value,
      );
      await repo.uploadTodoExecutionImage(
        storeId: storeId,
        executionId: uuid,
        submissionImageId: entry.key,
        imageFile: compressedFile,
      );
    }

    await repo.createTodoExecution(storeId: storeId, execution: execution);
    _ref
        .read(todoImageDraftProvider.notifier)
        .clearDrafts(
          TodoImageDraftScope(
            storeId: storeId,
            baseDate: baseDate,
            mappingId: item.mapping.id,
          ),
        );
  }

  Future<void> skipTodo({
    required String storeId,
    required OperationTodoItem item,
    required DateTime baseDate,
  }) async {
    final repo = _ref.read(operationRepositoryProvider);
    final uuid = const Uuid().v4();
    final todo = item.todoMaster!;

    final execution = TodoExecution(
      id: uuid,
      baseDate: baseDate,
      mappingId: item.mapping.id,
      todoId: todo.id,
      workerId: null,
      executionMinute: 0,
      executionEndTime: DateTime.now(),
      countableCount: null,
      isSkipped: true,
      isImageSend: false,
      metadata: Metadata.create(),
      submissionImageIds: const [],
    );

    await repo.createTodoExecution(storeId: storeId, execution: execution);
  }

  Future<void> deleteExecution({
    required String storeId,
    required String executionId,
  }) async {
    final repo = _ref.read(operationRepositoryProvider);
    await repo.deleteTodoExecution(storeId: storeId, executionId: executionId);
  }
}
