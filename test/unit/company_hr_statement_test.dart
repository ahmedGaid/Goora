import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/domain/enrollment.dart';
import 'package:goora/features/company/domain/hr_statement.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

// 010 T046 (US6, FR-024–FR-028, SC-008, Q7) on the pure rules and on the real
// fake over shared_preferences — no mocks.

WallTime _at(int y, int m, int d, [int h = 0, int min = 0]) => WallTime(CalendarDate(y, m, d), Clock.hm(h, min));

/// Tue 20 Oct 2026, 10:00: Valeo's seed was approved on 1 Aug 2026, so Aug and
/// Sep are closed months.
final _start = _at(2026, 10, 20, 10);

const _people = <String, ({String name, String? workEmail})>{
  'ahmed': (name: 'Ahmed', workEmail: 'ahmed@valeo.com'),
  'sara': (name: 'Sara', workEmail: 'sara@valeo.com'),
};

TripShare _share(
  String personId,
  CalendarDate date, {
  Leg leg = Leg.going,
  int amount = 40,
  ShareStatus status = ShareStatus.received,
  bool asRider = true,
}) => TripShare(personId: personId, date: date, leg: leg, sharePaid: amount, status: status, asRider: asRider);

Enrollment _enr(String personId, String name, WallTime at, {WallTime? leftAt}) => Enrollment(
  personId: personId,
  companyId: CompanySeed.valeoId,
  name: name,
  workEmail: '$personId@valeo.com',
  enrolledAt: at,
  leftAt: leftAt,
  leftWhy: leftAt == null ? null : LeftWhy.self,
);

Future<FakeCompanyRepository> _repo({List<TripShare> shares = const [], TestClock? clock}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = clock ?? TestClock(_start);
  return FakeCompanyRepository(
    prefs,
    person: (id) async => _people[id],
    now: c.call,
    shares: (companyId, month) async => shares,
  );
}

