import '../../../core/time/calendar_date.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/place.dart';
import 'company_rules.dart';
import 'employee_month_facts.dart';
import 'hr_views.dart';

/// Estimate constants for the dashboard (research R7). Labelled "estimate" in
/// the app, each with a one-line method.
abstract final class CompanyDashboardTerms {
  /// kg CO₂e per km, average petrol car: UK government (DESNZ/DEFRA) GHG
  /// conversion factors 2024 (0.1645). Egypt's fleet differs, so it is an
  /// estimate.
  static const co2KgPerKm = 0.1645;
}

/// The dashboard's pure aggregator (research R6, R7). It receives per-person
/// month facts and returns totals only; the k = 5 suppression is applied
/// here, before anything reaches presentation (FR-022, FR-023).
abstract final class CompanyDashboard {
  /// One month of totals. A figure is null ("fewer than 5") when fewer than
  /// [CompanyRules.suppressBelow] people it is built from.
  static DashboardMonth build({
    required String month,
    required bool soFar,
    required List<EmployeeMonthFacts> facts,
    required int workdays,
  }) {
    final active = facts.where((f) => f.isActive).toList();
    final riders = facts.where((f) => f.riderTrips > 0).toList();
    final goingRiders = facts.where((f) => f.riderGoingTrips > 0).toList();
    final grouped = facts.where((f) => f.groupIds.isNotEmpty || f.hasGroup).toList();

    final enrolled = CompanyRules.suppress(facts.length);
    final activeCount = CompanyRules.suppress(active.length);

    int? carpool;
    if (enrolled != null && activeCount != null && facts.isNotEmpty) {
      carpool = (active.length * 100 / facts.length).round();
    }

    int? groups;
    if (CompanyRules.suppress(grouped.length) != null) {
      groups = {for (final f in grouped) ...f.groupIds}.length;
    }

    int? tripsShared;
    if (activeCount != null) {
      tripsShared = {for (final f in active) ...f.legIds}.length;
    }

    int? moneySaved;
    int? co2Kg;
    if (CompanyRules.suppress(riders.length) != null) {
      moneySaved = riders.fold<int>(0, (a, f) => a + f.savedEgp);
      final km = riders.fold<int>(0, (a, f) => a + f.km);
      co2Kg = (km * CompanyDashboardTerms.co2KgPerKm).round();
    }

    int? parking;
    if (CompanyRules.suppress(goingRiders.length) != null && workdays > 0) {
      parking = goingRiders.fold<int>(0, (a, f) => a + f.riderGoingTrips) ~/ workdays;
    }

    return DashboardMonth(
      month: month,
      soFar: soFar,
      enrolled: enrolled,
      active: activeCount,
      carpoolRatePct: carpool,
      groups: groups,
      tripsShared: tripsShared,
      moneySaved: moneySaved,
      co2Kg: co2Kg,
      parkingPerDay: parking,
      routeGaps: _routeGaps(facts),
    );
  }

  /// Home areas with at least 5 employees who set a commute and are in no
  /// group. Smaller areas are left out entirely (FR-022). Biggest first.
  static List<(Area, int)> _routeGaps(List<EmployeeMonthFacts> facts) {
    final count = <Area, int>{};
    for (final f in facts) {
      if (f.hasProfile && !f.hasGroup) count.update(f.homeArea, (n) => n + 1, ifAbsent: () => 1);
    }
    final out = [
      for (final e in count.entries)
        if (CompanyRules.suppress(e.value) != null) (e.key, e.value),
    ]..sort((a, b) {
        final byCount = b.$2.compareTo(a.$2);
        return byCount != 0 ? byCount : a.$1.index.compareTo(b.$1.index);
      });
    return out;
  }

  /// Sun–Thu days in [month] (`yyyy-mm`), counted up to [through] when the
  /// month is still running (so "per workday" is not diluted by days that
  /// have not happened yet).
  static int workdaysIn(String month, {CalendarDate? through}) {
    final parts = month.split('-').map(int.parse).toList();
    final first = CalendarDate(parts[0], parts[1], 1);
    final last = first.addMonths(1).addDays(-1);
    final end = through != null && through.isBefore(last) ? through : last;
    var n = 0;
    for (var d = first; !d.isAfter(end); d = d.addDays(1)) {
      final w = d.weekday;
      if (w != Day.fri && w != Day.sat) n++;
    }
    return n;
  }

  /// The months HR can pick: the running month ("so far") first, then every
  /// closed month back to the month the contract started (FR-021).
  static List<({String month, bool soFar})> months(CalendarDate contractStart, CalendarDate today) {
    final first = CalendarDate(contractStart.year, contractStart.month, 1);
    final out = <({String month, bool soFar})>[];
    var m = CalendarDate(today.year, today.month, 1);
    var running = true;
    while (!m.isBefore(first)) {
      out.add((month: m.monthKey, soFar: running));
      running = false;
      m = m.addMonths(-1);
    }
    return out;
  }
}
