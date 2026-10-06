import 'dart:async';

import '../../../core/time/now_provider.dart';
import '../../../core/time/wall_time.dart';
import '../domain/daily_commute_repository.dart';
import '../domain/location_source.dart';
import '../domain/ride.dart';

/// From the driver's first "I've arrived" (or the trip start, or the first
/// pickup time) to arrival at the destination.
final class TripWindow {
  const TripWindow(this.start, this.end);

  final WallTime start;
  final WallTime end;

  /// Elapsed ÷ trip time, 0…1 (research R8).
  double progressAt(WallTime now) {
    final total = start.secondsUntil(end);
    if (total <= 0) return 1;
    return (start.secondsUntil(now) / total).clamp(0.0, 1.0);
  }
}

/// Stands in for the driver's phone until maps and the server exist
/// (research R8): one position every [tick] (5 s, inside the 10 s refresh
/// limit of FR-028) until arrival, then the stream closes.
final class SimulatedLocationSource implements LocationSource {
  SimulatedLocationSource(this._repo, {required this.now, this.tick = const Duration(seconds: 5)});

  final DailyCommuteRepository _repo;
  final Now now;
  final Duration tick;

  @override
  Stream<TripPosition> watch(String rideId) {
    Timer? timer;
    var cancelled = false;
    late final StreamController<TripPosition> out;
    out = StreamController<TripPosition>(
      onListen: () async {
        final window = await this.window(rideId);
        if (cancelled) return;
        if (window == null) {
          await out.close();
          return;
        }
        void emit() {
          final at = now();
          out.add(TripPosition(rideId: rideId, progress: window.progressAt(at), at: at));
          if (!at.isBefore(window.end)) {
            timer?.cancel();
            out.close();
          }
        }

        emit();
        if (!out.isClosed) timer = Timer.periodic(tick, (_) => emit());
      },
      onCancel: () {
        cancelled = true;
        timer?.cancel();
      },
    );
    return out.stream;
  }

  /// Null when the ride does not exist or nobody drives it.
  Future<TripWindow?> window(String rideId) async {
    final key = Ride.parseId(rideId);
    if (key == null) return null;
    final (date, leg) = key;
    final ride = await _repo.ride(date, leg);
    final group = await _repo.myGroup();
    if (ride == null || ride.driverId == null || group == null) return null;
    final arrivals = [for (final c in await _repo.checkIns(rideId)) c.arrivedAt]..sort();
    final start = arrivals.firstOrNull ?? ride.startedAt ?? ride.firstPickup;
    final end = ride.endedAt ?? WallTime(date, group.endFor(leg).shift(ride.delayMinutes));
    return TripWindow(start, end);
  }
}
