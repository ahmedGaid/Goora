import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/domain/company.dart';
import 'package:goora/features/company/domain/company_log.dart';
import 'package:goora/features/company/domain/company_repository.dart';
import 'package:goora/features/company/domain/invoice.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

/// 010 T032 (US3; FR-015, SC-006): an employee's company plan stops covering
/// trips from 00:00 on due + 8 when the invoice is unpaid, the fee shows on
/// that day's trip, paying brings coverage back from that moment, and trips
/// taken in the gap keep their fee. On the real fake, no mocks.
WallTime _at(int y, int m, int d, [int h = 0, int min = 0]) => WallTime(CalendarDate(y, m, d), Clock.hm(h, min));

/// October is issued 1 Nov, due 16 Nov, suspended from 24 Nov 00:00.
final _oct20 = _at(2026, 10, 20, 10);
final _beforeSuspension = _at(2026, 11, 23, 23, 59);
final _suspendedAt = _at(2026, 11, 24);

Future<({FakeCompanyRepository repo, TestClock clock})> _world() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final clock = TestClock(_oct20);
  final repo = FakeCompanyRepository(
    prefs,
    person: (id) async => id == 'ahmed' ? (name: 'Ahmed', workEmail: 'ahmed@valeo.com') : null,
    now: clock.call,
  );
  await repo.enroll('ahmed', now: _oct20);
  return (repo: repo, clock: clock);
}

/// The wallet attaches these windows to the person's company plan.
Future<Plan> _planAt(FakeCompanyRepository repo, WallTime now) async => Plan(
      personId: 'ahmed',
      type: PlanType.company,
      status: PlanStatus.active,
      price: 0,
      startDate: _oct20,
    ).withCoverage(await repo.coverageFor('ahmed', now));

void main() {
  test('the day before suspension the company plan still covers a trip', () async {
    final w = await _world();
    final plan = await _planAt(w.repo, _beforeSuspension);
    expect(plan.coversTrip(_beforeSuspension), isTrue);
  });

  test('a trip on the 24th carries the fee: covered one minute before, not at 00:00', () async {
    final w = await _world();
    final plan = await _planAt(w.repo, _at(2026, 11, 24, 7, 15));
    expect(plan.coversTrip(_beforeSuspension), isTrue);
    expect(plan.coversTrip(_suspendedAt), isFalse);
    expect(plan.coversTrip(_at(2026, 11, 24, 7, 15)), isFalse);
    // The employee is still enrolled; only the company's coverage paused.
    expect(await w.repo.offerFor('ahmed', _at(2026, 11, 24, 7, 15)), isA<Enrolled>());
  });

  test('the company shows suspended to HR and is still approved for enrolling', () async {
    final w = await _world();
    final home = await w.repo.myCompanyAccount(CompanySeed.valeoHrId, _at(2026, 11, 24, 7, 15));
    expect(home!.status, CompanyStatus.suspended);
  });

  test('paid at 09:00 on the 25th: covered from that moment, the gap trips keep their fee', () async {
    final w = await _world();
    final late = _at(2026, 11, 25, 9);
    final october = (await w.repo.invoices(CompanySeed.valeoId, late)).firstWhere((i) => i.month == '2026-10');
    expect(october.statusAt(late), InvoiceStatus.overdue);
    await w.repo.demoMarkPaid(october.id, bankRef: 'TX-1', now: late);

    final after = _at(2026, 11, 25, 9, 1);
    final plan = await _planAt(w.repo, after);
    expect(plan.coversTrip(after), isTrue);
    expect(plan.coversTrip(_at(2026, 11, 24, 7, 15)), isFalse, reason: 'a fee already charged stays');
    expect(plan.coversTrip(_at(2026, 11, 25, 8, 59)), isFalse);
    final home = await w.repo.myCompanyAccount(CompanySeed.valeoHrId, after);
    expect(home!.status, CompanyStatus.active);
  });

  test('suspension and resume are each logged once, by Goora', () async {
    final w = await _world();
    final late = _at(2026, 11, 25, 9);
    final october = (await w.repo.invoices(CompanySeed.valeoId, late)).firstWhere((i) => i.month == '2026-10');
    await w.repo.demoMarkPaid(october.id, bankRef: 'TX-1', now: late);
    await w.repo.invoices(CompanySeed.valeoId, late);
    final log = await w.repo.log(CompanySeed.valeoId);
    expect(log.where((e) => e.kind == LogKind.suspended).map((e) => e.at), [_suspendedAt]);
    expect(log.where((e) => e.kind == LogKind.resumed).map((e) => e.at), [late]);
  });

  test('an invoice paid before the 24th never suspends', () async {
    final w = await _world();
    final onTime = _at(2026, 11, 20, 9);
    final october = (await w.repo.invoices(CompanySeed.valeoId, onTime)).firstWhere((i) => i.month == '2026-10');
    await w.repo.demoMarkPaid(october.id, bankRef: 'TX-1', now: onTime);
    final plan = await _planAt(w.repo, _at(2026, 11, 24, 7, 15));
    expect(plan.coversTrip(_at(2026, 11, 24, 7, 15)), isTrue);
  });
}
