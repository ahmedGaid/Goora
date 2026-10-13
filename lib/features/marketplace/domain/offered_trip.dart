import '../../../core/time/calendar_date.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';
import '../../commute/domain/place.dart';

/// "Just once" or "Every workday".
enum Repeat { once, daily }

/// open → full → open (a booking cancelled or reclaimed) · open|full →
/// departed → done by the clock · open|full → cancelled (driver) · open|full →
/// grouped (daily, first booking; it then lives as a CommuteGroup, R10).
enum OfferStatus { open, full, departed, done, cancelled, grouped }

/// Published by the driver (C), or created by accepting a request (D).
enum OfferOrigin { published, fromRequest }

/// A trip a driver offers to riders (005 data-model.md).
final class OfferedTrip {
  const OfferedTrip({
    required this.id,
    required this.driverId,
    required this.leg,
    required this.from,
    required this.to,
    required this.date,
    required this.departure,
    required this.seats,
    required this.riderSeats,
    required this.tripCost,
    required this.contribution,
    required this.repeat,
    required this.pickup,
    this.durationMinutes = 40,
    this.status = OfferStatus.open,
    this.groupId,
    this.origin = OfferOrigin.published,
    this.cancelledWithRiders = false,
  }) : assert(seats >= 1 && seats <= 4 && seats <= riderSeats);

  /// `of-<n>`; seeded offers `of-seed-*`.
  final String id;
  final String driverId;

  /// Going = home area → work area.
  final Leg leg;
  final Area from;
  final Area to;

  /// Resolved by `MarketDay` (R13).
  final CalendarDate date;
  final Clock departure;
  final int durationMinutes;

  /// Capacity offered, 1–4.
  final int seats;

  /// The price basis (R6). Published: = [seats]. From a request: the
  /// request's basis, so its fixed price stays inside ±20%.
  final int riderSeats;
  final int tripCost;

  /// Within `PricingService.range(tripCost, riderSeats)`, 2 EGP steps.
  final int contribution;
  final Repeat repeat;

  /// A public point, never a home.
  final Stop pickup;
  final OfferStatus status;

  /// Set when a daily trip became a group.
  final String? groupId;
  final OfferOrigin origin;

  /// Cancelled with ≥ 1 booking: still counts on the driver's day (R5).
  final bool cancelledWithRiders;

  OfferedTrip copyWith({OfferStatus? status, String? groupId, bool? cancelledWithRiders}) => OfferedTrip(
        id: id,
        driverId: driverId,
        leg: leg,
        from: from,
        to: to,
        date: date,
        departure: departure,
        durationMinutes: durationMinutes,
        seats: seats,
        riderSeats: riderSeats,
        tripCost: tripCost,
        contribution: contribution,
        repeat: repeat,
        pickup: pickup,
        status: status ?? this.status,
        groupId: groupId ?? this.groupId,
        origin: origin,
        cancelledWithRiders: cancelledWithRiders ?? this.cancelledWithRiders,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'driverId': driverId,
        'leg': leg.name,
        'from': from.name,
        'to': to.name,
        'date': date.toIso(),
        'departure': departure.minutes,
        'durationMinutes': durationMinutes,
        'seats': seats,
        'riderSeats': riderSeats,
        'tripCost': tripCost,
        'contribution': contribution,
        'repeat': repeat.name,
        'pickup': pickup.toJson(),
        'status': status.name,
        'groupId': groupId,
        'origin': origin.name,
        'cancelledWithRiders': cancelledWithRiders,
      };

  static OfferedTrip fromJson(Map<String, Object?> j) => OfferedTrip(
        id: j['id']! as String,
        driverId: j['driverId']! as String,
        leg: Leg.values.byName(j['leg']! as String),
        from: Area.values.byName(j['from']! as String),
        to: Area.values.byName(j['to']! as String),
        date: CalendarDate.parse(j['date']! as String),
        departure: Clock(j['departure']! as int),
        durationMinutes: j['durationMinutes']! as int,
        seats: j['seats']! as int,
        riderSeats: j['riderSeats']! as int,
        tripCost: j['tripCost']! as int,
        contribution: j['contribution']! as int,
        repeat: Repeat.values.byName(j['repeat']! as String),
        pickup: Stop.fromJson((j['pickup']! as Map).cast<String, Object?>()),
        status: OfferStatus.values.byName(j['status']! as String),
        groupId: j['groupId'] as String?,
        origin: OfferOrigin.values.byName(j['origin']! as String),
        cancelledWithRiders: j['cancelledWithRiders']! as bool,
      );
}
