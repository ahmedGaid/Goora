import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/group_catalog.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart' show Leg;
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/domain/company_log.dart';
import 'package:goora/features/company/domain/company_repository.dart';
import 'package:goora/features/company/domain/company_rules.dart';
import 'package:goora/features/company/domain/enrollment.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/daily/domain/trust.dart';
import 'package:goora/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/domain/booking.dart';
import 'package:goora/features/marketplace/domain/marketplace_repository.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/fake_payment_provider.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

// 010 P9, research "P8/P9 notes (autonomous run)" finding C1: the spec's edge
// cases that had a sentence but no test. Real fakes over shared_preferences,
// no mocks.

WallTime _at(int y, int m, int d, [int h = 0, int min = 0]) => WallTime(CalendarDate(y, m, d), Clock.hm(h, min));
int _min(WallTime t) => SharePolicy.minuteOf(t);

/// Tue 20 Oct 2026, 10:00: the seed's Valeo was approved on 1 Aug 2026.
final _start = _at(2026, 10, 20, 10);

typedef _Person = ({String name, String? workEmail});

final class _World {
  _World(this.repo, this.prefs, this.clock, this.people);

  final FakeCompanyRepository repo;
  final SharedPreferences prefs;
  final TestClock clock;

  /// What the profile says about each person right now; tests change it to
  /// move someone to another work email.
  final Map<String, _Person> people;

  WallTime get now => clock.now;
}

Future<_World> _world([Map<String, _Person> people = const {}]) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final clock = TestClock(_start);
  final live = {...people};
  final repo = FakeCompanyRepository(prefs, person: (id) async => live[id], now: clock.call);
  // The seed anchors at the first read, so read once at [_start] before a test moves the clock.
  await repo.companyForDomain('valeo.com');
  return _World(repo, prefs, clock, live);
}

/// Goora changes Valeo's price per seat in storage, the way a later Q1 answer
/// would: the stored company changes, nothing already issued is rewritten.
Future<void> _setPrice(SharedPreferences prefs, String companyId, int price) async {
  final all = (jsonDecode(prefs.getString(FakeCompanyRepository.companiesKey)!) as List).cast<Map<String, Object?>>();
  for (final c in all.where((c) => c['id'] == companyId)) {
    c['pricePerSeat'] = price;
  }
  await prefs.setString(FakeCompanyRepository.companiesKey, jsonEncode(all));
}

