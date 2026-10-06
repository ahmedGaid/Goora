import '../../../core/time/wall_time.dart';

/// Driver position as progress along the drawn route (research R8); no
/// coordinates are needed until maps exist.
final class TripPosition {
  const TripPosition({required this.rideId, required this.progress, required this.at});

  final String rideId;

  /// 0 (pickup) … 1 (arrival).
  final double progress;
  final WallTime at;
}

abstract interface class LocationSource {
  Stream<TripPosition> watch(String rideId);
}
