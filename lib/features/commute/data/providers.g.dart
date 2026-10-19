// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every commute group the fakes know: the corridor seed plus groups the
/// marketplace created (005 research R10). The commute and daily
/// repositories watch it, so invalidating it rebuilds both.

@ProviderFor(groupCatalog)
final groupCatalogProvider = GroupCatalogProvider._();

/// Every commute group the fakes know: the corridor seed plus groups the
/// marketplace created (005 research R10). The commute and daily
/// repositories watch it, so invalidating it rebuilds both.

final class GroupCatalogProvider
    extends $FunctionalProvider<GroupCatalog, GroupCatalog, GroupCatalog>
    with $Provider<GroupCatalog> {
  /// Every commute group the fakes know: the corridor seed plus groups the
  /// marketplace created (005 research R10). The commute and daily
  /// repositories watch it, so invalidating it rebuilds both.
  GroupCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupCatalogHash();

  @$internal
  @override
  $ProviderElement<GroupCatalog> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GroupCatalog create(Ref ref) {
    return groupCatalog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupCatalog value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupCatalog>(value),
    );
  }
}

String _$groupCatalogHash() => r'6a40882c54caf200c19c1db8d6fddbde36b565f0';

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

String _$commuteRepositoryHash() => r'76db8e40eb79a85171e99bc341a94d32b7f025f2';

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

/// The corridor the app shows (006 research R4): Cairo ↔ Ismailia unless a
/// demo setting or a test switches it. "Reset demo data" clears the choice.

@ProviderFor(ActiveCorridor)
final activeCorridorProvider = ActiveCorridorProvider._();

/// The corridor the app shows (006 research R4): Cairo ↔ Ismailia unless a
/// demo setting or a test switches it. "Reset demo data" clears the choice.
final class ActiveCorridorProvider
    extends $NotifierProvider<ActiveCorridor, Corridor> {
  /// The corridor the app shows (006 research R4): Cairo ↔ Ismailia unless a
  /// demo setting or a test switches it. "Reset demo data" clears the choice.
  ActiveCorridorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeCorridorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeCorridorHash();

  @$internal
  @override
  ActiveCorridor create() => ActiveCorridor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Corridor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Corridor>(value),
    );
  }
}

String _$activeCorridorHash() => r'69bbd66e5c3dedf60dbc7af076a4c0fa2a72e3f3';

/// The corridor the app shows (006 research R4): Cairo ↔ Ismailia unless a
/// demo setting or a test switches it. "Reset demo data" clears the choice.

abstract class _$ActiveCorridor extends $Notifier<Corridor> {
  Corridor build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Corridor, Corridor>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Corridor, Corridor>,
              Corridor,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
