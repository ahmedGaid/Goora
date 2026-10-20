import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/company/domain/company_repository.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:goora/main.dart' show loadSession;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

/// 010 P3 seams (T017, T019): Trust gives the work email, the company
/// network knows the signed-in person through it, and the wallet asks the
/// company network for coverage through a function — both providers build
/// together with no cycle.
void main() {
  final enrollAt = WallTime(CalendarDate(2026, 10, 20), const Clock.hm(9, 0));

  group('TrustProfile.workEmail (T017)', () {
    Profile person(String first) =>
        Profile(phone: testPhone, firstName: first, lastName: 'Khaled', gender: Gender.male, role: Role.rider);

    test('verified work email reads <first>@valeo.com, beside the company name', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final trust = FakeTrustRepository(prefs, person: () => person('Omar'), now: () => enrollAt);
      final p = await trust.profile();
      expect(p.company, DailySeed.company);
      expect(p.workEmail, 'omar@valeo.com');
    });

    test('a first name with no Latin letters still gives a usable address', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final trust = FakeTrustRepository(prefs, person: () => person('عمر'), now: () => enrollAt);
      final email = (await trust.profile()).workEmail!;
      expect(email, endsWith('@valeo.com'));
      expect(RegExp(r'^[a-z0-9.]+@valeo\.com$').hasMatch(email), isTrue, reason: email);
    });
  });

  group('wallet ↔ company providers (T019)', () {
    Future<ProviderContainer> container({bool signedIn = true}) async {
      SharedPreferences.setMockInitialValues(
        signedIn ? memberPrefs(role: Role.rider, member: false, withPlan: false, method: PaymentMethod.cash) : {},
      );
      final prefs = await SharedPreferences.getInstance();
      final session = await loadSession(prefs);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialSessionProvider.overrideWithValue(session),
        nowProvider.overrideWithValue(() => enrollAt),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('both build together; the signed-in rider can enroll through Trust\'s work email', () async {
      final c = await container();
      final wallet = c.read(walletRepositoryProvider);
      final company = c.read(companyRepositoryProvider);
      final me = c.read(dailyCommuteRepositoryProvider).meId;
      expect(await company.offerFor(me, enrollAt), isA<CanEnroll>());
      expect(await wallet.getPlan(me), isNull);
    });

    test('a company plan read through the provider carries the company network\'s windows', () async {
      final c = await container();
      final wallet = c.read(walletRepositoryProvider);
      final company = c.read(companyRepositoryProvider);
      final me = c.read(dailyCommuteRepositoryProvider).meId;
      await company.enroll(me, now: enrollAt);
      await wallet.startCompanyPlan(me, enrollAt);

      final plan = (await wallet.getPlan(me))!;
      expect(plan.type, PlanType.company);
      expect(plan.coverage, [(from: SharePolicy.minuteOf(enrollAt), to: null)]);
      expect(await c.read(riderPricingProvider.future), PricingMode.company);

      final leftAt = enrollAt.plusMinutes(60);
      await company.leave(me, now: leftAt);
      final after = (await wallet.getPlan(me))!;
      expect(after.coverage, [(from: SharePolicy.minuteOf(enrollAt), to: SharePolicy.minuteOf(leftAt))]);
      expect(after.coversTrip(leftAt.plusMinutes(1)), isFalse);
    });

    test('a company plan with no enrollment anywhere keeps its pre-010 meaning', () async {
      final c = await container();
      final wallet = c.read(walletRepositoryProvider);
      final me = c.read(dailyCommuteRepositoryProvider).meId;
      await wallet.subscribe(me, PlanType.company, today: enrollAt.date);
      final plan = (await wallet.getPlan(me))!;
      expect(plan.coverage, isNull);
      expect(plan.coversTrip(enrollAt.plusMinutes(1)), isTrue);
    });

    test('signed out: the company network knows nobody, offers "no work email"', () async {
      final c = await container(signedIn: false);
      expect(await c.read(companyRepositoryProvider).offerFor(DailySeed.meId, enrollAt), isA<NoWorkEmail>());
    });
  });
}
