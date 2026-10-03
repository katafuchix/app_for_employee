// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_action_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TodoImageDraft)
const todoImageDraftProvider = TodoImageDraftProvider._();

final class TodoImageDraftProvider
    extends $NotifierProvider<TodoImageDraft, TodoImageDraftMap> {
  const TodoImageDraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todoImageDraftProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todoImageDraftHash();

  @$internal
  @override
  TodoImageDraft create() => TodoImageDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodoImageDraftMap value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodoImageDraftMap>(value),
    );
  }
}

String _$todoImageDraftHash() => r'd6810f1041c681f8f8adb8725bab7a2dee984773';

abstract class _$TodoImageDraft extends $Notifier<TodoImageDraftMap> {
  TodoImageDraftMap build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<TodoImageDraftMap, TodoImageDraftMap>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TodoImageDraftMap, TodoImageDraftMap>,
              TodoImageDraftMap,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(todoActionController)
const todoActionControllerProvider = TodoActionControllerProvider._();

final class TodoActionControllerProvider
    extends
        $FunctionalProvider<
          TodoActionController,
          TodoActionController,
          TodoActionController
        >
    with $Provider<TodoActionController> {
  const TodoActionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todoActionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todoActionControllerHash();

  @$internal
  @override
  $ProviderElement<TodoActionController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TodoActionController create(Ref ref) {
    return todoActionController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodoActionController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodoActionController>(value),
    );
  }
}

String _$todoActionControllerHash() =>
    r'd3d62f3e16a6e945b6131d0574b29dacef1007dd';
