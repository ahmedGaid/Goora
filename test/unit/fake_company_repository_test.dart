import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/domain/company.dart';
import 'package:goora/features/company/domain/company_log.dart';
import 'package:goora/features/company/domain/company_repository.dart';
import 'package:goora/features/company/domain/enrollment.dart';
import 'package:goora/features/company/domain/invoice.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

// 010 T015 on the real fake over shared_preferences — no mocks.

WallTime _at(int y, int m, int d, [int h = 0, int min = 0]) => WallTime(CalendarDate(y, m, d), Clock.hm(h, min));
int _m(WallTime t) => SharePolicy.minuteOf(t);

/// Tue 20 Oct 2026, 10:00: the seed's Valeo was approved on 1 Aug 2026.
final _start = _at(2026, 10, 20, 10);

/// People outside the seed, as Trust and the profile would give them.
const _people = <String, ({String name, String? workEmail})>{
  'ahmed': (name: 'Ahmed', workEmail: 'ahmed@valeo.com'),
  'sara': (name: 'Sara', workEmail: 'sara@valeo.eg'),
  'nour': (name: 'Nour', workEmail: 'nour@orange.com'),
  'omar': (name: 'Omar', workEmail: 'omar@acme.eg'),
  'laila': (name: 'Laila', workEmail: null),
};

final class _World {
  _World(this.repo, this.prefs, this.clock);

  final FakeCompanyRepository repo;
  final SharedPreferences prefs;
  final TestClock clock;

  WallTime get now => clock.now;
}

