// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commute_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The commute profile being edited on the setup screen.

@ProviderFor(CommuteController)
final commuteControllerProvider = CommuteControllerProvider._();

/// The commute profile being edited on the setup screen.
final class CommuteControllerProvider
    extends $AsyncNotifierProvider<CommuteController, CommuteProfile> {
  /// The commute profile being edited on the setup screen.
  CommuteControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commuteControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commuteControllerHash();

  @$internal
  @override
  CommuteController create() => CommuteController();
}

String _$commuteControllerHash() => r'4f02e33c8b316638cb3b418693f1e51c4400939c';

/// The commute profile being edited on the setup screen.

abstract class _$CommuteController extends $AsyncNotifier<CommuteProfile> {
  FutureOr<CommuteProfile> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CommuteProfile>, CommuteProfile>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CommuteProfile>, CommuteProfile>,
              AsyncValue<CommuteProfile>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(LastMatch)
final lastMatchProvider = LastMatchProvider._();

final class LastMatchProvider
    extends $NotifierProvider<LastMatch, MatchOutcome?> {
  LastMatchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastMatchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastMatchHash();

  @$internal
  @override
  LastMatch create() => LastMatch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatchOutcome? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatchOutcome?>(value),
    );
  }
}

String _$lastMatchHash() => r'f34604f2a6dac8bb49372825e3b106a53fd8b478';

abstract class _$LastMatch extends $Notifier<MatchOutcome?> {
  MatchOutcome? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MatchOutcome?, MatchOutcome?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MatchOutcome?, MatchOutcome?>,
              MatchOutcome?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
