// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(commuteRepository)
final commuteRepositoryProvider = CommuteRepositoryProvider._();

final class CommuteRepositoryProvider
    extends
        $FunctionalProvider<
          CommuteRepository,
          CommuteRepository,
          CommuteRepository
        >
    with $Provider<CommuteRepository> {
  CommuteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commuteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commuteRepositoryHash();

  @$internal
  @override
  $ProviderElement<CommuteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CommuteRepository create(Ref ref) {
    return commuteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommuteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommuteRepository>(value),
    );
  }
}

String _$commuteRepositoryHash() => r'b01a59a8efc9e4e90e443f4b677fe8d746061e84';

/// Real rates stay off until the founder sets them (brief §8 open item).

@ProviderFor(tripCostConfig)
final tripCostConfigProvider = TripCostConfigProvider._();

/// Real rates stay off until the founder sets them (brief §8 open item).

final class TripCostConfigProvider
    extends $FunctionalProvider<TripCostConfig, TripCostConfig, TripCostConfig>
    with $Provider<TripCostConfig> {
  /// Real rates stay off until the founder sets them (brief §8 open item).
  TripCostConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripCostConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripCostConfigHash();

  @$internal
  @override
  $ProviderElement<TripCostConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TripCostConfig create(Ref ref) {
    return tripCostConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripCostConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripCostConfig>(value),
    );
  }
}

String _$tripCostConfigHash() => r'b0efe9966e01949eb91bf0ef52bdb1b93c9ca9ea';
