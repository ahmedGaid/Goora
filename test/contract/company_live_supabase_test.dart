import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/company/data/supabase_company_repository.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';

import 'support/in_memory_gateway.dart';
import 'support/server.dart';
import 'support/tables.dart';

/// 013 D11, D12: coverage cut by suspensions, the dashboard's extra totals, reset, and the
/// staff buttons that do nothing on the real backend. The SQL behind each is in
/// supabase/tests/70_company_live.test.sql.
final _now = WallTime(CalendarDate(2026, 11, 2), const Clock.hm(9, 0));
const _company = 'co-1';

int _minute(String wall) => SharePolicy.minuteOf(WallTime.fromJson(wall));

Future<({InMemoryGateway db, SupabaseCompanyRepository repo, String me})> _world({String? approvedAt}) async {
  final db = InMemoryGateway(keys: tableKeys);
  installCompanyServer(db, wall: _now.toJson());
  final me = await signUpPerson(
    db,
    Profile(phone: PhoneNumber.tryParse('01001234567')!, firstName: 'Mona', lastName: 'K', gender: Gender.female),
    workEmail: 'mona@acme-k.eg',
  );
  db.table('companies').add({
    'id': _company,
    'name': 'Acme K',
    'status': 'active',
    'hr_contact_id': 'someone-else',
    'approved_at': approvedAt,
    'ended_at': null,
    'minimum_seats': 20,
    'price_per_seat': 99,
  });
  db.table('enrollments').add({
    'id': 'en-1',
    'company_id': _company,
    'person_id': me,
    'name': 'Mona K',
    'work_email': 'mona@acme-k.eg',
    'enrolled_at': '2026-01-02T09:00:00',
    'left_at': null,
    'left_why': null,
  });
  return (db: db, repo: SupabaseCompanyRepository(db), me: me);
}

void _invoice(InMemoryGateway db, {required String dueOn, String? paidAt}) => db.table('invoices').add({
  'id': 'inv-$dueOn',
  'company_id': _company,
  'due_on': dueOn,
  'paid_at': paidAt,
});

void main() {
  test('CS1 an unpaid invoice past its suspension day ends coverage on that day', () async {
    final w = await _world(approvedAt: '2026-01-01T09:00:00');
    _invoice(w.db, dueOn: '2026-10-01'); // due 1 Oct + 7 days of grace → suspended from 9 Oct
    final windows = await w.repo.coverageFor(w.me, _now);
    expect(windows, [(from: _minute('2026-01-02T09:00:00'), to: _minute('2026-10-09T00:00:00'))]);
  });

  test('CS2 paying late brings coverage back from the payment', () async {
    final w = await _world(approvedAt: '2026-01-01T09:00:00');
    _invoice(w.db, dueOn: '2026-10-01', paidAt: '2026-10-20T10:00:00');
    final windows = await w.repo.coverageFor(w.me, _now);
    expect(windows, [
      (from: _minute('2026-01-02T09:00:00'), to: _minute('2026-10-09T00:00:00')),
      (from: _minute('2026-10-20T10:00:00'), to: null),
    ]);
  });

  test('CS3 an invoice whose suspension day has not come cuts nothing', () async {
    final w = await _world(approvedAt: '2026-01-01T09:00:00');
    _invoice(w.db, dueOn: '2026-10-30'); // suspended from 7 Nov, after "now"
    final windows = await w.repo.coverageFor(w.me, _now);
    expect(windows, [(from: _minute('2026-01-02T09:00:00'), to: null)]);
  });

  test('CS4 a company Goora has not approved covers nobody', () async {
    final w = await _world();
    expect(await w.repo.coverageFor(w.me, _now), isEmpty);
  });

  test('CS5 the dashboard maps money, CO2, parking and route gaps; withheld arrive as null', () async {
    final w = await _world();
    w.db.rpcs['company_dashboard'] = (p, db) => {
      'month': p['p_month'],
      'enrolled': 6,
      'active': 5,
      'carpoolRatePct': 83,
      'tripsShared': 12,
      'groups': 2,
      'moneySaved': 600,
      'co2Kg': 101,
      'parkingPerDay': null,
      'routeGaps': [
        {'area': 'nasrCity', 'count': 5},
        {'area': 'newCairo', 'count': 7},
        {'area': 'heliopolis', 'count': 5},
      ],
    };
    final m = await w.repo.dashboard(_company, '2026-11', _now);
    expect((m.moneySaved, m.co2Kg, m.parkingPerDay), (600, 101, null));
    // Biggest first; equal counts in the order the areas are declared.
    expect(m.routeGaps, [(Area.newCairo, 7), (Area.nasrCity, 5), (Area.heliopolis, 5)]);
  });

  test('CS6 reset removes the signed-in person\'s own rows and no others', () async {
    final w = await _world();
    w.db.table('enrollments').add({
      'id': 'en-2',
      'company_id': _company,
      'person_id': 'other',
      'name': 'Sara K',
      'work_email': 'sara@acme-k.eg',
      'enrolled_at': '2026-01-02T09:00:00',
    });
    w.db.table('hr_consents').addAll([
      {'person_id': w.me, 'on': true},
      {'person_id': 'other', 'on': true},
    ]);
    w.db.table('companies').add({'id': 'mine-pending', 'name': 'Mine', 'status': 'pending', 'hr_contact_id': w.me});
    await w.repo.clearAll();
    expect([for (final e in w.db.table('enrollments')) e['person_id']], ['other']);
    expect([for (final c in w.db.table('hr_consents')) c['person_id']], ['other']);
    expect([for (final c in w.db.table('companies')) c['id']], [_company]);
  });

  test('CS7 the staff demo buttons do nothing on the real backend', () async {
    final w = await _world();
    await w.repo.demoApprove(_company, _now);
    await w.repo.demoMarkPaid('inv-1', bankRef: 'X', now: _now);
    await w.repo.demoSetHrContact(_company, null, _now);
    await w.repo.demoEndContract(_company, _now);
    expect(w.db.calls, isEmpty);
  });
}
