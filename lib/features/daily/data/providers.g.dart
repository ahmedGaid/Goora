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
