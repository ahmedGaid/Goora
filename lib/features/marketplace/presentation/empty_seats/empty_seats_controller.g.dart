// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'empty_seats_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The free seats on [leg] for the viewing rider (A). Re-read after every
/// booking so a taken seat leaves the list, and when the rider's way of paying
/// changes, since it sets every price line (T104 F6).

@ProviderFor(seatOffers)
final seatOffersProvider = SeatOffersFamily._();

/// The free seats on [leg] for the viewing rider (A). Re-read after every
/// booking so a taken seat leaves the list, and when the rider's way of paying
/// changes, since it sets every price line (T104 F6).

final class SeatOffersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SeatOffer>>,
          List<SeatOffer>,
          FutureOr<List<SeatOffer>>
        >
    with $FutureModifier<List<SeatOffer>>, $FutureProvider<List<SeatOffer>> {
  /// The free seats on [leg] for the viewing rider (A). Re-read after every
  /// booking so a taken seat leaves the list, and when the rider's way of paying
  /// changes, since it sets every price line (T104 F6).
  SeatOffersProvider._({
    required SeatOffersFamily super.from,
    required Leg super.argument,
  }) : super(
         retry: null,
         name: r'seatOffersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$seatOffersHash();

  @override
  String toString() {
    return r'seatOffersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SeatOffer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SeatOffer>> create(Ref ref) {
    final argument = this.argument as Leg;
    return seatOffers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SeatOffersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$seatOffersHash() => r'43432f25375c91db4b7bb4e057d933e9d49abc30';

/// The free seats on [leg] for the viewing rider (A). Re-read after every
/// booking so a taken seat leaves the list, and when the rider's way of paying
/// changes, since it sets every price line (T104 F6).

final class SeatOffersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SeatOffer>>, Leg> {
  SeatOffersFamily._()
    : super(
        retry: null,
        name: r'seatOffersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The free seats on [leg] for the viewing rider (A). Re-read after every
  /// booking so a taken seat leaves the list, and when the rider's way of paying
  /// changes, since it sets every price line (T104 F6).

  SeatOffersProvider call(Leg leg) =>
      SeatOffersProvider._(argument: leg, from: this);

  @override
  String toString() => r'seatOffersProvider';
}

/// The rider's live bookings, oldest first.

@ProviderFor(myBookings)
final myBookingsProvider = MyBookingsProvider._();

/// The rider's live bookings, oldest first.

final class MyBookingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Booking>>,
          List<Booking>,
          FutureOr<List<Booking>>
        >
    with $FutureModifier<List<Booking>>, $FutureProvider<List<Booking>> {
  /// The rider's live bookings, oldest first.
  MyBookingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myBookingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myBookingsHash();

  @$internal
  @override
  $FutureProviderElement<List<Booking>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Booking>> create(Ref ref) {
    return myBookings(ref);
  }
}

String _$myBookingsHash() => r'40acfc008d5a3c75ec99457fbca95f6ea141937a';
