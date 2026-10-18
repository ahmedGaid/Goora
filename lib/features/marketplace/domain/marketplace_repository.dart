import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';
import '../../commute/domain/place.dart';
import '../../daily/domain/trust.dart';
import '../../wallet/domain/done_one_off.dart';
import '../../wallet/domain/seat_price.dart';
import 'anonymous_rider.dart';
import 'booking.dart';
import 'driver_day.dart';
import 'driver_day_rules.dart';
import 'offered_trip.dart';
import 'seat_offer.dart';
import 'trip_request.dart';

/// Find riders' Morning / Evening toggle.
enum PartOfDay { morning, evening }

/// What a rider fills in on Post your trip (B). The day is resolved by
/// `MarketDay` (R13); the price is the system's (FR-022).
final class TripDraft {
  const TripDraft({required this.leg, required this.from, required this.to, required this.departure, required this.repeat});

  final Leg leg;
  final Area from;
  final Area to;
  final Clock departure;
  final Repeat repeat;
}

/// What a driver fills in on Offer a trip (C). [contribution] comes from the
/// stepper inside `PricingService.range` — never typed (FR-015, FR-022).
final class OfferDraft {
  const OfferDraft({
    required this.leg,
    required this.from,
    required this.to,
    required this.departure,
    required this.seats,
    required this.contribution,
    required this.repeat,
  });

  final Leg leg;
  final Area from;
  final Area to;
  final Clock departure;

  /// 1–4.
  final int seats;
  final int contribution;
  final Repeat repeat;
}

/// One booked rider on the driver's live trip: anonymous until departure,
/// then [firstName] is set (R15, FR-023).
final class LiveRider {
  const LiveRider({required this.rider, this.firstName, this.riderId, this.paidBy, this.price});

  final AnonymousRider rider;
  final String? firstName;

  /// The booking behind the row, for the cash rows after the trip (FR-029).
  final String? riderId;
  final PaidBy? paidBy;
  final SeatPrice? price;
}

/// What a driver must have verified before publishing (FR-014).
const publishChecks = {VerificationKind.nationalId, VerificationKind.license, VerificationKind.vehicle};

/// A published trip as its driver watches it fill (FR-016).
final class OfferLive {
  const OfferLive({required this.trip, required this.riders});

  final OfferedTrip trip;

  /// Active bookings, oldest first.
  final List<LiveRider> riders;

  int get taken => riders.length;
  bool get isFull => taken >= trip.seats;
}

/// A request as a driver sees it on Find riders or driver Today (FR-018,
/// FR-020). It has no name and no photo (FR-023).
final class RequestCard {
  const RequestCard({
    required this.requestId,
    required this.leg,
    required this.from,
    required this.to,
    required this.rider,
    required this.pickup,
    required this.date,
    required this.departure,
    required this.repeat,
    required this.price,
    required this.detourMinutes,
    required this.fit,
    this.joinTime,
  });

  final String requestId;
  final Leg leg;
  final Area from;
  final Area to;
  final AnonymousRider rider;
  final Stop pickup;
  final CalendarDate date;
  final Clock departure;
  final Repeat repeat;

  /// The request's rider's price, fixed at posting.
  final SeatPrice price;

  /// From the driver's area (R14).
  final int detourMinutes;

  /// What accepting would do to the driver's day (`DriverDayRules`).
  final TripFit fit;

  /// The time of the trip a join lands on (fit = join).
  final Clock? joinTime;
}

/// Book on Empty seats (A).
sealed class BookResult {
  const BookResult();
}

final class Booked extends BookResult {
  const Booked(this.booking);
  final Booking booking;
}

final class BookNeedsMethod extends BookResult {
  const BookNeedsMethod();
}

/// A driver marked a share of this rider's as not received (007 FR-005).
final class BookOwesDriver extends BookResult {
  const BookOwesDriver(this.amount, this.driverFirstName);

  final int amount;
  final String driverFirstName;
}

/// Goora's owed fees are overdue (008 FR-005).
final class BookFeeOverdue extends BookResult {
  const BookFeeOverdue(this.amount);
  final int amount;
}

/// The rider's ID isn't checked yet (009 FR-002); nothing was booked.
final class BookNeedsId extends BookResult {
  const BookNeedsId();
}

/// No free seat left at the moment of writing (SC-006).
final class SeatTaken extends BookResult {
  const SeatTaken();
}

/// One booking per rider per leg-date, and not on a leg they already ride.
final class AlreadyRiding extends BookResult {
  const AlreadyRiding();
}

/// Publish on Offer a trip (C).
sealed class PublishResult {
  const PublishResult();
}

final class Published extends PublishResult {
  const Published(this.trip);
  final OfferedTrip trip;
}

/// FR-014: the missing checks, shown as chips that open Trust.
final class NotVerified extends PublishResult {
  const NotVerified(this.missing);
  final List<VerificationKind> missing;
}

/// Anything but `create` from `DriverDayRules.fit`.
final class OverLimit extends PublishResult {
  const OverLimit(this.fit);
  final TripFit fit;
}

/// Accept on Find riders / driver Today (D).
sealed class AcceptResult {
  const AcceptResult();
}

/// A new trip was created.
final class AcceptCreated extends AcceptResult {
  const AcceptCreated(this.tripsLeft);
  final int tripsLeft;
}

