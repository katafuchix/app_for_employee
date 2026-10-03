// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_attendance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(operationAttendance)
const operationAttendanceProvider = OperationAttendanceFamily._();

final class OperationAttendanceProvider
    extends
        $FunctionalProvider<
          AsyncValue<AttendanceState>,
          AttendanceState,
          FutureOr<AttendanceState>
        >
    with $FutureModifier<AttendanceState>, $FutureProvider<AttendanceState> {
  const OperationAttendanceProvider._({
    required OperationAttendanceFamily super.from,
    required ({String storeId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'operationAttendanceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$operationAttendanceHash();

  @override
  String toString() {
    return r'operationAttendanceProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<AttendanceState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AttendanceState> create(Ref ref) {
    final argument = this.argument as ({String storeId, DateTime date});
    return operationAttendance(
      ref,
      storeId: argument.storeId,
      date: argument.date,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OperationAttendanceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$operationAttendanceHash() =>
    r'7b612b5a8095a9bfcd93dd1bb6400439f319f065';

final class OperationAttendanceFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<AttendanceState>,
          ({String storeId, DateTime date})
        > {
  const OperationAttendanceFamily._()
    : super(
        retry: null,
        name: r'operationAttendanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OperationAttendanceProvider call({
    required String storeId,
    required DateTime date,
  }) => OperationAttendanceProvider._(
    argument: (storeId: storeId, date: date),
    from: this,
  );

  @override
  String toString() => r'operationAttendanceProvider';
}

@ProviderFor(currentStoreWorkerId)
const currentStoreWorkerIdProvider = CurrentStoreWorkerIdProvider._();

final class CurrentStoreWorkerIdProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  const CurrentStoreWorkerIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentStoreWorkerIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentStoreWorkerIdHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return currentStoreWorkerId(ref);
  }
}

String _$currentStoreWorkerIdHash() =>
    r'd2a1b3487534dcfac05d0deeb9d8ca10f654e5fd';

@ProviderFor(isCurrentUserWorking)
const isCurrentUserWorkingProvider = IsCurrentUserWorkingFamily._();

final class IsCurrentUserWorkingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  const IsCurrentUserWorkingProvider._({
    required IsCurrentUserWorkingFamily super.from,
    required ({String storeId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'isCurrentUserWorkingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isCurrentUserWorkingHash();

  @override
  String toString() {
    return r'isCurrentUserWorkingProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as ({String storeId, DateTime date});
    return isCurrentUserWorking(
      ref,
      storeId: argument.storeId,
      date: argument.date,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsCurrentUserWorkingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isCurrentUserWorkingHash() =>
    r'd4ac3987c7eda3983130d582c13931ff4b03de54';

final class IsCurrentUserWorkingFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<bool>,
          ({String storeId, DateTime date})
        > {
  const IsCurrentUserWorkingFamily._()
    : super(
        retry: null,
        name: r'isCurrentUserWorkingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsCurrentUserWorkingProvider call({
    required String storeId,
    required DateTime date,
  }) => IsCurrentUserWorkingProvider._(
    argument: (storeId: storeId, date: date),
    from: this,
  );

  @override
  String toString() => r'isCurrentUserWorkingProvider';
}
