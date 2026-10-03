// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_master_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(operationMasterData)
const operationMasterDataProvider = OperationMasterDataFamily._();

final class OperationMasterDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<OperationMasterData>,
          OperationMasterData,
          FutureOr<OperationMasterData>
        >
    with
        $FutureModifier<OperationMasterData>,
        $FutureProvider<OperationMasterData> {
  const OperationMasterDataProvider._({
    required OperationMasterDataFamily super.from,
    required ({String storeId, DateTime date}) super.argument,
  }) : super(
         retry: null,
         name: r'operationMasterDataProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$operationMasterDataHash();

  @override
  String toString() {
    return r'operationMasterDataProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<OperationMasterData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OperationMasterData> create(Ref ref) {
    final argument = this.argument as ({String storeId, DateTime date});
    return operationMasterData(
      ref,
      storeId: argument.storeId,
      date: argument.date,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OperationMasterDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$operationMasterDataHash() =>
    r'2a11d20bcc56bfe528f7e5cc2c0ffd135083660e';

final class OperationMasterDataFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<OperationMasterData>,
          ({String storeId, DateTime date})
        > {
  const OperationMasterDataFamily._()
    : super(
        retry: null,
        name: r'operationMasterDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  OperationMasterDataProvider call({
    required String storeId,
    required DateTime date,
  }) => OperationMasterDataProvider._(
    argument: (storeId: storeId, date: date),
    from: this,
  );

  @override
  String toString() => r'operationMasterDataProvider';
}
