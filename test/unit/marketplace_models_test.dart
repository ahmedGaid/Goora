import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/marketplace/domain/anonymous_rider.dart';
import 'package:goora/features/marketplace/domain/booking.dart';
import 'package:goora/features/marketplace/domain/offered_trip.dart';
import 'package:goora/features/marketplace/domain/trip_request.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/seat_price.dart';

/// Through a real JSON string, as `market.*` stores it.
Map<String, Object?> _json(Map<String, Object?> j) => (jsonDecode(jsonEncode(j)) as Map).cast<String, Object?>();

const _pickup = Stop(id: 's1', name: StopName.mainGate, point: GeoPoint(30.0131, 30.9719), time: Clock.hm(7, 30));
const _rider = AnonymousRider(isWoman: true, rating: 4.8);

/// Thursday; its cut-off is Wednesday 2026-10-14 at 21:00.
final _date = CalendarDate(2026, 10, 15);
const _wallet44 = SeatPrice(contribution: 40, fee: 4, cash: null, mode: PricingMode.wallet);

WallTime _wed(int h, int m) => WallTime(CalendarDate(2026, 10, 14), Clock.hm(h, m));

Booking _booking({required WallTime bookedAt, bool isSubscriber = false, BookingStatus status = BookingStatus.booked}) =>
    Booking(
      id: 'bk-1',
      riderId: 'nadia',
      riderName: 'Nadia',
      rider: _rider,
      source: const BookingSource.offer('of-1'),
      date: _date,
      leg: Leg.going,
      rideId: Booking.offerRideId('of-1'),
      price: _wallet44,
      paidBy: PaidBy.wallet,
      paid: 44,
      bookedAt: bookedAt,
      isSubscriber: isSubscriber,
      status: status,
    );

void main() {
  group('Marketplace models JSON (005 T034)', () {
    test('OfferedTrip round-trips', () {
      final trip = OfferedTrip(
        id: 'of-1',
        driverId: 'me',
        leg: Leg.going,
        from: Area.sheikhZayed,
        to: Area.smartVillage,
        date: _date,
        departure: const Clock.hm(7, 30),
        seats: 2,
        riderSeats: 3,
        tripCost: 160,
        contribution: 42,
        repeat: Repeat.daily,
        pickup: _pickup,
        status: OfferStatus.grouped,
        groupId: 'mk-of-1',
        origin: OfferOrigin.fromRequest,
        cancelledWithRiders: true,
      );
      final back = OfferedTrip.fromJson(_json(trip.toJson()));
      expect(back.toJson(), trip.toJson());
      expect(back.date, _date);
      expect(back.departure, const Clock.hm(7, 30));
      expect(back.status, OfferStatus.grouped);
      expect(back.origin, OfferOrigin.fromRequest);
    });

    test('TripRequest round-trips, detours and fixed price included', () {
      final req = TripRequest(
        id: 'rq-1',
        riderId: 'nadia',
        rider: const AnonymousRider(isWoman: false),
        leg: Leg.ret,
        from: Area.smartVillage,
        to: Area.october,
        date: _date,
        departure: const Clock.hm(17, 0),
        repeat: Repeat.once,
        pickup: _pickup,
        detourFrom: const {Area.october: 4, Area.sheikhZayed: 12},
        price: const SeatPrice(contribution: 44, fee: 0, cash: 45, mode: PricingMode.cash),
        status: RequestStatus.accepted,
        acceptedBy: 'karim',
        tripId: 'of-7',
      );
      final back = TripRequest.fromJson(_json(req.toJson()));
      expect(back.toJson(), req.toJson());
      expect(back.detourFrom, {Area.october: 4, Area.sheikhZayed: 12});
      expect(back.price, req.price);
      expect(back.rider.rating, isNull);
    });

    test('Booking round-trips', () {
      final b = _booking(bookedAt: WallTime(CalendarDate(2026, 10, 14), const Clock.hm(10, 5), 30));
      final back = Booking.fromJson(_json(b.toJson()));
      expect(back.toJson(), b.toJson());
      expect(back.source, const BookingSource.offer('of-1'));
      expect(back.rideId, 'offer:of-1');
      expect(back.bookedAt, b.bookedAt);
      expect(back.rider, _rider);
    });
  });

  group('Booking.reclaimable (005 R13, T034)', () {
    final early = _wed(10, 0);

    test('booked before the cut-off: reclaimable at 20:59, not at 21:00 or 21:01', () {
      final b = _booking(bookedAt: early);
      expect(b.reclaimable(_wed(20, 59)), isTrue);
      expect(b.reclaimable(_wed(21, 0)), isFalse);
      expect(b.reclaimable(_wed(21, 1)), isFalse);
    });

    test('booked at 20:59 holds the same rule; booked at 21:00 or 21:01 never is', () {
      expect(_booking(bookedAt: _wed(20, 59)).reclaimable(_wed(20, 59)), isTrue);
      expect(_booking(bookedAt: _wed(21, 0)).reclaimable(_wed(21, 0)), isFalse);
      expect(_booking(bookedAt: _wed(21, 1)).reclaimable(_wed(21, 1)), isFalse);
    });

    test('a same-day booking is never reclaimable', () {
      final sameDay = WallTime(_date, const Clock.hm(6, 0));
      expect(_booking(bookedAt: sameDay).reclaimable(sameDay), isFalse);
    });

    test('a subscriber is never reclaimable', () {
      final b = _booking(bookedAt: early, isSubscriber: true);
      expect(b.reclaimable(_wed(12, 0)), isFalse);
      expect(b.reclaimable(_wed(20, 59)), isFalse);
    });

    test('only a live booking holds a seat to take', () {
      for (final s in BookingStatus.values.where((s) => s != BookingStatus.booked)) {
        expect(_booking(bookedAt: early, status: s).reclaimable(_wed(12, 0)), isFalse, reason: s.name);
      }
    });

    test('holdAt maps onto SeatMath', () {
      final b = _booking(bookedAt: early);
      expect(b.holdAt(_wed(20, 59)).reclaimable, isTrue);
      expect(b.holdAt(_wed(21, 0)).reclaimable, isFalse);
      expect(b.holdAt(_wed(21, 0)).riderId, 'nadia');
    });
  });
}
