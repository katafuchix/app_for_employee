// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(storeId)
const storeIdProvider = StoreIdProvider._();

final class StoreIdProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  const StoreIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storeIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storeIdHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return storeId(ref);
  }
}

String _$storeIdHash() => r'e6f36a25bff2bfb7a70952d16a073631a61e6d10';

/// Provides the current user's ID.
/// NOTE: Replace this with your actual Auth provider.

@ProviderFor(currentStoreWorkerId)
const currentStoreWorkerIdProvider = CurrentStoreWorkerIdProvider._();

/// Provides the current user's ID.
/// NOTE: Replace this with your actual Auth provider.

final class CurrentStoreWorkerIdProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Provides the current user's ID.
  /// NOTE: Replace this with your actual Auth provider.
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
    r'2b425ab04bf7ce868cdd3d29256b81f672a4d526';

@ProviderFor(fetchUserProfile)
const fetchUserProfileProvider = FetchUserProfileFamily._();

final class FetchUserProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile>,
          UserProfile,
          FutureOr<UserProfile>
        >
    with $FutureModifier<UserProfile>, $FutureProvider<UserProfile> {
  const FetchUserProfileProvider._({
    required FetchUserProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchUserProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchUserProfileHash();

  @override
  String toString() {
    return r'fetchUserProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfile> create(Ref ref) {
    final argument = this.argument as String;
    return fetchUserProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchUserProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchUserProfileHash() => r'49ee2d0b5b343b9e708ec293e943633ed3e88e37';

final class FetchUserProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UserProfile>, String> {
  const FetchUserProfileFamily._()
    : super(
        retry: null,
        name: r'fetchUserProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchUserProfileProvider call(String workerId) =>
      FetchUserProfileProvider._(argument: workerId, from: this);

  @override
  String toString() => r'fetchUserProfileProvider';
}

/// 4. 受信箱リスナー (Inbox Listener)

@ProviderFor(inboxMessages)
const inboxMessagesProvider = InboxMessagesProvider._();

/// 4. 受信箱リスナー (Inbox Listener)

final class InboxMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Message>>,
          List<Message>,
          Stream<List<Message>>
        >
    with $FutureModifier<List<Message>>, $StreamProvider<List<Message>> {
  /// 4. 受信箱リスナー (Inbox Listener)
  const InboxMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxMessagesHash();

  @$internal
  @override
  $StreamProviderElement<List<Message>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Message>> create(Ref ref) {
    return inboxMessages(ref);
  }
}

String _$inboxMessagesHash() => r'f2169d73e7c89b4e14ff92690f922f73055c3791';

@ProviderFor(allMessages)
const allMessagesProvider = AllMessagesProvider._();

final class AllMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Message>>,
          List<Message>,
          FutureOr<List<Message>>
        >
    with $FutureModifier<List<Message>>, $FutureProvider<List<Message>> {
  const AllMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allMessagesHash();

  @$internal
  @override
  $FutureProviderElement<List<Message>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Message>> create(Ref ref) {
    return allMessages(ref);
  }
}

String _$allMessagesHash() => r'c6577cd83fea19a29a6c2f29a70541e02bfa99df';

/// 1分ごとに現在時刻を更新して通知するプロバイダー
/// UI側でこれを watch すると、1分ごとに再描画が走ります。

@ProviderFor(currentMinute)
const currentMinuteProvider = CurrentMinuteProvider._();

/// 1分ごとに現在時刻を更新して通知するプロバイダー
/// UI側でこれを watch すると、1分ごとに再描画が走ります。

final class CurrentMinuteProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  /// 1分ごとに現在時刻を更新して通知するプロバイダー
  /// UI側でこれを watch すると、1分ごとに再描画が走ります。
  const CurrentMinuteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMinuteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMinuteHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return currentMinute(ref);
  }
}

String _$currentMinuteHash() => r'686577dd6e1e1cae9fea975f246ef80cca3d785d';

/// 5. 送信済みメッセージ取得 (Sent Messages) - 追加部分
/// Retrieves the list of messages sent by the current user.

@ProviderFor(sentMessages)
const sentMessagesProvider = SentMessagesProvider._();

/// 5. 送信済みメッセージ取得 (Sent Messages) - 追加部分
/// Retrieves the list of messages sent by the current user.

final class SentMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Message>>,
          List<Message>,
          FutureOr<List<Message>>
        >
    with $FutureModifier<List<Message>>, $FutureProvider<List<Message>> {
  /// 5. 送信済みメッセージ取得 (Sent Messages) - 追加部分
  /// Retrieves the list of messages sent by the current user.
  const SentMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sentMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sentMessagesHash();

  @$internal
  @override
  $FutureProviderElement<List<Message>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Message>> create(Ref ref) {
    return sentMessages(ref);
  }
}

String _$sentMessagesHash() => r'4c9eaa1f49ccc0f3cb407fb06d2868360dc8cc90';

@ProviderFor(senderActions)
const senderActionsProvider = SenderActionsProvider._();

final class SenderActionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MessageAction>>,
          List<MessageAction>,
          Stream<List<MessageAction>>
        >
    with
        $FutureModifier<List<MessageAction>>,
        $StreamProvider<List<MessageAction>> {
  const SenderActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'senderActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$senderActionsHash();

  @$internal
  @override
  $StreamProviderElement<List<MessageAction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MessageAction>> create(Ref ref) {
    return senderActions(ref);
  }
}

String _$senderActionsHash() => r'6baa647f784378ac6cb830c5976f8a388fd48a15';

/// メッセージ詳細モーダル用 アクションリスナー

@ProviderFor(messageActionsFamily)
const messageActionsFamilyProvider = MessageActionsFamilyFamily._();

/// メッセージ詳細モーダル用 アクションリスナー

final class MessageActionsFamilyProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MessageAction>>,
          List<MessageAction>,
          Stream<List<MessageAction>>
        >
    with
        $FutureModifier<List<MessageAction>>,
        $StreamProvider<List<MessageAction>> {
  /// メッセージ詳細モーダル用 アクションリスナー
  const MessageActionsFamilyProvider._({
    required MessageActionsFamilyFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messageActionsFamilyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageActionsFamilyHash();

  @override
  String toString() {
    return r'messageActionsFamilyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MessageAction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MessageAction>> create(Ref ref) {
    final argument = this.argument as String;
    return messageActionsFamily(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageActionsFamilyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageActionsFamilyHash() =>
    r'e17f39a33a820a53abab9803b5e5a9adb62d7e9c';

/// メッセージ詳細モーダル用 アクションリスナー

final class MessageActionsFamilyFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MessageAction>>, String> {
  const MessageActionsFamilyFamily._()
    : super(
        retry: null,
        name: r'messageActionsFamilyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// メッセージ詳細モーダル用 アクションリスナー

  MessageActionsFamilyProvider call(String messageId) =>
      MessageActionsFamilyProvider._(argument: messageId, from: this);

  @override
  String toString() => r'messageActionsFamilyProvider';
}

/// 単一メッセージの監視

@ProviderFor(messageDetailFamily)
const messageDetailFamilyProvider = MessageDetailFamilyFamily._();

/// 単一メッセージの監視

final class MessageDetailFamilyProvider
    extends
        $FunctionalProvider<AsyncValue<Message?>, Message?, Stream<Message?>>
    with $FutureModifier<Message?>, $StreamProvider<Message?> {
  /// 単一メッセージの監視
  const MessageDetailFamilyProvider._({
    required MessageDetailFamilyFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messageDetailFamilyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageDetailFamilyHash();

  @override
  String toString() {
    return r'messageDetailFamilyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Message?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Message?> create(Ref ref) {
    final argument = this.argument as String;
    return messageDetailFamily(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageDetailFamilyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageDetailFamilyHash() =>
    r'31de8c237d5ff098bd0c76aee813c333de9530f4';

/// 単一メッセージの監視

final class MessageDetailFamilyFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Message?>, String> {
  const MessageDetailFamilyFamily._()
    : super(
        retry: null,
        name: r'messageDetailFamilyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 単一メッセージの監視

  MessageDetailFamilyProvider call(String messageId) =>
      MessageDetailFamilyProvider._(argument: messageId, from: this);

  @override
  String toString() => r'messageDetailFamilyProvider';
}

@ProviderFor(storeWorkers)
const storeWorkersProvider = StoreWorkersProvider._();

final class StoreWorkersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, String>>>,
          List<Map<String, String>>,
          FutureOr<List<Map<String, String>>>
        >
    with
        $FutureModifier<List<Map<String, String>>>,
        $FutureProvider<List<Map<String, String>>> {
  const StoreWorkersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storeWorkersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storeWorkersHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, String>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, String>>> create(Ref ref) {
    return storeWorkers(ref);
  }
}

String _$storeWorkersHash() => r'87d61d3bae0e08f76b14b453029c1b0be5df369a';

@ProviderFor(selectableStoreWorkers)
const selectableStoreWorkersProvider = SelectableStoreWorkersProvider._();

final class SelectableStoreWorkersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, String>>>,
          List<Map<String, String>>,
          FutureOr<List<Map<String, String>>>
        >
    with
        $FutureModifier<List<Map<String, String>>>,
        $FutureProvider<List<Map<String, String>>> {
  const SelectableStoreWorkersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectableStoreWorkersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectableStoreWorkersHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, String>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, String>>> create(Ref ref) {
    return selectableStoreWorkers(ref);
  }
}

String _$selectableStoreWorkersHash() =>
    r'dd4e28daa34c9d1713730c766d6f1fc6baf090d6';

/// シフト確認用

@ProviderFor(workerShiftFamily)
const workerShiftFamilyProvider = WorkerShiftFamilyFamily._();

/// シフト確認用

final class WorkerShiftFamilyProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  /// シフト確認用
  const WorkerShiftFamilyProvider._({
    required WorkerShiftFamilyFamily super.from,
    required ({String workerId, DateTime targetDate}) super.argument,
  }) : super(
         retry: null,
         name: r'workerShiftFamilyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workerShiftFamilyHash();

  @override
  String toString() {
    return r'workerShiftFamilyProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as ({String workerId, DateTime targetDate});
    return workerShiftFamily(
      ref,
      workerId: argument.workerId,
      targetDate: argument.targetDate,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkerShiftFamilyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workerShiftFamilyHash() => r'b066630a3b10d2e373a0de0b550910910c379455';

/// シフト確認用

final class WorkerShiftFamilyFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Map<String, dynamic>>>,
          ({String workerId, DateTime targetDate})
        > {
  const WorkerShiftFamilyFamily._()
    : super(
        retry: null,
        name: r'workerShiftFamilyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// シフト確認用

  WorkerShiftFamilyProvider call({
    required String workerId,
    required DateTime targetDate,
  }) => WorkerShiftFamilyProvider._(
    argument: (workerId: workerId, targetDate: targetDate),
    from: this,
  );

  @override
  String toString() => r'workerShiftFamilyProvider';
}

/// Calculate Badge Count for Inbox

@ProviderFor(inboxBadgeCount)
const inboxBadgeCountProvider = InboxBadgeCountProvider._();

/// Calculate Badge Count for Inbox

final class InboxBadgeCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Calculate Badge Count for Inbox
  const InboxBadgeCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxBadgeCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxBadgeCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return inboxBadgeCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$inboxBadgeCountHash() => r'4d4a478976e76b3ef753349b806d563614a98ac3';

@ProviderFor(totalBadgeCount)
const totalBadgeCountProvider = TotalBadgeCountProvider._();

final class TotalBadgeCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  const TotalBadgeCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalBadgeCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalBadgeCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return totalBadgeCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$totalBadgeCountHash() => r'7e3ff4d2ff6ce176c12a5a98b9856d6aef8c65d2';

@ProviderFor(MessageController)
const messageControllerProvider = MessageControllerProvider._();

final class MessageControllerProvider
    extends $AsyncNotifierProvider<MessageController, void> {
  const MessageControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageControllerHash();

  @$internal
  @override
  MessageController create() => MessageController();
}

String _$messageControllerHash() => r'8f9892b339b7348aa381116761dfc72c05741af3';

abstract class _$MessageController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}

@ProviderFor(inboxHasLateMessage)
const inboxHasLateMessageProvider = InboxHasLateMessageProvider._();

final class InboxHasLateMessageProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  const InboxHasLateMessageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxHasLateMessageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxHasLateMessageHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return inboxHasLateMessage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$inboxHasLateMessageHash() =>
    r'4d4f90364c65e84f6bd596cc8e74879b48012cbb';
