// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_statistics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(operationStatistics)
const operationStatisticsProvider = OperationStatisticsFamily._();

final class OperationStatisticsProvider
    extends
        $FunctionalProvider<
          AsyncValue<StatisticsState>,
          StatisticsState,
          FutureOr<StatisticsState>
        >
    with $FutureModifier<StatisticsState>, $FutureProvider<StatisticsState> {
  const OperationStatisticsProvider._({
    required OperationStatisticsFamily super.from,
    required ({String storeId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'operationStatisticsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$operationStatisticsHash();

  @override
  String toString() {
    return r'operationStatisticsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<StatisticsState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StatisticsState> create(Ref ref) {
    final argument = this.argument as ({String storeId, DateTime date});
    return operationStatistics(
      ref,
      storeId: argument.storeId,
      date: argument.date,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OperationStatisticsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$operationStatisticsHash() =>
    r'1cc5d9c2b29f89678c9ce3ff13b940065debf0d6';

final class OperationStatisticsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<StatisticsState>,
          ({String storeId, DateTime date})
        > {
  const OperationStatisticsFamily._()
    : super(
        retry: null,
        name: r'operationStatisticsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OperationStatisticsProvider call({
    required String storeId,
    required DateTime date,
  }) => OperationStatisticsProvider._(
    argument: (storeId: storeId, date: date),
    from: this,
  );

  @override
  String toString() => r'operationStatisticsProvider';
}
