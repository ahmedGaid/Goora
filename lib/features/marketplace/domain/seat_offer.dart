import '../../../core/time/calendar_date.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';
import '../../wallet/domain/seat_price.dart';
import 'booking.dart';

/// The driver as riders see them on a seat — riders may see drivers (R15).
final class SeatDriver {
  const SeatDriver({required this.id, required this.firstName, required this.initials, required this.rating});

  final String id;
  final String firstName;

  /// For the avatar.
  final String initials;

  /// 0–5 stars.
  final double rating;
}

/// One free seat a rider can book on Empty seats (005 data-model.md). Derived
/// at read time from groups' next departures and open offers — never stored.
final class SeatOffer {
  const SeatOffer({
    required this.source,
    required this.driver,
    required this.pickup,
    required this.date,
    required this.leg,
    required this.departure,
    required this.freeSeats,
    required this.price,
  });

  /// A group seat or an offered trip.
  final BookingSource source;
  final SeatDriver driver;
  final Stop pickup;
  final CalendarDate date;
  final Leg leg;
  final Clock departure;

  /// From `SeatMath`, already > 0 (R6).
  final int freeSeats;

  /// Quoted for the viewing rider.
  final SeatPrice price;
}