Future<_World> _world({Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final clock = TestClock(_start);
  final repo = FakeCompanyRepository(p, person: (id) async => _people[id], now: clock.call);
  return _World(repo, p, clock);
}

Future<List<LogEntry>> _logOf(_World w, LogKind kind, {String companyId = CompanySeed.valeoId}) async =>
    (await w.repo.log(companyId)).where((e) => e.kind == kind).toList();

void main() {
  group('seed (T016, research R10)', () {
    test('Valeo active since the 1st two months back, 12 enrolled; Orange Business pending', () async {
      final w = await _world();
      final valeo = await w.repo.companyForDomain('valeo.com');
      expect(valeo!.name, 'Valeo');
      expect(valeo.status, CompanyStatus.active);
      expect(valeo.approvedAt!.date, CalendarDate(2026, 8, 1));
      expect(valeo.contractEnd, CalendarDate(2027, 8, 1));
      expect(valeo.minimumSeats, 20);
      expect(valeo.pricePerSeat, 99);
      final orange = await w.repo.companyForDomain('ORANGE.com');
      expect(orange!.status, CompanyStatus.pending);
      final roster = await w.repo.roster(CompanySeed.valeoId, w.now);
      expect(roster, hasLength(12));
      expect(roster.every((r) => r.workEmail.endsWith('@valeo.com') && r.leftAt == null), isTrue);
    });

    test('month facts: 8 active, one route-gap area of 3 waiting (below 5)', () {
      final facts = CompanySeed.valeoFacts;
      expect(facts, hasLength(12));
      expect(facts.where((f) => f.riderTrips + f.driverTrips > 0), hasLength(8));
      final waiting = facts.where((f) => f.hasProfile && !f.hasGroup).toList();
      expect(waiting, hasLength(3));
      expect(waiting.map((f) => f.homeArea).toSet(), {Area.october});
    });

    test('closed months before the seed are invoiced and paid, so Valeo is not suspended', () async {
      final w = await _world();
      final invoices = await w.repo.invoices(CompanySeed.valeoId, w.now);
      expect(invoices.map((i) => i.month), ['2026-09', '2026-08']);
      expect(invoices.every((i) => i.statusAt(w.now) == InvoiceStatus.paid), isTrue);
      expect((await w.repo.myCompanyAccount(CompanySeed.valeoHrId, w.now))!.status, CompanyStatus.active);
    });
  });

  group('register and approve (US1)', () {
    test('a company is saved pending and the person is its HR contact', () async {
      final w = await _world();
      final r = await w.repo.register(
        personId: 'omar',
        name: 'Acme',
        domains: const ['Acme.EG'],
        hrWorkEmail: 'omar@acme.eg',
        now: w.now,
      );
      final company = (r as Registered).company;
      expect(company.status, CompanyStatus.pending);
      expect(company.domains, ['acme.eg']);
      expect(company.hrContactId, 'omar');
      final home = await w.repo.myCompanyAccount('omar', w.now);
      expect(home!.company.id, company.id);
      expect(home.status, CompanyStatus.pending);
      expect(await w.repo.myCompanyAccount('ahmed', w.now), isNull);
    });

    test('a public mail domain is refused', () async {
      final w = await _world();
      final r = await w.repo.register(
        personId: 'omar',
        name: 'Acme',
        domains: const ['acme.eg', 'Gmail.com'],
        hrWorkEmail: 'omar@acme.eg',
        now: w.now,
      );
      expect((r as PublicDomain).domain, 'gmail.com');
    });

    test('a domain another company holds is refused, any case', () async {
      final w = await _world();
      final r = await w.repo.register(
        personId: 'omar',
        name: 'Fake Valeo',
        domains: const ['VALEO.com'],
        hrWorkEmail: 'omar@valeo.com',
        now: w.now,
      );
      expect((r as DomainTaken).domain, 'valeo.com');
    });

    test('the HR work email must be on one of the domains', () async {
      final w = await _world();
      final r = await w.repo.register(
        personId: 'omar',
        name: 'Acme',
        domains: const ['acme.eg'],
        hrWorkEmail: 'omar@other.eg',
        now: w.now,
      );
      expect(r, isA<EmailNotOnDomain>());
    });

    test('Goora approves: active from that moment, annual contract, minimum and price, logged as Goora', () async {
      final w = await _world();
      final id = ((await w.repo.register(
        personId: 'omar',
        name: 'Acme',
        domains: const ['acme.eg'],
        hrWorkEmail: 'omar@acme.eg',
        now: w.now,
      )) as Registered).company.id;
      w.clock.now = _at(2026, 10, 22, 12);
      await w.repo.demoApprove(id, w.now);
      final c = (await w.repo.companyForDomain('acme.eg'))!;
      expect(c.status, CompanyStatus.active);
      expect(c.approvedAt, _at(2026, 10, 22, 12));
      expect(c.contractStart, CalendarDate(2026, 10, 22));
      expect(c.contractEnd, CalendarDate(2027, 10, 22));
      expect(c.minimumSeats, 20);
      expect(c.pricePerSeat, 99);
      final log = await _logOf(w, LogKind.approved, companyId: id);
      expect(log.single.actor, LogActor.goora);
      expect(log.single.at, _at(2026, 10, 22, 12));
    });
  });

  group('offerFor (US1 AC5, US2 AC4)', () {
    test('no work email, not on Goora, pending, can enroll, enrolled', () async {
      final w = await _world();
      expect(await w.repo.offerFor('laila', w.now), isA<NoWorkEmail>());
      expect(((await w.repo.offerFor('omar', w.now)) as NotOnGoora).domain, 'acme.eg');
      expect(await w.repo.offerFor('nour', w.now), isA<PendingCompany>());
      expect(((await w.repo.offerFor('ahmed', w.now)) as CanEnroll).companyName, 'Valeo');
      await w.repo.enroll('ahmed', now: w.now);
      final e = (await w.repo.offerFor('ahmed', w.now)) as Enrolled;
      expect(e.companyName, 'Valeo');
      expect(e.since, _start);
    });

    test('enrolling without an offer is refused', () async {
      final w = await _world();
      await expectLater(w.repo.enroll('nour', now: w.now), throwsStateError);
    });
  });

  group('enroll and leave write windows (FR-010, FR-018)', () {
    test('coverage opens at the consent moment', () async {
      final w = await _world();
      expect(await w.repo.coverageFor('ahmed', w.now), isEmpty);
      await w.repo.enroll('ahmed', now: w.now);
      expect(await w.repo.coverageFor('ahmed', w.now), [(from: _m(_start), to: null)]);
    });

    test('leaving closes it at that exact moment; re-joining opens a second window', () async {
      final w = await _world();
      await w.repo.enroll('ahmed', now: w.now);
      w.clock.now = _at(2026, 10, 25, 18);
      await w.repo.leave('ahmed', now: w.now);
      expect(await w.repo.coverageFor('ahmed', w.now), [(from: _m(_start), to: _m(_at(2026, 10, 25, 18)))]);
      expect(await w.repo.offerFor('ahmed', w.now), isA<CanEnroll>());
      w.clock.now = _at(2026, 10, 27, 8);
      await w.repo.enroll('ahmed', now: w.now);
      expect(await w.repo.coverageFor('ahmed', w.now), [
        (from: _m(_start), to: _m(_at(2026, 10, 25, 18))),
        (from: _m(_at(2026, 10, 27, 8)), to: null),
      ]);
      final left = await _logOf(w, LogKind.employeeLeft);
      expect(left.single.actor, LogActor.employee);
      expect(left.single.detail, 'Ahmed');
    });

    test('a leaver shows on this month\'s roster as left, and counts once in the month\'s peak', () async {
      final w = await _world();
      await w.repo.enroll('ahmed', now: w.now);
      w.clock.now = _at(2026, 10, 25, 18);
      await w.repo.leave('ahmed', now: w.now);
      w.clock.now = _at(2026, 10, 27, 8);
      await w.repo.enroll('ahmed', now: w.now);
      await w.repo.leave('ahmed', now: w.now);
      final rows = (await w.repo.roster(CompanySeed.valeoId, w.now)).where((r) => r.name == 'Ahmed').toList();
      expect(rows.single.leftAt, _at(2026, 10, 27, 8));
      w.clock.now = _at(2026, 11, 2, 9);
      expect((await w.repo.roster(CompanySeed.valeoId, w.now)).where((r) => r.name == 'Ahmed'), isEmpty);
      final oct = (await w.repo.invoices(CompanySeed.valeoId, w.now)).firstWhere((i) => i.month == '2026-10');
      expect(oct.peakEnrolled, 13);
      expect(oct.billedSeats, 20);
      expect(oct.total, 1980);
    });
  });

  group('invoices (US3, SC-004)', () {
    test('lazy and idempotent across a 3-month demo-clock jump', () async {
      final w = await _world();
      await w.repo.invoices(CompanySeed.valeoId, w.now);
      w.clock.now = _at(2027, 1, 20, 10);
      final first = await w.repo.invoices(CompanySeed.valeoId, w.now);
      final again = await w.repo.invoices(CompanySeed.valeoId, w.now);
      expect(first.map((i) => i.month), ['2026-12', '2026-11', '2026-10', '2026-09', '2026-08']);
      expect(again, first);
      expect(first.every((i) => i.billedSeats == 20 && i.total == 1980), isTrue);
      expect(first.map((i) => i.id).toSet(), hasLength(5));
      expect((await _logOf(w, LogKind.invoiceIssued)).map((e) => e.at.date), [
        CalendarDate(2027, 1, 1),
        CalendarDate(2026, 12, 1),
        CalendarDate(2026, 11, 1),
        CalendarDate(2026, 10, 1),
        CalendarDate(2026, 9, 1),
      ]);
    });

    test('a pending company is never invoiced', () async {
      final w = await _world();
      w.clock.now = _at(2027, 1, 20, 10);
      expect(await w.repo.invoices(CompanySeed.orangeId, w.now), isEmpty);
    });

    test('unpaid 7 days past due → suspended from 00:00 on due + 8; paying resumes from that moment', () async {
      final w = await _world();
      await w.repo.enroll('ahmed', now: w.now);
      w.clock.now = _at(2026, 11, 23, 23, 59);
      expect(await w.repo.coverageFor('ahmed', w.now), [(from: _m(_start), to: null)]);
      w.clock.now = _at(2026, 11, 24);
      expect((await w.repo.myCompanyAccount(CompanySeed.valeoHrId, w.now))!.status, CompanyStatus.suspended);
      expect(await w.repo.coverageFor('ahmed', w.now), [(from: _m(_start), to: _m(_at(2026, 11, 24)))]);
      final suspended = await _logOf(w, LogKind.suspended);
      expect(suspended.single.at, _at(2026, 11, 24));
      expect(suspended.single.actor, LogActor.goora);

      w.clock.now = _at(2026, 11, 27, 12);
      final oct = (await w.repo.invoices(CompanySeed.valeoId, w.now)).firstWhere((i) => i.month == '2026-10');
      expect(oct.statusAt(w.now), InvoiceStatus.overdue);
      await w.repo.demoMarkPaid(oct.id, bankRef: 'CIB-778812', now: w.now);
      expect(await w.repo.coverageFor('ahmed', w.now), [
        (from: _m(_start), to: _m(_at(2026, 11, 24))),
        (from: _m(_at(2026, 11, 27, 12)), to: null),
      ]);
      expect((await w.repo.myCompanyAccount(CompanySeed.valeoHrId, w.now))!.status, CompanyStatus.active);
      final paid = (await w.repo.invoices(CompanySeed.valeoId, w.now)).firstWhere((i) => i.month == '2026-10');
      expect(paid.bankRef, 'CIB-778812');
      expect(paid.paidOn, CalendarDate(2026, 11, 27));
      expect((await _logOf(w, LogKind.invoicePaid)).first.actor, LogActor.goora);
      final resumed = await _logOf(w, LogKind.resumed);
      expect(resumed.single.at, _at(2026, 11, 27, 12));
      // Reading again writes nothing new.
      await w.repo.coverageFor('ahmed', w.now);
      expect(await _logOf(w, LogKind.suspended), hasLength(1));
      expect(await _logOf(w, LogKind.resumed), hasLength(1));
    });
  });

  group('company-side changes are logged with the actor (FR-031)', () {
    test('HR adds and removes a domain; employees on the removed domain leave', () async {
      final w = await _world();
      await w.repo.addDomain(CompanySeed.valeoId, 'Valeo.EG', w.now);
      await w.repo.enroll('sara', now: w.now);
      w.clock.now = _at(2026, 10, 21, 9);
      await w.repo.removeDomain(CompanySeed.valeoId, 'valeo.eg', w.now);
      expect(await w.repo.coverageFor('sara', w.now), [(from: _m(_start), to: _m(_at(2026, 10, 21, 9)))]);
      final row = (await w.repo.roster(CompanySeed.valeoId, w.now)).firstWhere((r) => r.name == 'Sara');
      expect(row.leftAt, _at(2026, 10, 21, 9));
      final added = await _logOf(w, LogKind.domainAdded);
      final removed = await _logOf(w, LogKind.domainRemoved);
      expect((added.single.actor, added.single.detail), (LogActor.hr, 'valeo.eg'));
      expect((removed.single.actor, removed.single.detail), (LogActor.hr, 'valeo.eg'));
      expect(await w.repo.offerFor('sara', w.now), isA<NotOnGoora>());
    });

    test('the last domain cannot be removed; a taken or public domain cannot be added', () async {
      final w = await _world();
      await expectLater(w.repo.removeDomain(CompanySeed.valeoId, 'valeo.com', w.now), throwsStateError);
      await expectLater(w.repo.addDomain(CompanySeed.valeoId, 'orange.com', w.now), throwsStateError);
      await expectLater(w.repo.addDomain(CompanySeed.valeoId, 'gmail.com', w.now), throwsStateError);
    });

    test('HR removes an employee', () async {
      final w = await _world();
      await w.repo.enroll('ahmed', now: w.now);
      w.clock.now = _at(2026, 10, 21, 9);
      await w.repo.removeEmployee(CompanySeed.valeoId, 'ahmed@valeo.com', w.now);
      expect(await w.repo.coverageFor('ahmed', w.now), [(from: _m(_start), to: _m(_at(2026, 10, 21, 9)))]);
      final removed = await _logOf(w, LogKind.employeeRemoved);
      expect((removed.single.actor, removed.single.detail), (LogActor.hr, 'Ahmed'));
    });

    test('Goora changes the HR contact', () async {
      final w = await _world();
      await w.repo.demoSetHrContact(CompanySeed.valeoId, 'ahmed', w.now);
      expect((await w.repo.myCompanyAccount('ahmed', w.now))!.company.id, CompanySeed.valeoId);
      expect(await w.repo.myCompanyAccount(CompanySeed.valeoHrId, w.now), isNull);
      expect((await _logOf(w, LogKind.hrContactChanged)).single.actor, LogActor.goora);
    });

    test('Goora ends the contract: everyone leaves, one final invoice, then none', () async {
      final w = await _world();
      await w.repo.enroll('ahmed', now: w.now);
      w.clock.now = _at(2026, 10, 21, 9);
      await w.repo.demoEndContract(CompanySeed.valeoId, w.now);
      expect(await w.repo.coverageFor('ahmed', w.now), [(from: _m(_start), to: _m(_at(2026, 10, 21, 9)))]);
      expect(((await w.repo.offerFor('ahmed', w.now)) as NotOnGoora).domain, 'valeo.com');
      expect((await w.repo.myCompanyAccount(CompanySeed.valeoHrId, w.now))!.status, CompanyStatus.ended);
      expect((await _logOf(w, LogKind.contractEnded)).single.actor, LogActor.goora);
      w.clock.now = _at(2027, 1, 20, 10);
      expect((await w.repo.invoices(CompanySeed.valeoId, w.now)).map((i) => i.month), ['2026-10', '2026-09', '2026-08']);
    });

    test('the contract end date passing ends the company at 00:00 that day', () async {
      final w = await _world();
      await w.repo.enroll('ahmed', now: w.now);
      w.clock.now = _at(2027, 8, 2, 9);
      // (Unpaid invoices since October also suspended coverage; this test is
      // about the enrollments closing.)
      expect(((await w.repo.offerFor('ahmed', w.now)) as NotOnGoora).domain, 'valeo.com');
      expect((await w.repo.myCompanyAccount(CompanySeed.valeoHrId, w.now))!.status, CompanyStatus.ended);
      final last = (await w.repo.invoices(CompanySeed.valeoId, w.now)).first;
      expect(last.month, '2027-07');
      final ended = await _logOf(w, LogKind.contractEnded);
      expect((ended.single.actor, ended.single.at), (LogActor.goora, _at(2027, 8, 1)));
      final rows = await w.repo.roster(CompanySeed.valeoId, w.now);
      expect(rows.every((r) => r.leftAt == _at(2027, 8, 1)), isTrue);
    });

    test('the log reads newest first', () async {
      final w = await _world();
      await w.repo.addDomain(CompanySeed.valeoId, 'valeo.eg', w.now);
      w.clock.now = _at(2026, 10, 21, 9);
      await w.repo.demoSetHrContact(CompanySeed.valeoId, 'ahmed', w.now);
      final log = await w.repo.log(CompanySeed.valeoId);
      expect(log.first.kind, LogKind.hrContactChanged);
      for (var i = 1; i < log.length; i++) {
        expect(log[i - 1].at.isBefore(log[i].at), isFalse);
      }
    });
  });

  group('clearAll (Settings → Reset)', () {
    test('removes every company key and nothing else', () async {
      final w = await _world(prefs: {'market.offers': '[]'});
      await w.repo.enroll('ahmed', now: w.now);
      expect(w.prefs.getKeys().where((k) => k.startsWith('company.')), isNotEmpty);
      await w.repo.clearAll();
      expect(w.prefs.getKeys().where((k) => k.startsWith('company.')), isEmpty);
      expect(w.prefs.getString('market.offers'), '[]');
    });

    test('overlapping first reads seed once', () async {
      final w = await _world();
      await Future.wait([
        w.repo.roster(CompanySeed.valeoId, w.now),
        w.repo.offerFor('ahmed', w.now),
        w.repo.invoices(CompanySeed.valeoId, w.now),
      ]);
      expect(await w.repo.roster(CompanySeed.valeoId, w.now), hasLength(12));
      expect(await _logOf(w, LogKind.approved), hasLength(1));
      expect(await w.repo.invoices(CompanySeed.valeoId, w.now), hasLength(2));
    });

    test('the next read starts from the seed again', () async {
      final w = await _world();
      await w.repo.enroll('ahmed', now: w.now);
      await w.repo.clearAll();
      expect(await w.repo.offerFor('ahmed', w.now), isA<CanEnroll>());
      expect(await w.repo.roster(CompanySeed.valeoId, w.now), hasLength(12));
    });
  });

  test('a roster row carries only name, work email and dates (constitution IV)', () async {
    final w = await _world();
    final row = (await w.repo.roster(CompanySeed.valeoId, w.now)).first;
    expect(row.toString(), isNot(contains(CompanySeed.valeoFacts.first.personId)));
    expect(row.enrolledAt, isA<WallTime>());
    expect(LeftWhy.values, hasLength(4));
  });
}
