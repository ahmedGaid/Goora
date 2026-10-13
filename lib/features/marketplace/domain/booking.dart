import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/commute_profile.dart';
import '../../daily/domain/attendance_rules.dart';
import '../../wallet/domain/done_one_off.dart';
import '../../wallet/domain/seat_price.dart';
import 'anonymous_rider.dart';
import 'seat_math.dart';

export '../../wallet/domain/done_one_off.dart' show PaidBy;

enum BookingSourceKind { groupSeat, offer, request }

/// Where a booked seat came from: a group's free seat, an offered trip, or an
/// accepted request.
final class BookingSource {
  const BookingSource._(this.kind, this.id);

  const BookingSource.groupSeat(String groupId) : this._(BookingSourceKind.groupSeat, groupId);
  const BookingSource.offer(String tripId) : this._(BookingSourceKind.offer, tripId);
  const BookingSource.request(String requestId) : this._(BookingSourceKind.request, requestId);

  final BookingSourceKind kind;

  /// The group, offered trip or request id.
  final String id;

  Map<String, Object?> toJson() => {'kind': kind.name, 'id': id};

  static BookingSource fromJson(Map<String, Object?> j) =>
      BookingSource._(BookingSourceKind.values.byName(j['kind']! as String), j['id']! as String);

  @override
  bool operator ==(Object other) => other is BookingSource && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'BookingSource(${kind.name}, $id)';
}

/// booked → done (trip end passed) · booked → cancelled (rider; refund =
/// BookingRefund.amount) · booked → reclaimed (a subscriber took it before the
/// cut-off; full refund) · booked → refunded (driver cancelled; full refund).
enum BookingStatus { booked, done, cancelled, reclaimed, refunded }

/// One rider in one seat on one leg-date (005 data-model.md).
final class Booking {
  const Booking({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.rider,
    required this.source,
    required this.date,
    required this.leg,
    required this.rideId,
    required this.price,
    required this.paidBy,
    required this.paid,
    required this.bookedAt,
    required this.isSubscriber,
    this.status = BookingStatus.booked,
  });

  /// The [rideId] of a seat on an offered trip; a group seat uses 003's
  /// `Ride.idFor`.
  static String offerRideId(String tripId) => 'offer:$tripId';

  /// `bk-<n>`.
  final String id;
  final String riderId;

  /// Shown to the driver only from departure (R15).
  final String riderName;
  final AnonymousRider rider;
  final BookingSource source;
  final CalendarDate date;
  final Leg leg;
  final String rideId;

  /// The quote at booking.
  final SeatPrice price;
  final PaidBy paidBy;

  /// The ledger debit at booking; 0 for cash.
  final int paid;
  final WallTime bookedAt;

  /// Subscribers' seats can't be reclaimed.
  final bool isSubscriber;
  final BookingStatus status;

  /// A subscriber could still take this seat (R13, FR-025): booked before
  /// the 9 PM cut-off the evening before, and it is still before it now. Only
  /// a live booking holds a seat to take.
  bool reclaimable(WallTime now) =>
      status == BookingStatus.booked &&
      !isSubscriber &&
      !AttendanceRules.isLate(date, bookedAt) &&
      !AttendanceRules.isLate(date, now);

  /// What seat math needs of this booking at [now].
  SeatHold holdAt(WallTime now) => SeatHold(riderId: riderId, reclaimable: reclaimable(now));

  Booking copyWith({BookingStatus? status, String? rideId}) => Booking(
        id: id,
        riderId: riderId,
        riderName: riderName,
        rider: rider,
        source: source,
        date: date,
        leg: leg,
        rideId: rideId ?? this.rideId,
        price: price,
        paidBy: paidBy,
        paid: paid,
        bookedAt: bookedAt,
        isSubscriber: isSubscriber,
        status: status ?? this.status,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'riderId': riderId,
        'riderName': riderName,
        'rider': rider.toJson(),
        'source': source.toJson(),
        'date': date.toIso(),
        'leg': leg.name,
        'rideId': rideId,
        'price': price.toJson(),
        'paidBy': paidBy.name,
        'paid': paid,
        'bookedAt': bookedAt.toJson(),
        'isSubscriber': isSubscriber,
        'status': status.name,
      };

  static Booking fromJson(Map<String, Object?> j) => Booking(
        id: j['id']! as String,
        riderId: j['riderId']! as String,
        riderName: j['riderName']! as String,
        rider: AnonymousRider.fromJson(_map(j['rider'])),
        source: BookingSource.fromJson(_map(j['source'])),
        date: CalendarDate.parse(j['date']! as String),
        leg: Leg.values.byName(j['leg']! as String),
        rideId: j['rideId']! as String,
        price: SeatPrice.fromJson(_map(j['price'])),
        paidBy: PaidBy.values.byName(j['paidBy']! as String),
        paid: j['paid']! as int,
        bookedAt: WallTime.fromJson(j['bookedAt']! as String),
        isSubscriber: j['isSubscriber']! as bool,
        status: BookingStatus.values.byName(j['status']! as String),
      );
}

Map<String, Object?> _map(Object? o) => (o! as Map).cast<String, Object?>();