void main() {
  group('price change mid-contract (spec edge case, Q1 later)', () {
    test('applies from the next invoice; invoices already issued never change', () async {
      final w = await _world();
      w.clock.now = _at(2026, 11, 2, 10);
      final before = await w.repo.invoices(CompanySeed.valeoId, w.now);
      expect(before.map((i) => i.month), ['2026-10', '2026-09', '2026-08']);
      expect(before.map((i) => i.pricePerSeat).toSet(), {99});

      await _setPrice(w.prefs, CompanySeed.valeoId, 120);
      w.clock.now = _at(2026, 12, 2, 10);
      final after = await w.repo.invoices(CompanySeed.valeoId, w.now);

      expect(after.map((i) => i.month), ['2026-11', '2026-10', '2026-09', '2026-08']);
      expect(after.skip(1).map((i) => i.toJson()).toList(), before.map((i) => i.toJson()).toList(),
          reason: 'issued invoices are stored as issued, price and total included');
      final november = after.first;
      expect(november.pricePerSeat, 120);
      expect(november.total, november.billedSeats * 120);
    });

    test('a month is invoiced once: reading again after the change issues nothing new', () async {
      final w = await _world();
      w.clock.now = _at(2026, 11, 2, 10);
      final first = await w.repo.invoices(CompanySeed.valeoId, w.now);
      await _setPrice(w.prefs, CompanySeed.valeoId, 150);
      final again = await w.repo.invoices(CompanySeed.valeoId, w.now);
      expect(again.map((i) => i.toJson()).toList(), first.map((i) => i.toJson()).toList());
    });
  });

  group('employee moves to another work email domain (spec edge case)', () {
    const ahmed = (name: 'Ahmed', workEmail: 'ahmed@valeo.com');

    test('another domain of the same company: stays enrolled, coverage unbroken', () async {
      final w = await _world({'ahmed': ahmed});
      await w.repo.addDomain(CompanySeed.valeoId, 'valeo.eg', w.now);
      await w.repo.enroll('ahmed', now: w.now);

      w.people['ahmed'] = (name: 'Ahmed', workEmail: 'ahmed@valeo.eg');
      w.clock.now = _at(2026, 10, 21, 10);

      expect(await w.repo.offerFor('ahmed', w.now), isA<Enrolled>());
      final windows = await w.repo.coverageFor('ahmed', w.now);
      expect(windows, hasLength(1));
      expect(windows.single.to, isNull, reason: 'one open window, no gap');
      expect((await w.repo.roster(CompanySeed.valeoId, w.now)).where((r) => r.name == 'Ahmed').single.leftAt, isNull);
      expect((await w.repo.log(CompanySeed.valeoId)).where((e) => e.kind == LogKind.employeeLeft), isEmpty);
    });

    test("another company's domain: leaves the first at that moment, may join the second", () async {
      final w = await _world({'ahmed': ahmed});
      await w.repo.demoApprove(CompanySeed.orangeId, w.now);
      await w.repo.enroll('ahmed', now: w.now);

      w.people['ahmed'] = (name: 'Ahmed', workEmail: 'ahmed@orange.com');
      w.clock.now = _at(2026, 10, 21, 10);

      expect(await w.repo.offerFor('ahmed', w.now), isA<CanEnroll>().having((o) => o.companyName, 'company', 'Orange Business'));
      final left = (await w.repo.lastLeave('ahmed', w.now))!;
      expect((left.companyName, left.at, left.why), ('Valeo', w.now, LeftWhy.self));
      final row = (await w.repo.roster(CompanySeed.valeoId, w.now)).singleWhere((r) => r.name == 'Ahmed');
      expect(row.leftAt, w.now, reason: 'HR sees "left on <date>" this month');
      final leaves = (await w.repo.log(CompanySeed.valeoId)).where((e) => e.kind == LogKind.employeeLeft).toList();
      expect(leaves.map((e) => (e.actor, e.detail)), [(LogActor.employee, 'Ahmed')]);

      // Valeo no longer covers a trip from this minute on.
      final valeoWindows = await w.repo.coverageFor('ahmed', w.now);
      expect(CompanyRules.covered(valeoWindows, _min(w.now) - 1), isTrue);
      expect(CompanyRules.covered(valeoWindows, _min(w.now)), isFalse);

      await w.repo.enroll('ahmed', now: w.now);
      expect(await w.repo.offerFor('ahmed', w.now), isA<Enrolled>().having((o) => o.companyName, 'company', 'Orange Business'));
      expect(CompanyRules.covered(await w.repo.coverageFor('ahmed', w.now), _min(w.now)), isTrue);
    });

    test('the other company is checked on the wallet side too: coverage alone ends Valeo', () async {
      final w = await _world({'ahmed': ahmed});
      await w.repo.enroll('ahmed', now: w.now);
      w.people['ahmed'] = (name: 'Ahmed', workEmail: 'ahmed@orange.com');
      w.clock.now = _at(2026, 10, 21, 10);
      // The wallet reads coverage first; it must not keep a closed company covering.
      expect(CompanyRules.covered(await w.repo.coverageFor('ahmed', w.now), _min(w.now)), isFalse);
    });

    test('a domain no company holds, or no email at all: stays enrolled (spec is silent; HR can remove them)', () async {
      final w = await _world({'ahmed': ahmed});
      await w.repo.enroll('ahmed', now: w.now);
      w.clock.now = _at(2026, 10, 21, 10);

      w.people['ahmed'] = (name: 'Ahmed', workEmail: 'ahmed@nowhere.example');
      expect(await w.repo.offerFor('ahmed', w.now), isA<Enrolled>());
      w.people['ahmed'] = (name: 'Ahmed', workEmail: null);
      expect(await w.repo.offerFor('ahmed', w.now), isA<Enrolled>());
    });
  });

  group('009 ID check is not skipped by enrolling (spec edge case)', () {
    final tue = rideTuesday;

    Future<({FakeMarketplaceRepository market, FakeTrustRepository trust, FakeCompanyRepository company, TestClock clock})>
        world() async {
      SharedPreferences.setMockInitialValues(
        memberPrefs(role: Role.rider, member: false, method: PaymentMethod.instapay, pastTrial: true, idVerified: false),
      );
      final prefs = await SharedPreferences.getInstance();
      final clock = TestClock(at(tue, 20, 0));
      final person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: Role.rider);
      final catalog = GroupCatalog(prefs);
      final daily = FakeDailyCommuteRepository(
        prefs,
        commute: FakeCommuteRepository(prefs, catalog: catalog),
        person: () => person,
        now: clock.call,
        catalog: catalog,
      );
      final company = FakeCompanyRepository(
        prefs,
        person: (_) async => (name: 'Omar Khaled', workEmail: 'omar@valeo.com'),
        now: clock.call,
      );
      late final FakeMarketplaceRepository market;
      final wallet = FakeWalletRepository(
        prefs,
        daily: daily,
        role: () => MemberRole.rider,
        now: clock.call,
        provider: FakePaymentProvider(),
        oneOffs: () => market.doneOneOffs(),
        companyCoverage: (id) => company.coverageFor(id, clock.now),
      );
      final trust = FakeTrustRepository(prefs, person: () => person, now: clock.call);
      market = FakeMarketplaceRepository(
        prefs,
        catalog: catalog,
        daily: daily,
        commute: FakeCommuteRepository(prefs, catalog: catalog),
        notices: daily,
        ledger: () => wallet,
        wallet: () => wallet,
        trust: trust,
        now: clock.call,
        corridor: Corridors.sheikhZayedSmartVillage,
      );
      await wallet.topUp(DailySeed.meId, method: 'card', amount: 200);
      await company.enroll(DailySeed.meId, now: clock.now);
      await wallet.startCompanyPlan(DailySeed.meId, clock.now);
      return (market: market, trust: trust, company: company, clock: clock);
    }

    Future<BookResult> book(FakeMarketplaceRepository market, TestClock clock) async {
      final seats = await market.seatOffers(Leg.going, now: clock.now);
      final seat = seats.firstWhere((s) => s.source == const BookingSource.offer(MarketSeed.tarekId));
      return market.book(seat, now: clock.now);
    }

    test('enrolled and covered with the ID not checked: booking still asks for the ID; after it, fee 0', () async {
      final w = await world();
      expect(await w.trust.riderIdStatus(), isNot(RiderIdStatus.verified));
      expect(CompanyRules.covered(await w.company.coverageFor(DailySeed.meId, w.clock.now), _min(w.clock.now)), isTrue);

      expect(await book(w.market, w.clock), isA<BookNeedsId>(), reason: 'coverage is about the fee, never the ID');
      expect(await w.trust.riderIdStatus(), isNot(RiderIdStatus.verified), reason: 'enrolling did not verify anyone');

      await w.trust.submitRiderId();
      final booked = await book(w.market, w.clock);
      expect(booked, isA<Booked>());
      expect((booked as Booked).booking.price.fee, 0);
    });
  });

  group('same-company privacy filter (spec edge case, 002/003)', () {
    test('enrolling changes nothing the matcher reads: the filter keeps keying on the verified work-email company', () async {
      SharedPreferences.setMockInitialValues(memberPrefs(role: Role.rider, member: false));
      final prefs = await SharedPreferences.getInstance();
      final clock = TestClock(_start);
      final person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: Role.rider);
      final trust = FakeTrustRepository(prefs, person: () => person, now: clock.call);
      final company = FakeCompanyRepository(
        prefs,
        person: (_) async => (name: 'Omar Khaled', workEmail: 'omar@valeo.com'),
        now: clock.call,
      );
      final before = (await trust.profile()).facts;
      await company.enroll(DailySeed.meId, now: clock.now);
      final after = (await trust.profile()).facts;
      expect(after.company, before.company);
      expect(after.compound, before.compound);
      expect(after.isWoman, before.isWoman);
    });
  });

  group('a driver-only employee enrolls (spec edge case, Q2 default)', () {
    test('counts once for the roster, the dashboard headcount and the month\'s billed seats', () async {
      // The company network has no role field: a driver-only person is one
      // with a work email and no rider trips. Valeo has 12; add the driver
      // and 8 riders, 21 in all, one above the 20-seat floor.
      final people = {
        'dina': (name: 'Dina', workEmail: 'dina@valeo.com'),
        for (var i = 1; i <= 8; i++) 'r$i': (name: 'Rider $i', workEmail: 'r$i@valeo.com'),
      };
      final w = await _world(people);
      expect(await w.repo.offerFor('dina', w.now), isA<CanEnroll>());
      for (final id in people.keys) {
        await w.repo.enroll(id, now: w.now);
      }

      expect(await w.repo.offerFor('dina', w.now), isA<Enrolled>());
      final roster = await w.repo.roster(CompanySeed.valeoId, w.now);
      expect(roster.where((r) => r.name == 'Dina'), hasLength(1));
      expect(roster, hasLength(21));
      final october = await w.repo.dashboard(CompanySeed.valeoId, '2026-10', w.now);
      expect(october.enrolled, 21);
      expect(october.active, 8, reason: 'enrolled, but no trip as rider or driver yet');

      w.clock.now = _at(2026, 11, 2, 10);
      final invoice = (await w.repo.invoices(CompanySeed.valeoId, w.now)).firstWhere((i) => i.month == '2026-10');
      expect(invoice.peakEnrolled, 21);
      expect(invoice.billedSeats, 21);
    });
  });

  group('a month with nobody enrolled, and an HR contact who also rides (spec edge cases)', () {
    test('a company with zero enrolled for a month is still billed the minimum', () async {
      final w = await _world();
      await w.repo.demoApprove(CompanySeed.orangeId, w.now);
      w.clock.now = _at(2026, 11, 2, 10);
      final invoices = await w.repo.invoices(CompanySeed.orangeId, w.now);
      expect(invoices.map((i) => i.month), ['2026-10']);
      expect(invoices.single.peakEnrolled, 0);
      expect(invoices.single.billedSeats, 20);
      expect(invoices.single.total, 20 * invoices.single.pricePerSeat);
    });

    test('the HR contact who rides is on the roster like anyone, and keeps the HR home', () async {
      final w = await _world({'hala': (name: 'Hala', workEmail: 'hala@valeo.com')});
      await w.repo.demoSetHrContact(CompanySeed.valeoId, 'hala', w.now);
      await w.repo.enroll('hala', now: w.now);

      final rows = (await w.repo.roster(CompanySeed.valeoId, w.now)).where((r) => r.name == 'Hala').toList();
      expect(rows, hasLength(1));
      expect((rows.single.workEmail, rows.single.leftAt), ('hala@valeo.com', null));
      expect((await w.repo.myCompanyAccount('hala', w.now))!.company.id, CompanySeed.valeoId);
      expect(await w.repo.offerFor('hala', w.now), isA<Enrolled>());
    });
  });
}
