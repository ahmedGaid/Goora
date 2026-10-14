import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/marketplace/domain/seat_math.dart';

/// 005 research R6: free seats against riderSeats (the price basis).
void main() {
  final sz0725 = CorridorSeed.groups.firstWhere((g) => g.id == 'sz-0725');

  Ride ride(List<String> riding, {int seats = 4}) => Ride(
    groupId: 'sz-0725',
    date: CalendarDate(2026, 10, 18),
    leg: Leg.going,
    driverId: 'driver',
    passengers: [for (final id in riding) Passenger(memberId: id, stopId: 'main-gate')],
    stops: const [],
    seats: seats,
  );

  test('sz-0725 160/3 with its off-duty driver riding → 0 free, never the 4th place (T078)', () {
    expect([sz0725.tripCost, sz0725.riderSeats], [160, 3]);
    // Two riders + the off-duty driver in a 4-seat car.
    final r = ride(['rider-1', 'rider-2', 'off-duty-driver']);
    expect(r.freeSeats, 1, reason: 'the car itself has a 4th place');
    expect(SeatMath.ownGroupLeg(r, riderSeats: sz0725.riderSeats), 0);
  });

  test('counted against riderSeats, not the car', () {
    expect(SeatMath.ownGroupLeg(ride(['rider-1'], seats: 6), riderSeats: 3), 2);
  });

  test('a booker who is also a member is counted once', () {
    final r = ride(['rider-1', 'booker']);
    expect(SeatMath.ownGroupLeg(r, riderSeats: 3, bookings: const [SeatHold(riderId: 'booker')]), 1);
    expect(SeatMath.ownGroupLeg(r, riderSeats: 3, bookings: const [SeatHold(riderId: 'other')]), 0);
  });

  test('full car with one reclaimable booking: 1 free for a subscriber, 0 otherwise', () {
    final r = ride(['rider-1', 'rider-2']);
    const bookings = [SeatHold(riderId: 'one-off', reclaimable: true)];
    expect(SeatMath.ownGroupLeg(r, riderSeats: 3, bookings: bookings, subscriberView: true), 1);
    expect(SeatMath.ownGroupLeg(r, riderSeats: 3, bookings: bookings), 0);
  });

  test('a final (non-reclaimable) booking is never free, even for a subscriber', () {
    final r = ride(['rider-1', 'rider-2']);
    expect(
      SeatMath.ownGroupLeg(r, riderSeats: 3, bookings: const [SeatHold(riderId: 'one-off')], subscriberView: true),
      0,
    );
  });

  test('other seeded group: riderSeats − seeded free, then bookings', () {
    expect(SeatMath.otherGroupLeg(sz0725, Leg.going), sz0725.freeSeats(Leg.going));
    expect(
      SeatMath.otherGroupLeg(sz0725, Leg.going, bookings: const [SeatHold(riderId: 'x')]),
      sz0725.freeSeats(Leg.going) - 1,
    );
  });

  test('offered trip: seats − bookings, floored at 0', () {
    expect(SeatMath.offeredTrip(seats: 3, bookings: const [SeatHold(riderId: 'a')]), 2);
    expect(
      SeatMath.offeredTrip(
        seats: 1,
        bookings: const [
          SeatHold(riderId: 'a'),
          SeatHold(riderId: 'b'),
        ],
      ),
      0,
    );
  });
}
