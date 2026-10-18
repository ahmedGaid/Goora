// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_off_section.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The rider's booked one-off seats on Today. A seat booked on the rider's own
/// group ride is the group card's business, not shown twice (R10). Follows
/// [myBookingsProvider], so a booking made over Today shows on it (T104 F17).

@ProviderFor(oneOffToday)
final oneOffTodayProvider = OneOffTodayProvider._();

/// The rider's booked one-off seats on Today. A seat booked on the rider's own
/// group ride is the group card's business, not shown twice (R10). Follows
/// [myBookingsProvider], so a booking made over Today shows on it (T104 F17).

final class OneOffTodayProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OneOffSeat>>,
          List<OneOffSeat>,
          FutureOr<List<OneOffSeat>>
        >
    with $FutureModifier<List<OneOffSeat>>, $FutureProvider<List<OneOffSeat>> {
  /// The rider's booked one-off seats on Today. A seat booked on the rider's own
  /// group ride is the group card's business, not shown twice (R10). Follows
  /// [myBookingsProvider], so a booking made over Today shows on it (T104 F17).
  OneOffTodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oneOffTodayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oneOffTodayHash();

  @$internal
  @override
  $FutureProviderElement<List<OneOffSeat>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OneOffSeat>> create(Ref ref) {
    return oneOffToday(ref);
  }
}

String _$oneOffTodayHash() => r'2301d179130dda577844487d6394134680d24ff8';

/// The driver's offered trips in the coming week, each with its live state.
/// A group's legs are the group card's business; only `of-` trips show here.

@ProviderFor(driverOffers)
final driverOffersProvider = DriverOffersProvider._();

/// The driver's offered trips in the coming week, each with its live state.
/// A group's legs are the group card's business; only `of-` trips show here.

final class DriverOffersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OfferLive>>,
          List<OfferLive>,
          FutureOr<List<OfferLive>>
        >
    with $FutureModifier<List<OfferLive>>, $FutureProvider<List<OfferLive>> {
  /// The driver's offered trips in the coming week, each with its live state.
  /// A group's legs are the group card's business; only `of-` trips show here.
  DriverOffersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driverOffersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driverOffersHash();

  @$internal
  @override
  $FutureProviderElement<List<OfferLive>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OfferLive>> create(Ref ref) {
    return driverOffers(ref);
  }
}

String _$driverOffersHash() => r'86e6b01066c2cb925afe9076f3d066d40c7f62e1';
