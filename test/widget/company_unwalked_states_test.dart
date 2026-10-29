import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/company/domain/company_repository.dart';
import 'package:goora/features/company/presentation/company_controller.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 010 P9 (walk 5 left two states unwalked on a device, REPORT.md): what an
/// employee sees on their next trip after HR removes them (US4 AC2, AC7;
/// FR-018, FR-020), and a dashboard where some figures show a number and the
/// rest say "Fewer than 5" (FR-022) — ar + en. The unit tests already pin the
/// rules; these pin the screens.
final _now = at(rideTuesday, 10, 0);

/// The demo user's Trust work email (`FakeTrustRepository.workEmailFor`).
const _myEmail = 'omar@valeo.com';

Future<ProviderContainer> _enrolledEmployee(WidgetTester tester, String locale, TestClock clock) async {
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale, withPlan: false),
    overrides: dailyOverrides(clock),
  );
  tester.view.physicalSize = const Size(390, 2400);
  c.read(routerProvider).go(Routes.plan);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('plan-company')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('plan-cta')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('company-join')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('consent-agree')));
  await tester.pumpAndSettle();
  return c;
}

/// Orange Business with [headcount] employees, approved, the demo user as its
/// HR contact. Orange has no seeded activity, so only "enrolled" can ever
/// reach 5 here — a deliberately mixed month.
Future<ProviderContainer> _orangeHr(WidgetTester tester, String locale, {required int headcount}) async {
  final people = <String, ({String name, String? workEmail})>{
    for (var i = 1; i <= headcount; i++) 'orange-$i': (name: 'Orange Person $i', workEmail: 'p$i@orange.com'),
  };
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale),
    overrides: [
      ...dailyOverrides(TestClock(_now)),
      companyRepositoryProvider.overrideWith(
        (ref) => FakeCompanyRepository(
          ref.watch(sharedPreferencesProvider),
          person: (id) async => people[id],
          now: ref.watch(nowProvider),
        ),
      ),
    ],
  );
  tester.view.physicalSize = const Size(390, 4200);
  final repo = c.read(companyRepositoryProvider);
  await repo.demoApprove(CompanySeed.orangeId, _now);
  for (final id in people.keys) {
    await repo.enroll(id, now: _now.plusMinutes(5));
  }
  await repo.demoSetHrContact(CompanySeed.orangeId, c.read(dailyCommuteRepositoryProvider).meId, _now);
  c.read(routerProvider).go(Routes.company);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('company-dashboard')));
  await tester.pumpAndSettle();
  return c;
}

String _value(WidgetTester tester, String id) => (tester.widget(find.byKey(Key('dash-$id-value'))) as Text).data!;

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] removed by HR: the next trip carries the fee and the inbox says the plan ended', (tester) async {
      final clock = TestClock(_now);
      final c = await _enrolledEmployee(tester, code, clock);
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      expect(find.text(l.planCompanyOf('Valeo')), findsOneWidget, reason: 'enrolled: company card');

      // Two hours later HR removes them; the employee's side catches up the
      // next time the company area loads.
      clock.now = _now.plusMinutes(120);
      await c.read(companyRepositoryProvider).removeEmployee(CompanySeed.valeoId, _myEmail, clock.now);
      // No plan and no method sends a rider to "How will you pay" first (walk nit N-15,
      // by design), so a method is set before looking at Today.
      await c.read(walletRepositoryProvider).setMethod(c.read(dailyCommuteRepositoryProvider).meId, PaymentMethod.instapay);
      c.invalidate(companyAccountProvider);
      c.read(routerProvider).go(Routes.today);
      await tester.pumpAndSettle();
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();

      expect(find.text(l.planCompanyOf('Valeo')), findsNothing);
      expect(find.byKey(const Key('company-leave')), findsNothing);
      // Per-trip plan with Goora's fee back: 40 EGP share → 4 EGP fee.
      expect((tester.widget(find.byKey(const Key('plan-line'))) as Text).data, l.planPerTripLine(4));
      expect(await c.read(companyRepositoryProvider).offerFor(c.read(dailyCommuteRepositoryProvider).meId, clock.now),
          isA<CanEnroll>(),
          reason: 'removed, not blocked: they may enroll again');

      c.read(routerProvider).go(Routes.today);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inbox')));
      await tester.pumpAndSettle();
      expect(find.text(l.nCompanyPlanEnded('Valeo')), findsOneWidget);
    });

    testWidgets('[$code] 5 employees: the headcount shows, every figure built from fewer says "Fewer than 5"',
        (tester) async {
      await _orangeHr(tester, code, headcount: 5);
      expect(_value(tester, 'enrolled'), '5');
      for (final id in ['active', 'carpool', 'groups', 'trips', 'saved', 'co2', 'parking']) {
        expect(_value(tester, id), l.companyDashboardFewer, reason: id);
      }
      expect(find.byKey(const Key('dash-fewer-note')), findsOneWidget);
      expect(find.text(l.companyDashboardGapsEmpty), findsOneWidget);
    });

    testWidgets('[$code] 4 employees: even the headcount is hidden', (tester) async {
      await _orangeHr(tester, code, headcount: 4);
      expect(_value(tester, 'enrolled'), l.companyDashboardFewer);
    });
  }
}
