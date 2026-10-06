import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/presentation/today/today_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/presentation/plan/plan_screen.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US1: the plan screen, ar + en (T024).
Future<ProviderContainer> _openAsRider(WidgetTester tester, String locale) async {
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale, withPlan: false),
    overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
  );
  tester.view.physicalSize = const Size(390, 2200);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] AC1: a rider with no plan lands here with every element present', (tester) async {
      await _openAsRider(tester, code);
      expect(find.text(l.planTitle), findsOneWidget);
      expect(find.text(l.planSubline), findsOneWidget);
      expect(find.byKey(const Key('plan-monthly')), findsOneWidget);
      expect(find.byKey(const Key('plan-yearly')), findsOneWidget);
      expect(find.byKey(const Key('plan-company')), findsOneWidget);
      expect(find.text(l.planYearlyChip), findsOneWidget);
      expect(find.text(l.planIncludedTitle), findsOneWidget);
      expect(find.text(l.planFuelNote), findsOneWidget);
      expect(find.text(l.planFooter), findsOneWidget);
    });

    testWidgets('[$code] AC2: choosing Monthly starts a free month with no charge', (tester) async {
      final c = await _openAsRider(tester, code);
      expect(find.text(l.planCtaStart), findsOneWidget);
      await tester.tap(find.byKey(const Key('plan-cta')));
      await tester.pumpAndSettle();

      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final plan = await c.read(walletRepositoryProvider).getPlan(meId);
      expect(plan, isNotNull);
      expect(plan!.price, 129);
      expect(plan.untilDate, rideTuesday.addMonths(1));
      expect(find.byType(TodayScreen), findsOneWidget, reason: 'plan chosen, no longer redirected');
    });

    testWidgets('[$code] AC2: choosing Yearly starts a free month at the yearly price', (tester) async {
      final c = await _openAsRider(tester, code);
      await tester.tap(find.byKey(const Key('plan-yearly')));
      await tester.pumpAndSettle();
      expect(find.text(l.planCtaStart), findsOneWidget);
      await tester.tap(find.byKey(const Key('plan-cta')));
      await tester.pumpAndSettle();

      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final plan = await c.read(walletRepositoryProvider).getPlan(meId);
      expect(plan!.price, 1290);
      expect(plan.untilDate, rideTuesday.addMonths(1));
    });

    testWidgets('[$code] AC3: Through my company verifies and starts a free, trial-less Company plan',
        (tester) async {
      final c = await _openAsRider(tester, code);
      await tester.tap(find.byKey(const Key('plan-company')));
      await tester.pumpAndSettle();
      expect(find.text(l.planCtaVerify), findsOneWidget);
      await tester.tap(find.byKey(const Key('plan-cta')));
      await tester.pumpAndSettle();

      expect(find.text(l.verifyEmailTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('verify-confirm')));
      await tester.pumpAndSettle();

      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final plan = await c.read(walletRepositoryProvider).getPlan(meId);
      expect(plan!.price, 0);
      expect(plan.untilDate, isNull);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('[$code] AC4: a driver never sees the plan screen', (tester) async {
      await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.driver, locale: code),
        overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PlanScreen), findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('[$code] AC5: without a plan, Today/Week keep redirecting back to the plan screen',
        (tester) async {
      final c = await _openAsRider(tester, code);
      expect(find.byType(PlanScreen), findsOneWidget);
      c.read(routerProvider).go(Routes.today);
      await tester.pumpAndSettle();
      expect(find.byType(PlanScreen), findsOneWidget, reason: 'no plan chosen yet — still redirected');
    });
  }
}
