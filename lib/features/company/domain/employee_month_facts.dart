import '../../commute/domain/place.dart';

/// What one enrolled employee did in one month: the dashboard aggregator's
/// input (data-model.md "Per-person activity facts"). Never shown to HR —
/// only totals built from it are, with k = 5 suppression (research R6).
final class EmployeeMonthFacts {
  const EmployeeMonthFacts({
    required this.personId,
    required this.riderTrips,
    required this.riderGoingTrips,
    required this.driverTrips,
    required this.savedEgp,
    required this.km,
    required this.homeArea,
    required this.hasProfile,
    required this.hasGroup,
    this.groupIds = const [],
  });

  final String personId;

  /// Completed legs ridden as a rider (group or one-off).
  final int riderTrips;

  /// Of [riderTrips], the going legs (parking spaces freed, research R7).
  final int riderGoingTrips;
  final int driverTrips;

  /// Σ (leg trip cost − share paid) over [riderTrips].
  final int savedEgp;

  /// Rider kilometres, for the CO₂ estimate.
  final int km;

  /// Coarse area only — never an address or pickup point.
  final Area homeArea;
  final bool hasProfile;
  final bool hasGroup;
  final List<String> groupIds;

  /// Rode or drove at least once (FR-021 "active this month").
  bool get isActive => riderTrips + driverTrips > 0;
}
