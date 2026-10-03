// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_todo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(operationTodoList)
const operationTodoListProvider = OperationTodoListFamily._();

final class OperationTodoListProvider
    extends
        $FunctionalProvider<
          AsyncValue<TodoListState>,
          TodoListState,
          FutureOr<TodoListState>
        >
    with $FutureModifier<TodoListState>, $FutureProvider<TodoListState> {
  const OperationTodoListProvider._({
    required OperationTodoListFamily super.from,
    required ({String storeId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'operationTodoListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$operationTodoListHash();

  @override
  String toString() {
    return r'operationTodoListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<TodoListState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TodoListState> create(Ref ref) {
    final argument = this.argument as ({String storeId, DateTime date});
    return operationTodoList(
      ref,
      storeId: argument.storeId,
      date: argument.date,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OperationTodoListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$operationTodoListHash() => r'03baa297c894363ceac6af5aa2045940eafedee7';

final class OperationTodoListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<TodoListState>,
          ({String storeId, DateTime date})
        > {
  const OperationTodoListFamily._()
    : super(
        retry: null,
        name: r'operationTodoListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OperationTodoListProvider call({
    required String storeId,
    required DateTime date,
  }) => OperationTodoListProvider._(
    argument: (storeId: storeId, date: date),
    from: this,
  );

  @override
  String toString() => r'operationTodoListProvider';
}

@ProviderFor(latestTodoExecution)
const latestTodoExecutionProvider = LatestTodoExecutionFamily._();

final class LatestTodoExecutionProvider
    extends
        $FunctionalProvider<
          AsyncValue<
            ({
              TodoExecution? execution,
              String? workerName,
              String? workerPhotoUrl,
            })
          >,
          ({
            TodoExecution? execution,
            String? workerName,
            String? workerPhotoUrl,
          }),
          FutureOr<
            ({
              TodoExecution? execution,
              String? workerName,
              String? workerPhotoUrl,
            })
          >
        >
    with
        $FutureModifier<
          ({
            TodoExecution? execution,
            String? workerName,
            String? workerPhotoUrl,
          })
        >,
        $FutureProvider<
          ({
            TodoExecution? execution,
            String? workerName,
            String? workerPhotoUrl,
          })
        > {
  const LatestTodoExecutionProvider._({
    required LatestTodoExecutionFamily super.from,
    required ({String storeId, String todoId}) super.argument,
  }) : super(
         retry: null,
         name: r'latestTodoExecutionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$latestTodoExecutionHash();

  @override
  String toString() {
    return r'latestTodoExecutionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<
    ({TodoExecution? execution, String? workerName, String? workerPhotoUrl})
  >
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<
    ({TodoExecution? execution, String? workerName, String? workerPhotoUrl})
  >
  create(Ref ref) {
    final argument = this.argument as ({String storeId, String todoId});
    return latestTodoExecution(
      ref,
      storeId: argument.storeId,
      todoId: argument.todoId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LatestTodoExecutionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$latestTodoExecutionHash() =>
    r'a419f16bddbd69b2332c7c175e93816ab263aac4';

final class LatestTodoExecutionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<
            ({
              TodoExecution? execution,
              String? workerName,
              String? workerPhotoUrl,
            })
          >,
          ({String storeId, String todoId})
        > {
  const LatestTodoExecutionFamily._()
    : super(
        retry: null,
        name: r'latestTodoExecutionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LatestTodoExecutionProvider call({
    required String storeId,
    required String todoId,
  }) => LatestTodoExecutionProvider._(
    argument: (storeId: storeId, todoId: todoId),
    from: this,
  );

  @override
  String toString() => r'latestTodoExecutionProvider';
}

@ProviderFor(todoExecutionImageUrl)
const todoExecutionImageUrlProvider = TodoExecutionImageUrlFamily._();

final class TodoExecutionImageUrlProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  const TodoExecutionImageUrlProvider._({
    required TodoExecutionImageUrlFamily super.from,
    required ({String storeId, String executionId, String submissionImageId})
    super.argument,
  }) : super(
         retry: null,
         name: r'todoExecutionImageUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$todoExecutionImageUrlHash();

  @override
  String toString() {
    return r'todoExecutionImageUrlProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument =
        this.argument
            as ({String storeId, String executionId, String submissionImageId});
    return todoExecutionImageUrl(
      ref,
      storeId: argument.storeId,
      executionId: argument.executionId,
      submissionImageId: argument.submissionImageId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TodoExecutionImageUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$todoExecutionImageUrlHash() =>
    r'131515f8bd1ee2c0b56e76857265e53e8bcf9586';

final class TodoExecutionImageUrlFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<String?>,
          ({String storeId, String executionId, String submissionImageId})
        > {
  const TodoExecutionImageUrlFamily._()
    : super(
        retry: null,
        name: r'todoExecutionImageUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TodoExecutionImageUrlProvider call({
    required String storeId,
    required String executionId,
    required String submissionImageId,
  }) => TodoExecutionImageUrlProvider._(
    argument: (
      storeId: storeId,
      executionId: executionId,
      submissionImageId: submissionImageId,
    ),
    from: this,
  );

  @override
  String toString() => r'todoExecutionImageUrlProvider';
}
