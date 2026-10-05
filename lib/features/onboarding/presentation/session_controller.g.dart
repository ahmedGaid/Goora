// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loaded once in `main()` before the first frame, then overridden.

@ProviderFor(initialSession)
final initialSessionProvider = InitialSessionProvider._();

/// Loaded once in `main()` before the first frame, then overridden.

final class InitialSessionProvider
    extends $FunctionalProvider<Session, Session, Session>
    with $Provider<Session> {
  /// Loaded once in `main()` before the first frame, then overridden.
  InitialSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialSessionHash();

  @$internal
  @override
  $ProviderElement<Session> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Session create(Ref ref) {
    return initialSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Session value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Session>(value),
    );
  }
}

String _$initialSessionHash() => r'd07e6eb7666c8ba5ecfd1dddab3c403fd5f5907d';

@ProviderFor(SessionController)
final sessionControllerProvider = SessionControllerProvider._();

final class SessionControllerProvider
    extends $NotifierProvider<SessionController, Session> {
  SessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionControllerHash();

  @$internal
  @override
  SessionController create() => SessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Session value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Session>(value),
    );
  }
}

String _$sessionControllerHash() => r'0ea3c31f9760159e0aff3734067325f3017a80d8';

abstract class _$SessionController extends $Notifier<Session> {
  Session build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Session, Session>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Session, Session>,
              Session,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
