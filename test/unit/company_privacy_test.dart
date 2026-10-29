import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/domain/company_dashboard.dart';

/// 010 T042 (SC-005, FR-023, constitution IV): what the HR contact reads has
/// no person id, group, pickup, time, share or role field, and the dashboard
/// built from the seed carries no seeded name, email or person id.
String _classSource(String source, String className) {
  final start = source.indexOf('final class $className');
  expect(start, greaterThanOrEqualTo(0), reason: '$className not found');
  final end = source.indexOf('\nfinal class', start + 1);
  return source.substring(start, end == -1 ? source.length : end);
}

List<String> _names(String classSource) => [
      for (final m in RegExp(r'^\s*final\s+[\w<>?(), ]+\s+(\w+);', multiLine: true).allMatches(classSource))
        m.group(1)!,
    ];

void main() {
  final source = File('lib/features/company/domain/hr_views.dart').readAsStringSync();

  test('RosterRow fields are exactly name, email, enrolled, left', () {
    expect(_names(_classSource(source, 'RosterRow')), ['name', 'workEmail', 'enrolledAt', 'leftAt']);
  });

  test('DashboardMonth fields are totals only', () {
    final names = _names(_classSource(source, 'DashboardMonth'));
    expect(names, [
      'month',
      'soFar',
      'enrolled',
      'active',
      'carpoolRatePct',
      'groups',
      'tripsShared',
      'moneySaved',
      'co2Kg',
      'parkingPerDay',
      'routeGaps',
    ]);
    final forbidden = RegExp(r'person|groupId|groupName|pickup|stop|sharePaid|shareStatus|role|driver|email|name', caseSensitive: false);
    for (final n in names) {
      expect(forbidden.hasMatch(n), isFalse, reason: 'field "$n" looks individual');
    }
  });

  test('the seed dashboard shows no seeded name, email or person id', () {
    final m = CompanyDashboard.build(month: '2026-10', soFar: false, facts: CompanySeed.valeoFacts, workdays: 21);
    final shown = [
      m.month,
      m.soFar,
      m.enrolled,
      m.active,
      m.carpoolRatePct,
      m.groups,
      m.tripsShared,
      m.moneySaved,
      m.co2Kg,
      m.parkingPerDay,
      m.routeGaps,
    ].join('|');
    final at = WallTime(CalendarDate(2026, 8, 1), const Clock.hm(9, 0));
    for (final e in CompanySeed.valeoEnrollments(at)) {
      expect(shown.contains(e.name), isFalse);
      expect(shown.contains(e.workEmail), isFalse);
      expect(shown.contains(e.personId), isFalse);
    }
  });
}
