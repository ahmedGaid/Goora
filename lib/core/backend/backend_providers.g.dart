// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backend_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fake unless `Backend.init` went live (011 research D2). Tests override it.

@ProviderFor(backendMode)
final backendModeProvider = BackendModeProvider._();

/// Fake unless `Backend.init` went live (011 research D2). Tests override it.

final class BackendModeProvider
    extends $FunctionalProvider<BackendMode, BackendMode, BackendMode>
    with $Provider<BackendMode> {
  /// Fake unless `Backend.init` went live (011 research D2). Tests override it.
  BackendModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backendModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backendModeHash();

  @$internal
  @override
  $ProviderElement<BackendMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackendMode create(Ref ref) {
    return backendMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackendMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackendMode>(value),
    );
  }
}

String _$backendModeHash() => r'9a46a7c0ae84461f220a945dd6ad3663aa8a2a5a';

/// Only read in live mode; tests override it with an in-memory gateway.

@ProviderFor(backendGateway)
final backendGatewayProvider = BackendGatewayProvider._();

/// Only read in live mode; tests override it with an in-memory gateway.

final class BackendGatewayProvider
    extends $FunctionalProvider<BackendGateway, BackendGateway, BackendGateway>
    with $Provider<BackendGateway> {
  /// Only read in live mode; tests override it with an in-memory gateway.
  BackendGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backendGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backendGatewayHash();

  @$internal
  @override
  $ProviderElement<BackendGateway> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackendGateway create(Ref ref) {
    return backendGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackendGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackendGateway>(value),
    );
  }
}

String _$backendGatewayHash() => r'c212f31bb7ac7a411eb1929337be94930f9cdbaa';
