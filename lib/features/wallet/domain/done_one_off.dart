import '../../../core/time/calendar_date.dart';
import '../../commute/domain/commute_profile.dart' show Leg;

/// How a one-off seat is paid. `plan` = subscribed or company. Lives in the
/// wallet, not the marketplace, so the wallet reads one-off trips without
/// importing the marketplace back (005 research R9).
enum PaidBy { wallet, cash, plan }

/// One rider on one finished one-off trip, as the marketplace hands it to the
/// wallet (005 contracts/repositories.md "One-off trips into the wallet").
/// `wallet`/`plan` seats were debited at booking (`seatBooked`); `cash` ones
/// enter 004's cash-trial fold. [rideId] is 003's group ride id once an offer
/// became a group (R10), so a group trip and its booking share it.
final class DoneOneOff {
  const DoneOneOff({
    required this.rideId,
    required this.date,
    required this.leg,
    required this.paidBy,
    required this.contribution,
    required this.tripCost,
    required this.riderSeats,
    required this.riderId,
    required this.driverId,
  });

  final String rideId;
  final CalendarDate date;
  final Leg leg;
  final PaidBy paidBy;

  /// EGP to the driver for this seat (the published contribution).
  final int contribution;

  /// The offer's basis, for the fee cap (004 v2.1).
  final int tripCost;
  final int riderSeats;

  final String riderId;
  final String driverId;
}
