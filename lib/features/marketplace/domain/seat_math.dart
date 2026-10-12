import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';
import '../../daily/domain/ride.dart';

/// One active one-off booking on a leg-date, as seat math needs it.
final class SeatHold {
  const SeatHold({required this.riderId, this.reclaimable = false});

  final String riderId;

  /// A subscriber could still take this seat (booked before the 9 PM cut-off,
  /// and now is before it — research R13).
  final bool reclaimable;
}

/// Free seats on a leg-date (005 research R6, FR-004, FR-024). Seats are
/// counted against `riderSeats`, the price basis — never the car's physical
/// seats — so riders' total stays within the trip cost.
abstract final class SeatMath {
  /// `seats − riding − held`, floored at 0.
  static int free({required int seats, required int riding, required int held}) {
    final f = seats - riding - held;
    return f < 0 ? 0 : f;
  }

  /// Bookings that hold a seat. A rider already riding (they also became a
  /// member) counts once, not twice; for a subscriber a reclaimable booking is
  /// free (US6 AC1).
  static int held(Iterable<SeatHold> bookings, {Set<String> riding = const {}, bool subscriberView = false}) =>
      bookings.where((b) => !riding.contains(b.riderId) && !(subscriberView && b.reclaimable)).length;

  /// The person's own group: riding = 003's derived passengers (riders and
  /// off-duty drivers, absences already excluded).
  static int ownGroupLeg(
    Ride ride, {
    required int riderSeats,
    Iterable<SeatHold> bookings = const [],
    bool subscriberView = false,
  }) {
    final riding = {for (final p in ride.passengers) p.memberId};
    return free(
      seats: riderSeats,
      riding: riding.length,
      held: held(bookings, riding: riding, subscriberView: subscriberView),
    );
  }

  /// Any other seeded group: its seeded free count is already net of members.
  static int otherGroupLeg(
    CommuteGroup group,
    Leg leg, {
    Iterable<SeatHold> bookings = const [],
    bool subscriberView = false,
  }) => free(
    seats: group.riderSeats,
    riding: group.riderSeats - group.freeSeats(leg),
    held: held(bookings, subscriberView: subscriberView),
  );

  /// An offered trip: its own seats minus its bookings.
  static int offeredTrip({required int seats, Iterable<SeatHold> bookings = const [], bool subscriberView = false}) =>
      free(
        seats: seats,
        riding: 0,
        held: held(bookings, subscriberView: subscriberView),
      );
}
