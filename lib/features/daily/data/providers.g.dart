// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dailyCommuteRepository)
final dailyCommuteRepositoryProvider = DailyCommuteRepositoryProvider._();

final class DailyCommuteRepositoryProvider
    extends
        $FunctionalProvider<
          DailyCommuteRepository,
          DailyCommuteRepository,
          DailyCommuteRepository
        >
    with $Provider<DailyCommuteRepository> {
  DailyCommuteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyCommuteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyCommuteRepositoryHash();

  @$internal
  @override
  $ProviderElement<DailyCommuteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DailyCommuteRepository create(Ref ref) {
    return dailyCommuteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyCommuteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyCommuteRepository>(value),
    );
  }
}

String _$dailyCommuteRepositoryHash() =>
    r'eb27688d5d3c995c611228fdbedf8d100a2164f9';

@ProviderFor(trustRepository)
final trustRepositoryProvider = TrustRepositoryProvider._();

final class TrustRepositoryProvider
    extends
        $FunctionalProvider<TrustRepository, TrustRepository, TrustRepository>
    with $Provider<TrustRepository> {
  TrustRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trustRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trustRepositoryHash();

  @$internal
  @override
  $ProviderElement<TrustRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TrustRepository create(Ref ref) {
    return trustRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrustRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrustRepository>(value),
    );
  }
}

String _$trustRepositoryHash() => r'50748e00457ffbef4ee6058a2845802adf4d7b82';

@ProviderFor(phoneDialer)
final phoneDialerProvider = PhoneDialerProvider._();

final class PhoneDialerProvider
    extends $FunctionalProvider<PhoneDialer, PhoneDialer, PhoneDialer>
    with $Provider<PhoneDialer> {
  PhoneDialerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneDialerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneDialerHash();

  @$internal
  @override
  $ProviderElement<PhoneDialer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhoneDialer create(Ref ref) {
    return phoneDialer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhoneDialer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneDialer>(value),
    );
  }
}

String _$phoneDialerHash() => r'a6bfa8c8febb5f00c393ea7b5d37ffcaaacc058a';

@ProviderFor(tripSharer)
final tripSharerProvider = TripSharerProvider._();

final class TripSharerProvider
    extends $FunctionalProvider<TripSharer, TripSharer, TripSharer>
    with $Provider<TripSharer> {
  TripSharerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripSharerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripSharerHash();

  @$internal
  @override
  $ProviderElement<TripSharer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TripSharer create(Ref ref) {
    return tripSharer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripSharer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripSharer>(value),
    );
  }
}

String _$tripSharerHash() => r'7c0d3778dd122d91dec435e2647d60cf82dbdfee';

/// Simulated until maps and the server exist (research R8).

@ProviderFor(locationSource)
final locationSourceProvider = LocationSourceProvider._();

/// Simulated until maps and the server exist (research R8).

final class LocationSourceProvider
    extends $FunctionalProvider<LocationSource, LocationSource, LocationSource>
    with $Provider<LocationSource> {
  /// Simulated until maps and the server exist (research R8).
  LocationSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationSourceHash();

  @$internal
  @override
  $ProviderElement<LocationSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocationSource create(Ref ref) {
    return locationSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationSource>(value),
    );
  }
}

String _$locationSourceHash() => r'08b683df31a03ed43e46012497fb4b115a7768b2';
