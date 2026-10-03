// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(manualRepository)
const manualRepositoryProvider = ManualRepositoryProvider._();

final class ManualRepositoryProvider
    extends
        $FunctionalProvider<
          ManualRepository,
          ManualRepository,
          ManualRepository
        >
    with $Provider<ManualRepository> {
  const ManualRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualRepositoryHash();

  @$internal
  @override
  $ProviderElement<ManualRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ManualRepository create(Ref ref) {
    return manualRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ManualRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ManualRepository>(value),
    );
  }
}

String _$manualRepositoryHash() => r'80dc77b16d13179e3efb3224a32d0f61676d393d';

@ProviderFor(manualStoreId)
const manualStoreIdProvider = ManualStoreIdProvider._();

final class ManualStoreIdProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  const ManualStoreIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualStoreIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualStoreIdHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return manualStoreId(ref);
  }
}

String _$manualStoreIdHash() => r'889a8a7f6af33e8ab1f463c80b6fba7588dc9a73';

@ProviderFor(manualList)
const manualListProvider = ManualListFamily._();

final class ManualListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Manual>>,
          List<Manual>,
          FutureOr<List<Manual>>
        >
    with $FutureModifier<List<Manual>>, $FutureProvider<List<Manual>> {
  const ManualListProvider._({
    required ManualListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'manualListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$manualListHash();

  @override
  String toString() {
    return r'manualListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Manual>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Manual>> create(Ref ref) {
    final argument = this.argument as String;
    return manualList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ManualListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$manualListHash() => r'796a2aff1eafe18729386b6d2233781614919c29';

final class ManualListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Manual>>, String> {
  const ManualListFamily._()
    : super(
        retry: null,
        name: r'manualListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ManualListProvider call(String storeId) =>
      ManualListProvider._(argument: storeId, from: this);

  @override
  String toString() => r'manualListProvider';
}

@ProviderFor(manualCategoryRawList)
const manualCategoryRawListProvider = ManualCategoryRawListFamily._();

final class ManualCategoryRawListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ManualCategory>>,
          List<ManualCategory>,
          FutureOr<List<ManualCategory>>
        >
    with
        $FutureModifier<List<ManualCategory>>,
        $FutureProvider<List<ManualCategory>> {
  const ManualCategoryRawListProvider._({
    required ManualCategoryRawListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'manualCategoryRawListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$manualCategoryRawListHash();

  @override
  String toString() {
    return r'manualCategoryRawListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ManualCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ManualCategory>> create(Ref ref) {
    final argument = this.argument as String;
    return manualCategoryRawList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ManualCategoryRawListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$manualCategoryRawListHash() =>
    r'c7096039f6ccad684a14c505205a5dab9f53bfe2';

final class ManualCategoryRawListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ManualCategory>>, String> {
  const ManualCategoryRawListFamily._()
    : super(
        retry: null,
        name: r'manualCategoryRawListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ManualCategoryRawListProvider call(String storeId) =>
      ManualCategoryRawListProvider._(argument: storeId, from: this);

  @override
  String toString() => r'manualCategoryRawListProvider';
}

@ProviderFor(manualCategoryList)
const manualCategoryListProvider = ManualCategoryListFamily._();

final class ManualCategoryListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CategoryWithContent>>,
          List<CategoryWithContent>,
          FutureOr<List<CategoryWithContent>>
        >
    with
        $FutureModifier<List<CategoryWithContent>>,
        $FutureProvider<List<CategoryWithContent>> {
  const ManualCategoryListProvider._({
    required ManualCategoryListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'manualCategoryListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$manualCategoryListHash();

  @override
  String toString() {
    return r'manualCategoryListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CategoryWithContent>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CategoryWithContent>> create(Ref ref) {
    final argument = this.argument as String;
    return manualCategoryList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ManualCategoryListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$manualCategoryListHash() =>
    r'0ea35b738276c4e2e0b3628e56b05bbf287d7125';

final class ManualCategoryListFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<CategoryWithContent>>, String> {
  const ManualCategoryListFamily._()
    : super(
        retry: null,
        name: r'manualCategoryListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ManualCategoryListProvider call(String storeId) =>
      ManualCategoryListProvider._(argument: storeId, from: this);

  @override
  String toString() => r'manualCategoryListProvider';
}

@ProviderFor(manualImageUrl)
const manualImageUrlProvider = ManualImageUrlFamily._();

final class ManualImageUrlProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  const ManualImageUrlProvider._({
    required ManualImageUrlFamily super.from,
    required ({String storeId, String manualId, String imageId}) super.argument,
  }) : super(
         retry: null,
         name: r'manualImageUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$manualImageUrlHash();

  @override
  String toString() {
    return r'manualImageUrlProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument =
        this.argument as ({String storeId, String manualId, String imageId});
    return manualImageUrl(
      ref,
      storeId: argument.storeId,
      manualId: argument.manualId,
      imageId: argument.imageId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ManualImageUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$manualImageUrlHash() => r'dfcd5d6d19ec45653ea5d12ea0f0bec224ed4f76';

final class ManualImageUrlFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<String>,
          ({String storeId, String manualId, String imageId})
        > {
  const ManualImageUrlFamily._()
    : super(
        retry: null,
        name: r'manualImageUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ManualImageUrlProvider call({
    required String storeId,
    required String manualId,
    required String imageId,
  }) => ManualImageUrlProvider._(
    argument: (storeId: storeId, manualId: manualId, imageId: imageId),
    from: this,
  );

  @override
  String toString() => r'manualImageUrlProvider';
}
