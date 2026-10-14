import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/place.dart';

/// What accepting a request or publishing a trip would do to a driver's day
/// (005 research R4). The order of the values is the order the rule checks.
enum TripFitKind { join, full, limitReached, doesntFit, oneGroupOnly, overlap, create }

/// One trip the driver already has that day: a group leg they drive, an
/// offered trip, or a trip made by accepting a request (research R5).
final class DayTrip {
  const DayTrip({
    required this.id,
    required this.leg,
    required this.from,
    required this.to,
    required this.departure,
    required this.durationMinutes,
    required this.seats,
    required this.taken,
  });

  final String id;
  final Leg leg;
  final Area from;
  final Area to;

  /// Minutes of the day.
  final int departure;
  final int durationMinutes;
  final int seats;
  final int taken;

  DayTrip withTaken(int taken) => DayTrip(
    id: id,
    leg: leg,
    from: from,
    to: to,
    departure: departure,
    durationMinutes: durationMinutes,
    seats: seats,
    taken: taken,
  );
}

/// What accepting or publishing would add.
final class Candidate {
  const Candidate({
    required this.leg,
    required this.from,
    required this.to,
    required this.departure,
    required this.durationMinutes,
    this.daily = false,
    this.leadsGroup = false,
  });

  final Leg leg;
  final Area from;
  final Area to;

  /// Minutes of the day.
  final int departure;
  final int durationMinutes;

  /// "Every workday" rather than "Just once".
  final bool daily;

  /// The driver already drives a daily commute group.
  final bool leadsGroup;
}

final class TripFit {
  const TripFit._(this.kind, {this.tripId, this.tripsLeftAfter});

  const TripFit.join(String tripId) : this._(TripFitKind.join, tripId: tripId);
  const TripFit.full(String tripId) : this._(TripFitKind.full, tripId: tripId);
  const TripFit.create(int tripsLeftAfter) : this._(TripFitKind.create, tripsLeftAfter: tripsLeftAfter);
  const TripFit.limitReached() : this._(TripFitKind.limitReached);
  const TripFit.doesntFit() : this._(TripFitKind.doesntFit);
  const TripFit.oneGroupOnly() : this._(TripFitKind.oneGroupOnly);
  const TripFit.overlap() : this._(TripFitKind.overlap);

  final TripFitKind kind;

  /// The trip to join, or the full one (join / full).
  final String? tripId;

  /// Trips the driver has left once this one exists (create).
  final int? tripsLeftAfter;

  @override
  bool operator ==(Object other) =>
      other is TripFit && other.kind == kind && other.tripId == tripId && other.tripsLeftAfter == tripsLeftAfter;

  @override
  int get hashCode => Object.hash(kind, tripId, tripsLeftAfter);

  @override
  String toString() => 'TripFit(${kind.name}, tripId: $tripId, tripsLeftAfter: $tripsLeftAfter)';
}

/// Constitution II's daily limit — at most 2 trips a day, one per direction —
/// and the ±30 min join (005 research R4, FR-019, FR-021). Twinned in
/// supabase/functions/_shared/marketplace.ts; both run
/// test/fixtures/marketplace_vectors.json.
abstract final class DriverDayRules {
  static const maxTrips = 2;

  /// Inclusive: a candidate exactly 30 min away still joins.
  static const joinWindowMinutes = 30;

  static int tripsLeft(List<DayTrip> trips) => trips.length >= maxTrips ? 0 : maxTrips - trips.length;

  /// First match wins: join → full → limitReached → doesntFit → oneGroupOnly →
  /// overlap → create.
  static TripFit fit(List<DayTrip> trips, Candidate c) {
    final near =
        [
          for (final t in trips)
            if (t.leg == c.leg &&
                t.from == c.from &&
                t.to == c.to &&
                (t.departure - c.departure).abs() <= joinWindowMinutes)
              t,
        ]..sort((a, b) {
          final byGap = (a.departure - c.departure).abs().compareTo((b.departure - c.departure).abs());
          return byGap != 0 ? byGap : a.id.compareTo(b.id);
        });
    for (final t in near) {
      if (t.taken < t.seats) return TripFit.join(t.id);
    }
    if (near.isNotEmpty) return TripFit.full(near.first.id);
    if (trips.length >= maxTrips) return const TripFit.limitReached();
    if (trips.any((t) => t.leg == c.leg)) return const TripFit.doesntFit();
    if (c.daily && c.leadsGroup) return const TripFit.oneGroupOnly();
    final end = c.departure + c.durationMinutes;
    if (trips.any((t) => c.departure < t.departure + t.durationMinutes && t.departure < end)) {
      return const TripFit.overlap();
    }
    return TripFit.create(tripsLeft(trips) - 1);
  }
}
