import '../../../core/time/calendar_date.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';
import '../../commute/domain/place.dart';
import '../../wallet/domain/seat_price.dart';
import 'anonymous_rider.dart';
import 'offered_trip.dart';

/// posted → accepted (a driver accepts and the rider passes BookingGate) ·
/// posted → withdrawn (the gate fails at accept) · posted → cancelled (rider,
/// free, FR-012) · posted → expired (now ≥ date + departure, no charge).
enum RequestStatus { posted, accepted, withdrawn, cancelled, expired }

/// A trip a rider posts for drivers to accept (B; 005 data-model.md).
final class TripRequest {
  const TripRequest({
    required this.id,
    required this.riderId,
    required this.rider,
    required this.leg,
    required this.from,
    required this.to,
    required this.date,
    required this.departure,
    required this.repeat,
    required this.pickup,
    required this.price,
    this.detourFrom = const {},
    this.status = RequestStatus.posted,
    this.acceptedBy,
    this.tripId,
  });

  /// `rq-<n>`; seeded `rq-seed-*`.
  final String id;
  final String riderId;

  /// What drivers see.
  final AnonymousRider rider;
  final Leg leg;
  final Area from;
  final Area to;
  final CalendarDate date;
  final Clock departure;

  /// `daily` isn't allowed when the rider is already in a group (R10).
  final Repeat repeat;

  /// The nearest public stop to the rider's home area.
  final Stop pickup;

  /// Seeded detour minutes by the driver's origin area (R14); fits under 10.
  final Map<Area, int> detourFrom;

  /// Quoted for the rider at posting and fixed from then on (FR-022).
  final SeatPrice price;
  final RequestStatus status;

  /// The accepting driver's id.
  final String? acceptedBy;

  /// The offered trip or group ride the rider was seated in.
  final String? tripId;

  TripRequest copyWith({RequestStatus? status, String? acceptedBy, String? tripId}) => TripRequest(
        id: id,
        riderId: riderId,
        rider: rider,
        leg: leg,
        from: from,
        to: to,
        date: date,
        departure: departure,
        repeat: repeat,
        pickup: pickup,
        detourFrom: detourFrom,
        price: price,
        status: status ?? this.status,
        acceptedBy: acceptedBy ?? this.acceptedBy,
        tripId: tripId ?? this.tripId,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'riderId': riderId,
        'rider': rider.toJson(),
        'leg': leg.name,
        'from': from.name,
        'to': to.name,
        'date': date.toIso(),
        'departure': departure.minutes,
        'repeat': repeat.name,
        'pickup': pickup.toJson(),
        // Written in enum order, so the JSON is stable.
        'detourFrom': {
          for (final a in Area.values)
            if (detourFrom.containsKey(a)) a.name: detourFrom[a],
        },
        'price': price.toJson(),
        'status': status.name,
        'acceptedBy': acceptedBy,
        'tripId': tripId,
      };

  static TripRequest fromJson(Map<String, Object?> j) => TripRequest(
        id: j['id']! as String,
        riderId: j['riderId']! as String,
        rider: AnonymousRider.fromJson(_map(j['rider'])),
        leg: Leg.values.byName(j['leg']! as String),
        from: Area.values.byName(j['from']! as String),
        to: Area.values.byName(j['to']! as String),
        date: CalendarDate.parse(j['date']! as String),
        departure: Clock(j['departure']! as int),
        repeat: Repeat.values.byName(j['repeat']! as String),
        pickup: Stop.fromJson(_map(j['pickup'])),
        detourFrom: {for (final e in _map(j['detourFrom']).entries) Area.values.byName(e.key): e.value! as int},
        price: SeatPrice.fromJson(_map(j['price'])),
        status: RequestStatus.values.byName(j['status']! as String),
        acceptedBy: j['acceptedBy'] as String?,
        tripId: j['tripId'] as String?,
      );
}

Map<String, Object?> _map(Object? o) => (o! as Map).cast<String, Object?>();
