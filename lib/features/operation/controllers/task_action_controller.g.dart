// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_action_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TaskImageState)
const taskImageStateProvider = TaskImageStateProvider._();

final class TaskImageStateProvider
    extends $NotifierProvider<TaskImageState, File?> {
  const TaskImageStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskImageStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskImageStateHash();

  @$internal
  @override
  TaskImageState create() => TaskImageState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(File? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<File?>(value),
    );
  }
}

String _$taskImageStateHash() => r'e69d22c195eb40b602dd89e92a980f185484951b';

abstract class _$TaskImageState extends $Notifier<File?> {
  File? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<File?, File?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<File?, File?>,
              File?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(taskActionController)
const taskActionControllerProvider = TaskActionControllerProvider._();

final class TaskActionControllerProvider
    extends
        $FunctionalProvider<
          TaskActionController,
          TaskActionController,
          TaskActionController
        >
    with $Provider<TaskActionController> {
  const TaskActionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskActionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskActionControllerHash();

  @$internal
  @override
  $ProviderElement<TaskActionController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TaskActionController create(Ref ref) {
    return taskActionController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskActionController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskActionController>(value),
    );
  }
}

String _$taskActionControllerHash() =>
    r'cfd1267343c8a03853524bbe42b83b435726bf4e';