/// The rider joined a trip the driver already has, using no extra trip.
final class AcceptJoined extends AcceptResult {
  const AcceptJoined(this.time);
  final Clock time;
}

final class AcceptRefused extends AcceptResult {
  const AcceptRefused(this.fit);
  final TripFit fit;
}

/// The rider failed the gate at accept; the request is withdrawn.
final class RiderCantPay extends AcceptResult {
  const RiderCantPay();
}

/// Post on Post your trip (B).
sealed class PostResult {
  const PostResult();
}

final class Posted extends PostResult {
  const Posted(this.request);
  final TripRequest request;
}

final class PostNeedsMethod extends PostResult {
  const PostNeedsMethod();
}

/// A driver marked a share of this rider's as not received (007 FR-005).
final class PostOwesDriver extends PostResult {
  const PostOwesDriver(this.amount, this.driverFirstName);

  final int amount;
  final String driverFirstName;
}

/// Goora's owed fees are overdue (008 FR-005).
final class PostFeeOverdue extends PostResult {
  const PostFeeOverdue(this.amount);
  final int amount;
}

/// The rider's ID isn't checked yet (009 FR-002); nothing was posted.
final class PostNeedsId extends PostResult {
  const PostNeedsId();
}

/// The rider is already in a daily group (R10).
final class DailyNotAllowed extends PostResult {
  const DailyNotAllowed();
}

/// A subscriber takes a one-off seat (US6, FR-025).
sealed class ReclaimResult {
  const ReclaimResult();
}

final class Reclaimed extends ReclaimResult {
  const Reclaimed(this.refund);

  /// EGP back to the booker's wallet.
  final int refund;
}

/// At or after the 9 PM cut-off: the booking is final.
final class ReclaimTooLate extends ReclaimResult {
  const ReclaimTooLate();
}

/// Booked after the cut-off, by a subscriber, or no longer live.
final class NotReclaimable extends ReclaimResult {
  const NotReclaimable();
}

/// A rider cancels their booking.
sealed class CancelResult {
  const CancelResult();
}

final class BookingCancelled extends CancelResult {
  const BookingCancelled(this.refund);

  /// EGP back to the wallet (`BookingRefund.amount`).
  final int refund;
}

/// Already cancelled, reclaimed, refunded or done.
final class NotCancellable extends CancelResult {
  const NotCancellable();
}

/// Settings → Demo actions (debug only, FR-028).
sealed class DemoResult {
  const DemoResult();
}

final class DemoDone extends DemoResult {
  const DemoDone();
}

/// Nothing to act on (no posted request, no open offer, no reclaimable seat).
final class DemoNothing extends DemoResult {
  const DemoNothing();
}

/// The reclaim demo after 9 PM: "Too late to reclaim — this booking is final."
final class DemoTooLate extends DemoResult {
  const DemoTooLate();
}

/// The seat marketplace (005 contracts/repositories.md). The fake runs on
/// shared_preferences; a Supabase one calls the server, whose own ledger and
/// rule twins decide.
abstract interface class MarketplaceRepository {
  // A — Empty seats
  Future<List<SeatOffer>> seatOffers(Leg leg, {required WallTime now});

  /// Re-checks free seats and the gate inside the write; a failure changes
  /// nothing (SC-006).
  Future<BookResult> book(SeatOffer offer, {required WallTime now});
  Future<CancelResult> cancelBooking(String bookingId, {required WallTime now});

  /// Booked, not done or ended, oldest first.
  Future<List<Booking>> myBookings({required WallTime now});

  /// The seat a booking rides on — driver, pickup and time — for the rider's
  /// Today. Null when its source is gone.
  Future<SeatOffer?> seatOf(Booking booking);

  // B — Post your trip
  Future<PostResult> post(TripDraft draft, {required WallTime now});
  Future<void> cancelRequest(String requestId);

  /// The person's requests still waiting for a driver, soonest first.
  Future<List<TripRequest>> myRequests({required WallTime now});

  /// Expires on read (R13).
  Future<TripRequest?> request(String requestId, {required WallTime now});

  /// "Sent to N drivers on your route".
  Future<int> driversOnRoute(TripDraft draft);

  // C — Offer a trip
  Future<PublishResult> publish(OfferDraft draft, {required WallTime now});
  Future<OfferedTrip?> offer(String tripId, {required WallTime now});

  /// Seats and anonymous riders; first names from departure.
  Future<OfferLive> live(String tripId, {required WallTime now});

  /// Refunds every booking in full; counts on reliability (FR-017).
  Future<void> cancelOffer(String tripId, {required WallTime now});

  // D — Find riders / driver Today
  Future<DriverDay> driverDay(CalendarDate date);
  Future<List<RequestCard>> requestsForMe({Area? leavingFrom, required PartOfDay part, required WallTime now});
  Future<AcceptResult> accept(String requestId, {required WallTime now});

  // US6 — a subscriber takes the seat
  Future<ReclaimResult> reclaim(String bookingId, {required WallTime now});

  /// Every finished one-off seat, for the wallet's cash trial and the
  /// driver's income (research R9, T038). Not a screen's call.
  Future<List<DoneOneOff>> doneOneOffs();

  // Demo (debug only, FR-028)
  Future<DemoResult> demoDriverAccepts({required WallTime now});
  Future<DemoResult> demoRiderBooks({required WallTime now});
  Future<DemoResult> demoSubscriberTakes({required WallTime now});
}