void main() {
  group('consent history (pure)', () {
    final history = [
      ConsentChange(on: true, at: _at(2026, 9, 10, 9)),
      ConsentChange(on: false, at: _at(2026, 10, 15, 9)),
    ];

    test('off with no history; on from the moment it was turned on; off from the moment it was withdrawn', () {
      expect(HrStatement.consentOn(const [], _at(2026, 9, 30)), isFalse);
      expect(HrStatement.consentOn(history, _at(2026, 9, 10, 8, 59)), isFalse);
      expect(HrStatement.consentOn(history, _at(2026, 9, 10, 9)), isTrue);
      expect(HrStatement.consentOn(history, _at(2026, 10, 15, 8, 59)), isTrue);
      expect(HrStatement.consentOn(history, _at(2026, 10, 15, 9)), isFalse);
    });

    test('a month ends at 00:00 on the 1st of the next', () {
      expect(HrStatement.monthEnd('2026-09'), _at(2026, 10, 1));
      expect(HrStatement.monthEnd('2026-12'), _at(2027, 1, 1));
    });
  });

  group('statement lines (pure)', () {
    final aug1 = _at(2026, 8, 1, 9, 10);
    final enrolled = [_enr('a', 'Aya', aug1), _enr('b', 'Basem', aug1)];

    test('only employees whose consent was on at the end of the month; the others are absent entirely', () {
      final lines = HrStatement.build(
        month: '2026-09',
        enrollments: enrolled,
        consent: {
          'a': [ConsentChange(on: true, at: _at(2026, 9, 2))],
        },
        shares: [_share('a', CalendarDate(2026, 9, 6)), _share('b', CalendarDate(2026, 9, 6))],
      );
      expect(lines.map((l) => l.name), ['Aya']);
    });

    test('consent turned on only after the month ended leaves that month out', () {
      final lines = HrStatement.build(
        month: '2026-09',
        enrollments: enrolled,
        consent: {
          'a': [ConsentChange(on: true, at: _at(2026, 10, 1, 0, 1))],
        },
        shares: [_share('a', CalendarDate(2026, 9, 6))],
      );
      expect(lines, isEmpty);
    });

    test('rider trips only: a trip driven by the employee is not on the statement', () {
      final lines = HrStatement.build(
        month: '2026-09',
        enrollments: enrolled,
        consent: {
          'a': [ConsentChange(on: true, at: _at(2026, 9, 2))],
        },
        shares: [_share('a', CalendarDate(2026, 9, 6)), _share('a', CalendarDate(2026, 9, 7), asRider: false)],
      );
      expect(lines, hasLength(1));
      expect(lines.single.date, CalendarDate(2026, 9, 6));
    });

    test('only received and auto-received shares count (Q7); pending, not received and disputed never do', () {
      final lines = HrStatement.build(
        month: '2026-09',
        enrollments: enrolled,
        consent: {
          'a': [ConsentChange(on: true, at: _at(2026, 9, 2))],
        },
        shares: [for (final (i, s) in ShareStatus.values.indexed) _share('a', CalendarDate(2026, 9, 6 + i), status: s)],
      );
      expect(lines.map((l) => l.date.day), [6 + ShareStatus.received.index, 6 + ShareStatus.autoReceived.index]);
    });

    test('only that month\'s trips; sorted by name, then date, then going before return', () {
      final both = {
        'a': [ConsentChange(on: true, at: _at(2026, 9, 2))],
        'b': [ConsentChange(on: true, at: _at(2026, 9, 2))],
      };
      final lines = HrStatement.build(
        month: '2026-09',
        enrollments: enrolled,
        consent: both,
        shares: [
          _share('b', CalendarDate(2026, 9, 3)),
          _share('a', CalendarDate(2026, 9, 7), leg: Leg.ret),
          _share('a', CalendarDate(2026, 9, 7)),
          _share('a', CalendarDate(2026, 9, 6)),
          _share('a', CalendarDate(2026, 8, 31)),
          _share('a', CalendarDate(2026, 10, 1)),
        ],
      );
      expect(
        [for (final l in lines) (l.name, l.date.day, l.leg)],
        [('Aya', 6, Leg.going), ('Aya', 7, Leg.going), ('Aya', 7, Leg.ret), ('Basem', 3, Leg.going)],
      );
    });

    test('an employee who left the company before the month ended is not on it, consent or not', () {
      final left = _enr('a', 'Aya', aug1, leftAt: _at(2026, 9, 20));
      final lines = HrStatement.build(
        month: '2026-09',
        enrollments: [left],
        consent: {
          'a': [ConsentChange(on: true, at: _at(2026, 9, 2))],
        },
        shares: [_share('a', CalendarDate(2026, 9, 6))],
      );
      expect(lines, isEmpty);
    });

    test('the line carries the paid share as it was', () {
      final lines = HrStatement.build(
        month: '2026-09',
        enrollments: enrolled,
        consent: {
          'a': [ConsentChange(on: true, at: _at(2026, 9, 2))],
        },
        shares: [_share('a', CalendarDate(2026, 9, 6), amount: 45)],
      );
      expect(lines.single.sharePaid, 45);
    });
  });

  group('FakeCompanyRepository HR consent and statement (T047)', () {
    test('off by default, and for someone who is not enrolled', () async {
      final r = await _repo();
      expect(await r.hrConsent('ahmed'), isFalse);
      await r.enroll('ahmed', now: _start);
      expect(await r.hrConsent('ahmed'), isFalse);
    });

    test('setHrConsent needs an open enrollment', () async {
      final r = await _repo();
      expect(() => r.setHrConsent('ahmed', true, _start), throwsStateError);
    });

    test('on, then off; saying the same thing twice writes nothing new', () async {
      final r = await _repo();
      await r.enroll('ahmed', now: _start);
      await r.setHrConsent('ahmed', true, _start.plusMinutes(1));
      await r.setHrConsent('ahmed', true, _start.plusMinutes(2));
      expect(await r.hrConsent('ahmed'), isTrue);
      await r.setHrConsent('ahmed', false, _start.plusMinutes(3));
      await r.setHrConsent('ahmed', false, _start.plusMinutes(4));
      expect(await r.hrConsent('ahmed'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      final key = FakeCompanyRepository.hrConsentKey(CompanySeed.valeoId, 'ahmed');
      expect(prefs.getString(key), isNotNull);
      expect(HrStatement.historyFromJson(prefs.getString(key)!), hasLength(2));
    });

    test('leaving ends it; joining again starts from off, never from the old yes', () async {
      final r = await _repo();
      await r.enroll('ahmed', now: _start);
      await r.setHrConsent('ahmed', true, _start.plusMinutes(1));
      await r.leave('ahmed', now: _start.plusMinutes(2));
      expect(await r.hrConsent('ahmed'), isFalse);
      await r.enroll('ahmed', now: _start.plusMinutes(3));
      expect(await r.hrConsent('ahmed'), isFalse);
    });

    test('statement of a consenting employee lists only their paid rider shares of that month', () async {
      final clock = TestClock(_at(2026, 9, 4, 10));
      final r = await _repo(
        clock: clock,
        shares: [
          _share('ahmed', CalendarDate(2026, 9, 6)),
          _share('ahmed', CalendarDate(2026, 9, 7), status: ShareStatus.notReceived),
          _share('sara', CalendarDate(2026, 9, 6)),
        ],
      );
      await r.enroll('ahmed', now: clock.now);
      await r.enroll('sara', now: clock.now);
      await r.setHrConsent('ahmed', true, clock.now);
      clock.now = _at(2026, 10, 3, 9);
      final lines = await r.statement(CompanySeed.valeoId, '2026-09', clock.now);
      expect([for (final l in lines) l.name], ['Ahmed']);
      expect(lines.single.date, CalendarDate(2026, 9, 6));
    });

    test('withdrawing leaves later months out and the issued month as it was (SC-008)', () async {
      final clock = TestClock(_at(2026, 9, 4, 10));
      final r = await _repo(
        clock: clock,
        shares: [_share('ahmed', CalendarDate(2026, 9, 6)), _share('ahmed', CalendarDate(2026, 10, 6))],
      );
      await r.enroll('ahmed', now: clock.now);
      await r.setHrConsent('ahmed', true, clock.now);
      clock.now = _at(2026, 10, 3, 9);
      final issued = await r.statement(CompanySeed.valeoId, '2026-09', clock.now);
      expect(issued, hasLength(1));

      clock.now = _at(2026, 10, 15, 9);
      await r.setHrConsent('ahmed', false, clock.now);
      clock.now = _at(2026, 11, 2, 9);
      final again = await r.statement(CompanySeed.valeoId, '2026-09', clock.now);
      expect(
        [for (final l in again) (l.name, l.date, l.leg, l.sharePaid)],
        [for (final l in issued) (l.name, l.date, l.leg, l.sharePaid)],
      );
      expect(await r.statement(CompanySeed.valeoId, '2026-10', clock.now), isEmpty);
    });

    test('a month that has not ended has no statement yet', () async {
      final clock = TestClock(_at(2026, 10, 20, 10));
      final r = await _repo(clock: clock, shares: [_share('ahmed', CalendarDate(2026, 10, 6))]);
      await r.enroll('ahmed', now: _at(2026, 10, 1, 9));
      await r.setHrConsent('ahmed', true, _at(2026, 10, 1, 9));
      expect(await r.statement(CompanySeed.valeoId, '2026-10', clock.now), isEmpty);
    });

    test('the seed: three Valeo riders agreed; one withdrew in September, so Aug has her and Sep not', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final r = FakeCompanyRepository(prefs, person: (id) async => null, now: () => _start);
      final aug = await r.statement(CompanySeed.valeoId, '2026-08', _start);
      final sep = await r.statement(CompanySeed.valeoId, '2026-09', _start);
      expect(aug.map((l) => l.name).toSet(), {'Dina Samir', 'Hossam Nabil', 'Yasmin Fouad'});
      expect(sep.map((l) => l.name).toSet(), {'Dina Samir', 'Hossam Nabil'});
      // The seed's driver agreed too, but a driver pays no share: nothing of him.
      expect(aug.map((l) => l.name), isNot(contains('Karim Fawzy')));
      // Hossam's not-received, disputed and pending shares stay off.
      expect(sep.where((l) => l.name == 'Hossam Nabil'), hasLength(CompanySeed.hossamPaidShares));
    });
  });

  group('what HR gets (constitution IV)', () {
    test('a statement line has exactly name, date, leg and share paid', () {
      final source = File('lib/features/company/domain/hr_views.dart').readAsStringSync();
      final start = source.indexOf('final class StatementLine');
      final body = source.substring(start);
      final names = [
        for (final m in RegExp(r'^\s*final\s+[\w<>?(), ]+\s+(\w+);', multiLine: true).allMatches(body)) m.group(1)!,
      ];
      expect(names, ['name', 'date', 'leg', 'sharePaid']);
    });

    test('the export flag stays off until the lawyer answers (constitution VIII)', () {
      expect(File('lib/features/company/company_flags.dart').readAsStringSync(), contains('hrStatementExport = false'));
    });
  });
}
