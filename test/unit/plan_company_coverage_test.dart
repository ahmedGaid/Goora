import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/group_catalog.dart';
import 'package:goora/features/commute/domain/commute_profile.dart' show Leg;
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/company/domain/company_rules.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
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
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

/// 010 P1 (T004, T006, research R2): a company plan covers only inside its
/// coverage windows, judged at the exact moment; with no windows attached it
/// behaves as before 010 (covers from its start, forever).
void main() {
  final enrolled = at(CalendarDate(2026, 10, 6), 8, 30);
  final left = at(CalendarDate(2026, 10, 9), 14, 0);
  int m(WallTime t) => SharePolicy.minuteOf(t);
  WallTime minuteAfter(WallTime t) => t.plusMinutes(1);
  WallTime minuteBefore(WallTime t) => t.plusMinutes(-1);

  Plan company({List<Window>? coverage}) {
    final p = Plan(
      personId: 'me',
      type: PlanType.company,
      status: PlanStatus.active,
      price: 0,
      startDate: enrolled,
    );
    return coverage == null ? p : p.withCoverage(coverage);
  }

  group('Plan coverage (T004)', () {
    test('[enrolled, ∞) behaves as a company plan does today', () {
      final legacy = company();
      final open = company(coverage: [(from: m(enrolled), to: null)]);
      for (final t in [minuteBefore(enrolled), enrolled, at(CalendarDate(2027, 3, 1), 7, 0)]) {
        expect(open.coversTrip(t), legacy.coversTrip(t), reason: '$t');
      }
      for (final d in [enrolled.date.addDays(-1), enrolled.date, enrolled.date.addDays(400)]) {
        expect(open.coversDate(d), legacy.coversDate(d), reason: '$d');
      }
      expect(open.coversTrip(minuteBefore(enrolled)), isFalse);
      expect(open.coversTrip(enrolled), isTrue);
    });

    test('[enrolled, left): covered up to the minute before leaving, not at or after it', () {
      final p = company(coverage: [(from: m(enrolled), to: m(left))]);
      expect(p.coversTrip(minuteBefore(left)), isTrue);
      expect(p.coversTrip(left), isFalse);
      expect(p.coversTrip(minuteAfter(left)), isFalse);
      expect(p.coversTrip(at(left.date.addDays(5), 8, 0)), isFalse);
    });

    test('coversDate is true on any day a window overlaps, false outside every window', () {
      final p = company(coverage: [(from: m(enrolled), to: m(left))]);
      expect(p.coversDate(enrolled.date.addDays(-1)), isFalse);
      expect(p.coversDate(enrolled.date), isTrue, reason: 'enrolled at 08:30 that day');
      expect(p.coversDate(left.date), isTrue, reason: 'covered until 14:00 that day');
      expect(p.coversDate(left.date.addDays(1)), isFalse);
    });

    test('a gap (suspension) between windows is not covered; both sides are', () {
      final suspendFrom = at(CalendarDate(2026, 10, 7), 0, 0);
      final paid = at(CalendarDate(2026, 10, 8), 11, 0);
      final p = company(coverage: [(from: m(enrolled), to: m(suspendFrom)), (from: m(paid), to: null)]);
      expect(p.coversTrip(minuteBefore(suspendFrom)), isTrue);
      expect(p.coversTrip(at(CalendarDate(2026, 10, 7), 12, 0)), isFalse);
      expect(p.coversDate(CalendarDate(2026, 10, 7)), isFalse, reason: 'the whole 7th is suspended');
      expect(p.coversTrip(paid), isTrue);
    });

    test('empty coverage covers nothing', () {
      final p = company(coverage: const []);
      expect(p.coversTrip(enrolled), isFalse);
      expect(p.coversDate(enrolled.date), isFalse);
    });

    test('no coverage attached = today\'s behaviour, from startDate', () {
      final p = company();
      expect(p.coverage, isNull);
      expect(p.coversTrip(minuteBefore(enrolled)), isFalse);
      expect(p.coversTrip(at(CalendarDate(2030, 1, 1), 9, 0)), isTrue);
      const v1 = Plan(personId: 'me', type: PlanType.company, status: PlanStatus.active, price: 0);
      expect(v1.coversDate(CalendarDate(2020, 1, 1)), isTrue);
    });

    test('coverage is not stored: JSON round trip drops it, withCoverage keeps the rest', () {
      final p = company(coverage: [(from: m(enrolled), to: m(left))]);
      expect(p.toJson().containsKey('coverage'), isFalse);
      expect(jsonEncode(p.toJson()), jsonEncode(company().toJson()));
      expect(Plan.fromJson(p.toJson()).coverage, isNull);
      expect((p.personId, p.type, p.status, p.price, p.startDate), ('me', PlanType.company, PlanStatus.active, 0, enrolled));
    });

    test('coverage only speaks for a company plan; a monthly plan ignores it', () {
      final monthly = Plan(
        personId: 'me',
        type: PlanType.monthly,
        status: PlanStatus.active,
        price: 149,
        startDate: enrolled,
        untilDate: enrolled.date.addMonths(1),
      );
      final withWindows = monthly.withCoverage(const []);
      expect(withWindows.coversTrip(minuteAfter(enrolled)), isTrue);
      expect(withWindows.coversDate(enrolled.date), isTrue);
    });
  });

  group('PricingMode.of at the exact moment (T006)', () {
    test('Company one minute before leaving, per trip one minute after — same day', () {
      final p = company(coverage: [(from: m(enrolled), to: m(left))]);
      expect(PricingMode.of(plan: p, now: minuteBefore(left), trialAvailable: false), PricingMode.company);
      expect(PricingMode.of(plan: p, now: minuteAfter(left), trialAvailable: false), PricingMode.perTrip);
      expect(minuteAfter(left).date, left.date);
    });

    test('a monthly plan still prices from its paid period', () {
      final monthly = Plan(
        personId: 'me',
        type: PlanType.monthly,
        status: PlanStatus.active,
        price: 149,
        startDate: enrolled,
        untilDate: enrolled.date.addMonths(1),
      );
      expect(PricingMode.of(plan: monthly, now: minuteAfter(enrolled), trialAvailable: false), PricingMode.subscribed);
      expect(
        PricingMode.of(plan: monthly, now: at(enrolled.date.addMonths(1).addDays(1), 8, 0), trialAvailable: false),
        PricingMode.perTrip,
      );
    });
  });

  group('a one-off seat is priced at the booking moment (T006)', () {
    // Tue 6 Oct 2026 evening; Tarek's seed seat is Wed 07:30 at 44 (+4 fee).
    final tue = rideTuesday;

    Future<(FakeMarketplaceRepository, FakeWalletRepository, TestClock)> world(List<Window> windows) async {
      SharedPreferences.setMockInitialValues({
        ...memberPrefs(role: Role.rider, member: false, method: PaymentMethod.instapay, pastTrial: true),
        FakeWalletRepository.planKey: jsonEncode(
          Plan(
            personId: DailySeed.meId,
            type: PlanType.company,
            status: PlanStatus.active,
            price: 0,
            startDate: at(tue, 8, 0),
          ).toJson(),
        ),
      });
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
      late final FakeMarketplaceRepository repo;
      final wallet = FakeWalletRepository(
        prefs,
        daily: daily,
        role: () => MemberRole.rider,
        now: clock.call,
        provider: FakePaymentProvider(),
        oneOffs: () => repo.doneOneOffs(),
        companyCoverage: (_) async => windows,
      );
      repo = FakeMarketplaceRepository(
        prefs,
        catalog: catalog,
        daily: daily,
        commute: FakeCommuteRepository(prefs, catalog: catalog),
        notices: daily,
        ledger: () => wallet,
        wallet: () => wallet,
        trust: FakeTrustRepository(prefs, person: () => person, now: clock.call),
        now: clock.call,
        corridor: Corridors.sheikhZayedSmartVillage,
      );
      await wallet.topUp('me', method: 'card', amount: 200);
      return (repo, wallet, clock);
    }

    Future<Booking> bookTarek(FakeMarketplaceRepository repo, WallTime now) async {
      final seats = await repo.seatOffers(Leg.going, now: now);
      final seat = seats.firstWhere((s) => s.source == const BookingSource.offer(MarketSeed.tarekId));
      return (await repo.book(seat, now: now) as Booked).booking;
    }

    test('booked one minute after leaving: carries the fee', () async {
      final (repo, wallet, clock) = await world([(from: m(at(tue, 8, 0)), to: m(at(tue, 19, 59)))]);
      final booking = await bookTarek(repo, clock.now);
      expect(booking.price.fee, 4);
      expect((await wallet.getWallet('me')).balance, 196);
    });

    test('booked one minute before leaving: fee-free', () async {
      final (repo, wallet, clock) = await world([(from: m(at(tue, 8, 0)), to: m(at(tue, 20, 1)))]);
      final booking = await bookTarek(repo, clock.now);
      expect(booking.price.fee, 0);
      expect((await wallet.getWallet('me')).balance, 200);
    });
  });
}
