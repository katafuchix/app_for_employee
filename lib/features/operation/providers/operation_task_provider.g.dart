// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_task_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 月次タスク (Temporary) のStream

@ProviderFor(operationMonthlyTasks)
const operationMonthlyTasksProvider = OperationMonthlyTasksFamily._();

/// 月次タスク (Temporary) のStream

final class OperationMonthlyTasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TaskTemporary>>,
          List<TaskTemporary>,
          Stream<List<TaskTemporary>>
        >
    with
        $FutureModifier<List<TaskTemporary>>,
        $StreamProvider<List<TaskTemporary>> {
  /// 月次タスク (Temporary) のStream
  const OperationMonthlyTasksProvider._({
    required OperationMonthlyTasksFamily super.from,
    required ({String storeId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'operationMonthlyTasksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$operationMonthlyTasksHash();

  @override
  String toString() {
    return r'operationMonthlyTasksProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<TaskTemporary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TaskTemporary>> create(Ref ref) {
    final argument = this.argument as ({String storeId, DateTime date});
    return operationMonthlyTasks(
      ref,
      storeId: argument.storeId,
      date: argument.date,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OperationMonthlyTasksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$operationMonthlyTasksHash() =>
    r'88511e8d299beac75f49bd91c4b19229cfdc14a3';

/// 月次タスク (Temporary) のStream

final class OperationMonthlyTasksFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<TaskTemporary>>,
          ({String storeId, DateTime date})
        > {
  const OperationMonthlyTasksFamily._()
    : super(
        retry: null,
        name: r'operationMonthlyTasksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 月次タスク (Temporary) のStream

  OperationMonthlyTasksProvider call({
    required String storeId,
    required DateTime date,
  }) => OperationMonthlyTasksProvider._(
    argument: (storeId: storeId, date: date),
    from: this,
  );

  @override
  String toString() => r'operationMonthlyTasksProvider';
}

/// 定期タスク (Schedule) のStream

@ProviderFor(operationRegularTasks)
const operationRegularTasksProvider = OperationRegularTasksFamily._();

/// 定期タスク (Schedule) のStream

final class OperationRegularTasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RegularTaskNode>>,
          List<RegularTaskNode>,
          Stream<List<RegularTaskNode>>
        >
    with
        $FutureModifier<List<RegularTaskNode>>,
        $StreamProvider<List<RegularTaskNode>> {
  /// 定期タスク (Schedule) のStream
  const OperationRegularTasksProvider._({
    required OperationRegularTasksFamily super.from,
    required ({String storeId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'operationRegularTasksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$operationRegularTasksHash();

  @override
  String toString() {
    return r'operationRegularTasksProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<RegularTaskNode>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<RegularTaskNode>> create(Ref ref) {
    final argument = this.argument as ({String storeId, DateTime date});
    return operationRegularTasks(
      ref,
      storeId: argument.storeId,
      date: argument.date,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OperationRegularTasksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$operationRegularTasksHash() =>
    r'25a85b238376023cad46f7730c822ac2f390aa19';

/// 定期タスク (Schedule) のStream

final class OperationRegularTasksFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<RegularTaskNode>>,
          ({String storeId, DateTime date})
        > {
  const OperationRegularTasksFamily._()
    : super(
        retry: null,
        name: r'operationRegularTasksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 定期タスク (Schedule) のStream

  OperationRegularTasksProvider call({
    required String storeId,
    required DateTime date,
  }) => OperationRegularTasksProvider._(
    argument: (storeId: storeId, date: date),
    from: this,
  );

  @override
  String toString() => r'operationRegularTasksProvider';
}
