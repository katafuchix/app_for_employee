// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_streams.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(operationStatusStream)
const operationStatusStreamProvider = OperationStatusStreamFamily._();

final class OperationStatusStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailySetup?>,
          DailySetup?,
          Stream<DailySetup?>
        >
    with $FutureModifier<DailySetup?>, $StreamProvider<DailySetup?> {
  const OperationStatusStreamProvider._({
    required OperationStatusStreamFamily super.from,
    required ({String storeId, String dailySetupId}) super.argument,
  }) : super(
         retry: null,
         name: r'operationStatusStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$operationStatusStreamHash();

  @override
  String toString() {
    return r'operationStatusStreamProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<DailySetup?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DailySetup?> create(Ref ref) {
    final argument = this.argument as ({String storeId, String dailySetupId});
    return operationStatusStream(
      ref,
      storeId: argument.storeId,
      dailySetupId: argument.dailySetupId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OperationStatusStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$operationStatusStreamHash() =>
    r'800b3dc2cacbb783944ace6d2b5acea698311ea8';

final class OperationStatusStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<DailySetup?>,
          ({String storeId, String dailySetupId})
        > {
  const OperationStatusStreamFamily._()
    : super(
        retry: null,
        name: r'operationStatusStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OperationStatusStreamProvider call({
    required String storeId,
    required String dailySetupId,
  }) => OperationStatusStreamProvider._(
    argument: (storeId: storeId, dailySetupId: dailySetupId),
    from: this,
  );

  @override
  String toString() => r'operationStatusStreamProvider';
}

@ProviderFor(todoExecutionsStream)
const todoExecutionsStreamProvider = TodoExecutionsStreamFamily._();

final class TodoExecutionsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TodoExecution>>,
          List<TodoExecution>,
          Stream<List<TodoExecution>>
        >
    with
        $FutureModifier<List<TodoExecution>>,
        $StreamProvider<List<TodoExecution>> {
  const TodoExecutionsStreamProvider._({
    required TodoExecutionsStreamFamily super.from,
    required ({String storeId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'todoExecutionsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$todoExecutionsStreamHash();

  @override
  String toString() {
    return r'todoExecutionsStreamProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<TodoExecution>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TodoExecution>> create(Ref ref) {
    final argument = this.argument as ({String storeId, DateTime date});
    return todoExecutionsStream(
      ref,
      storeId: argument.storeId,
      date: argument.date,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TodoExecutionsStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$todoExecutionsStreamHash() =>
    r'9ee5dba82207fa53794fd33c0c877b81ce63961b';

final class TodoExecutionsStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<TodoExecution>>,
          ({String storeId, DateTime date})
        > {
  const TodoExecutionsStreamFamily._()
    : super(
        retry: null,
        name: r'todoExecutionsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TodoExecutionsStreamProvider call({
    required String storeId,
    required DateTime date,
  }) => TodoExecutionsStreamProvider._(
    argument: (storeId: storeId, date: date),
    from: this,
  );

  @override
  String toString() => r'todoExecutionsStreamProvider';
}

@ProviderFor(workerClocksStream)
const workerClocksStreamProvider = WorkerClocksStreamFamily._();

final class WorkerClocksStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkerClock>>,
          List<WorkerClock>,
          Stream<List<WorkerClock>>
        >
    with
        $FutureModifier<List<WorkerClock>>,
        $StreamProvider<List<WorkerClock>> {
  const WorkerClocksStreamProvider._({
    required WorkerClocksStreamFamily super.from,
    required ({String storeId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'workerClocksStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workerClocksStreamHash();

  @override
  String toString() {
    return r'workerClocksStreamProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<WorkerClock>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WorkerClock>> create(Ref ref) {
    final argument = this.argument as ({String storeId, DateTime date});
    return workerClocksStream(
      ref,
      storeId: argument.storeId,
      date: argument.date,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkerClocksStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workerClocksStreamHash() =>
    r'b5ace74336f58612bd6e52ae60395d0711f1ec21';

final class WorkerClocksStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<WorkerClock>>,
          ({String storeId, DateTime date})
        > {
  const WorkerClocksStreamFamily._()
    : super(
        retry: null,
        name: r'workerClocksStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkerClocksStreamProvider call({
    required String storeId,
    required DateTime date,
  }) => WorkerClocksStreamProvider._(
    argument: (storeId: storeId, date: date),
    from: this,
  );

  @override
  String toString() => r'workerClocksStreamProvider';
}

@ProviderFor(taskExecutionsStream)
const taskExecutionsStreamProvider = TaskExecutionsStreamFamily._();

final class TaskExecutionsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TaskExecution>>,
          List<TaskExecution>,
          Stream<List<TaskExecution>>
        >
    with
        $FutureModifier<List<TaskExecution>>,
        $StreamProvider<List<TaskExecution>> {
  const TaskExecutionsStreamProvider._({
    required TaskExecutionsStreamFamily super.from,
    required ({String storeId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'taskExecutionsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskExecutionsStreamHash();

  @override
  String toString() {
    return r'taskExecutionsStreamProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<TaskExecution>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TaskExecution>> create(Ref ref) {
    final argument = this.argument as ({String storeId, DateTime date});
    return taskExecutionsStream(
      ref,
      storeId: argument.storeId,
      date: argument.date,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TaskExecutionsStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskExecutionsStreamHash() =>
    r'0d41b39cccd77ed00b6eba2343ef3a6611e012a2';

final class TaskExecutionsStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<TaskExecution>>,
          ({String storeId, DateTime date})
        > {
  const TaskExecutionsStreamFamily._()
    : super(
        retry: null,
        name: r'taskExecutionsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TaskExecutionsStreamProvider call({
    required String storeId,
    required DateTime date,
  }) => TaskExecutionsStreamProvider._(
    argument: (storeId: storeId, date: date),
    from: this,
  );

  @override
  String toString() => r'taskExecutionsStreamProvider';
}

@ProviderFor(dailySalesStream)
const dailySalesStreamProvider = DailySalesStreamFamily._();

final class DailySalesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DailySales>>,
          List<DailySales>,
          Stream<List<DailySales>>
        >
    with $FutureModifier<List<DailySales>>, $StreamProvider<List<DailySales>> {
  const DailySalesStreamProvider._({
    required DailySalesStreamFamily super.from,
    required ({String storeId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'dailySalesStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailySalesStreamHash();

  @override
  String toString() {
    return r'dailySalesStreamProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<DailySales>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DailySales>> create(Ref ref) {
    final argument = this.argument as ({String storeId, DateTime date});
    return dailySalesStream(
      ref,
      storeId: argument.storeId,
      date: argument.date,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DailySalesStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailySalesStreamHash() => r'2845bd1e717d2dc853638215c469b4af088eb62e';

final class DailySalesStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<DailySales>>,
          ({String storeId, DateTime date})
        > {
  const DailySalesStreamFamily._()
    : super(
        retry: null,
        name: r'dailySalesStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DailySalesStreamProvider call({
    required String storeId,
    required DateTime date,
  }) => DailySalesStreamProvider._(
    argument: (storeId: storeId, date: date),
    from: this,
  );

  @override
  String toString() => r'dailySalesStreamProvider';
}

@ProviderFor(minuteTicker)
const minuteTickerProvider = MinuteTickerProvider._();

final class MinuteTickerProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  const MinuteTickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'minuteTickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$minuteTickerHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return minuteTicker(ref);
  }
}

String _$minuteTickerHash() => r'21f5bf1f9769c951e7dcbe97a8e0668cf8d780bf';
