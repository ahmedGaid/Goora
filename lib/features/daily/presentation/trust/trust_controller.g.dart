// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trust_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TrustController)
final trustControllerProvider = TrustControllerProvider._();

final class TrustControllerProvider
    extends $AsyncNotifierProvider<TrustController, TrustView> {
  TrustControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trustControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trustControllerHash();

  @$internal
  @override
  TrustController create() => TrustController();
}

String _$trustControllerHash() => r'4ad36e3025fb65493dc62e06f0addef89fe4820c';

abstract class _$TrustController extends $AsyncNotifier<TrustView> {
  FutureOr<TrustView> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TrustView>, TrustView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TrustView>, TrustView>,
              AsyncValue<TrustView>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
