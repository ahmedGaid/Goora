import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/domain/company_dashboard.dart';
import 'package:goora/features/company/domain/employee_month_facts.dart';

/// 010 T041 (US5; FR-021, FR-022; research R6, R7): the dashboard aggregator
/// turns per-person month facts into totals, and any figure built from fewer
/// than 5 people becomes null ("fewer than 5").
EmployeeMonthFacts _idle(String id, {Area home = Area.sheikhZayed, bool profile = true, bool group = false}) =>
    EmployeeMonthFacts(
      personId: id,
      riderTrips: 0,
      riderGoingTrips: 0,
      driverTrips: 0,
      savedEgp: 0,
      km: 0,
      homeArea: home,
      hasProfile: profile,
      hasGroup: group,
    );

EmployeeMonthFacts _rider(String id, int trips, {Set<String> legs = const {}, String? group}) => EmployeeMonthFacts(
      personId: id,
      riderTrips: trips,
      riderGoingTrips: trips ~/ 2,
      driverTrips: 0,
      savedEgp: trips * 120,
      km: trips * 10,
      homeArea: Area.sheikhZayed,
      hasProfile: true,
      hasGroup: group != null,
      groupIds: group == null ? const [] : [group],
      legIds: legs,
    );

void main() {
  group('Valeo seed month (12 enrolled, 8 active)', () {
    final m = CompanyDashboard.build(month: '2026-10', soFar: false, facts: CompanySeed.valeoFacts, workdays: 21);

    test('headcount figures', () {
      expect(m.enrolled, 12);
      expect(m.active, 8);
      expect(m.carpoolRatePct, 67); // 8 ÷ 12
      expect(m.groups, 2);
    });

    test('trips shared count each leg once, however many employees rode', () {
      expect(m.tripsShared, 76); // 40 + 36 legs; riders share the drivers' legs
    });

    test('money saved = Σ (leg cost − share); CO₂ = Σ km × factor; parking = going trips ÷ workdays', () {
      expect(m.moneySaved, 132 * 120);
      expect(m.co2Kg, (132 * CompanySeed.legKm * CompanyDashboardTerms.co2KgPerKm).round());
      expect(m.parkingPerDay, 66 ~/ 21);
    });

    test('route gap of 3 waiting is not listed', () {
      expect(m.routeGaps, isEmpty);
    });
  });

  group('suppression (k = 5)', () {
    test('3 active: every figure built on active people is null; enrolled stays', () {
      final facts = [
        _rider('a', 10, legs: {'l1', 'l2'}, group: 'g1'),
        _rider('b', 10, legs: {'l1', 'l2'}, group: 'g1'),
        _rider('c', 10, legs: {'l1', 'l2'}, group: 'g1'),
        for (var i = 0; i < 9; i++) _idle('x$i'),
      ];
      final m = CompanyDashboard.build(month: '2026-10', soFar: false, facts: facts, workdays: 21);
      expect(m.enrolled, 12);
      expect(m.active, isNull);
      expect(m.carpoolRatePct, isNull);
      expect(m.groups, isNull);
      expect(m.tripsShared, isNull);
      expect(m.moneySaved, isNull);
      expect(m.co2Kg, isNull);
      expect(m.parkingPerDay, isNull);
    });

    test('exactly 5 active shows numbers; 4 does not', () {
      List<EmployeeMonthFacts> withActive(int n) => [
            for (var i = 0; i < n; i++) _rider('r$i', 4, legs: {'l$i'}, group: 'g'),
            for (var i = 0; i < 6; i++) _idle('x$i'),
          ];
      expect(CompanyDashboard.build(month: '2026-10', soFar: false, facts: withActive(5), workdays: 21).active, 5);
      expect(CompanyDashboard.build(month: '2026-10', soFar: false, facts: withActive(4), workdays: 21).active, isNull);
    });

    test('fewer than 5 enrolled hides even the headcount', () {
      final m = CompanyDashboard.build(month: '2026-10', soFar: false, facts: [_idle('a'), _idle('b')], workdays: 21);
      expect(m.enrolled, isNull);
    });

    test('route-gap area: 5 waiting listed, 4 not', () {
      List<EmployeeMonthFacts> waiting(int n, Area a) => [for (var i = 0; i < n; i++) _idle('w${a.name}$i', home: a)];
      final m = CompanyDashboard.build(
        month: '2026-10',
        soFar: false,
        facts: [...waiting(5, Area.october), ...waiting(4, Area.newCairo), _idle('np', profile: false)],
        workdays: 21,
      );
      expect(m.routeGaps, [(Area.october, 5)]);
    });
  });

  group('months and workdays', () {
    test('Sun–Thu workdays in a month and up to a date', () {
      expect(CompanyDashboard.workdaysIn('2026-10'), 21);
      expect(CompanyDashboard.workdaysIn('2026-10', through: CalendarDate(2026, 10, 8)), 6);
      expect(CompanyDashboard.workdaysIn('2026-10', through: CalendarDate(2026, 10, 3)), 1);
    });

    test('month list = current so far, then closed months back to the contract start', () {
      final list = CompanyDashboard.months(CalendarDate(2026, 8, 1), CalendarDate(2026, 10, 29));
      expect(list, [(month: '2026-10', soFar: true), (month: '2026-09', soFar: false), (month: '2026-08', soFar: false)]);
    });

    test('contract starting this month lists only the running month', () {
      final list = CompanyDashboard.months(CalendarDate(2026, 10, 1), CalendarDate(2026, 10, 2));
      expect(list, [(month: '2026-10', soFar: true)]);
    });
  });
}
