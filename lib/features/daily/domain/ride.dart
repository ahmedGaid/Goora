import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';

enum RideStatus { scheduled, confirmed, delayed, driverArrived, inProgress, arrived, cancelled }

/// A person in the car on this leg and the stop they board at.
final class Passenger {
  const Passenger({required this.memberId, required this.stopId});

  final String memberId;
  final String stopId;
}

/// One trip (one leg on one date) of a group.
final class Ride {
  const Ride({
    required this.groupId,
    required this.date,
    required this.leg,
    required this.driverId,
    required this.passengers,
    required this.stops,
    this.delayMinutes = 0,
    this.confirmed = false,
    this.arrivedStopIds = const {},
    this.startedAt,
    this.endedAt,
    this.shareToken,
    this.seats,
  });

  final String groupId;
  final CalendarDate date;
  final Leg leg;

  /// Actual driver; null when nobody covers the leg.
  final String? driverId;
  final List<Passenger> passengers;

  /// Pickup stops in order with times already shifted by [delayMinutes].
  final List<Stop> stops;
  final int delayMinutes;
  final bool confirmed;
  final Set<String> arrivedStopIds;
  final WallTime? startedAt;
  final WallTime? endedAt;
  final String? shareToken;

  /// Passenger seats in the actual driver's car; null when unknown.
  final int? seats;

  /// Seats still free on this leg (FR-022a): the car's seats minus everyone
  /// riding in it — riders and off-duty drivers — absent people excluded.
  int? get freeSeats => seats == null ? null : seats! - passengers.length;

  String get id => idFor(groupId, date, leg);

  /// Deterministic: `<groupId>:<yyyy-mm-dd>:<going|return>` (data-model).
  static String idFor(String groupId, CalendarDate date, Leg leg) =>
      '$groupId:${date.toIso()}:${leg == Leg.going ? 'going' : 'return'}';

  /// Inverse of [idFor]: the ride's date and leg; null for a malformed id.
  static (CalendarDate, Leg)? parseId(String id) {
    final parts = id.split(':');
    if (parts.length < 3) return null;
    final leg = switch (parts.last) { 'going' => Leg.going, 'return' => Leg.ret, _ => null };
    if (leg == null) return null;
    try {
      return (CalendarDate.parse(parts[parts.length - 2]), leg);
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }

  RideStatus get status {
    if (driverId == null) return RideStatus.cancelled;
    if (endedAt != null) return RideStatus.arrived;
    if (startedAt != null) return RideStatus.inProgress;
    if (arrivedStopIds.isNotEmpty) return RideStatus.driverArrived;
    if (delayMinutes > 0) return RideStatus.delayed;
    if (confirmed) return RideStatus.confirmed;
    return RideStatus.scheduled;
  }

  Stop? stop(String stopId) {
    for (final s in stops) {
      if (s.id == stopId) return s;
    }
    return null;
  }

  WallTime pickupAt(String stopId) => WallTime(date, (stop(stopId) ?? stops.first).time);

  WallTime get firstPickup => WallTime(date, stops.first.time);

  Iterable<Passenger> passengersAt(String stopId) => passengers.where((p) => p.stopId == stopId);

  bool carries(String memberId) => passengers.any((p) => p.memberId == memberId);
}
