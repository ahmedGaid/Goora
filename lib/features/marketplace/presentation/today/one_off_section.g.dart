// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one_off_section.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The rider's booked one-off seats on Today. A seat booked on the rider's own
/// group ride is the group card's business, not shown twice (R10).

@ProviderFor(oneOffToday)
final oneOffTodayProvider = OneOffTodayProvider._();

/// The rider's booked one-off seats on Today. A seat booked on the rider's own
/// group ride is the group card's business, not shown twice (R10).

final class OneOffTodayProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OneOffSeat>>,
          List<OneOffSeat>,
          FutureOr<List<OneOffSeat>>
        >
    with $FutureModifier<List<OneOffSeat>>, $FutureProvider<List<OneOffSeat>> {
  /// The rider's booked one-off seats on Today. A seat booked on the rider's own
  /// group ride is the group card's business, not shown twice (R10).
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

String _$oneOffTodayHash() => r'a09efad2d780d6ca9bffb1ea5547ef490655278a';

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

/// Cash the driver marked on an offered trip (`offer:<id>`), by rider.

@ProviderFor(offerCashMarks)
final offerCashMarksProvider = OfferCashMarksFamily._();

/// Cash the driver marked on an offered trip (`offer:<id>`), by rider.

final class OfferCashMarksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CashMark>>,
          List<CashMark>,
          FutureOr<List<CashMark>>
        >
    with $FutureModifier<List<CashMark>>, $FutureProvider<List<CashMark>> {
  /// Cash the driver marked on an offered trip (`offer:<id>`), by rider.
  OfferCashMarksProvider._({
    required OfferCashMarksFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'offerCashMarksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$offerCashMarksHash();

  @override
  String toString() {
    return r'offerCashMarksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CashMark>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CashMark>> create(Ref ref) {
    final argument = this.argument as String;
    return offerCashMarks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OfferCashMarksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$offerCashMarksHash() => r'b334156199ce573b29456a3e6646cc1799dae6e9';

/// Cash the driver marked on an offered trip (`offer:<id>`), by rider.

final class OfferCashMarksFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CashMark>>, String> {
  OfferCashMarksFamily._()
    : super(
        retry: null,
        name: r'offerCashMarksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Cash the driver marked on an offered trip (`offer:<id>`), by rider.

  OfferCashMarksProvider call(String rideId) =>
      OfferCashMarksProvider._(argument: rideId, from: this);

  @override
  String toString() => r'offerCashMarksProvider';
}
