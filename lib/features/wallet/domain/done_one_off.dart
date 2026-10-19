import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/commute_profile.dart' show Leg;

/// What a one-off seat put on Goora's ledger at booking (007 research R5).
/// `wallet` = Goora's fee taken at booking; `plan` = subscribed or company
/// (fee 0, row written); `cash` = a fee-free trial seat, nothing at booking.
/// The driver's share is never here. Lives in the wallet, not the
/// marketplace, so the wallet reads one-off trips without importing the
/// marketplace back (005 research R9).
enum PaidBy { wallet, cash, plan }

/// One rider on one finished one-off trip, as the marketplace hands it to the
/// wallet (005 contracts/repositories.md "One-off trips into the wallet").
/// `wallet`/`plan` seats have a `seatBooked` row; `cash` ones enter the trial
/// fold. [rideId] is 003's group ride id once an offer became a group (R10),
/// so a group trip and its booking share it.
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
    this.riderName = '',
    this.driverName = '',
    this.end,
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

  /// First names only, for the share each side sees (007 FR-018).
  final String riderName;
  final String driverName;

  /// When the trip ended (007 R2's 24-hour clock); null = end of [date].
  final WallTime? end;
}
