import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/place.dart';

// The only shapes the HR contact ever gets (research R6, constitution IV).
// None carries a person id, group, pickup point, time of travel, share status
// or role; `company_privacy_test.dart` (P7) checks the fields.

/// One row of the roster (FR-016): what the employee agreed the company sees.
final class RosterRow {
  const RosterRow({required this.name, required this.workEmail, required this.enrolledAt, this.leftAt});

  final String name;
  final String workEmail;
  final WallTime enrolledAt;

  /// Set only for this calendar month's leavers ("left on" + the date).
  final WallTime? leftAt;

  @override
  bool operator ==(Object other) =>
      other is RosterRow &&
      other.name == name &&
      other.workEmail == workEmail &&
      other.enrolledAt == enrolledAt &&
      other.leftAt == leftAt;

  @override
  int get hashCode => Object.hash(name, workEmail, enrolledAt, leftAt);

  @override
  String toString() => 'RosterRow($name, $workEmail, $enrolledAt${leftAt == null ? '' : ' → $leftAt'})';
}

/// One month of the dashboard (FR-021, FR-022): totals only. Every number is
/// null when built from fewer than 5 employees ("fewer than 5").
final class DashboardMonth {
  const DashboardMonth({
    required this.month,
    required this.soFar,
    required this.enrolled,
    required this.active,
    required this.carpoolRatePct,
    required this.groups,
    required this.tripsShared,
    required this.moneySaved,
    required this.co2Kg,
    required this.parkingPerDay,
    required this.routeGaps,
  });

  /// `yyyy-mm`.
  final String month;

  /// The current month, still running.
  final bool soFar;
  final int? enrolled;
  final int? active;
  final int? carpoolRatePct;
  final int? groups;
  final int? tripsShared;

  /// Whole EGP, estimate (research R7).
  final int? moneySaved;

  /// Estimate (research R7).
  final int? co2Kg;
  final int? parkingPerDay;

  /// Home areas with ≥ 5 employees waiting with no group; smaller ones are
  /// not listed at all.
  final List<(Area, int)> routeGaps;
}

/// One line of the HR statement (US6, FR-025): only for an employee whose
/// consent was on at the end of the month, rider trips only, received or
/// auto-received shares only (Q7).
final class StatementLine {
  const StatementLine({required this.name, required this.date, required this.leg, required this.sharePaid});

  final String name;
  final CalendarDate date;
  final Leg leg;

  /// Paid directly to the driver; Goora's fee is 0 for a covered employee.
  final int sharePaid;
}
