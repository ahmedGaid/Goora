import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/presentation/today/today_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/plan.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// v2 US3: the optional subscription screen, paid from the wallet, ar + en.
Future<ProviderContainer> _openSubscription(WidgetTester tester, String locale, {int balance = 0}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {
      ...memberPrefs(role: Role.rider, locale: locale, withPlan: false),
      'wallet.balance.me': balance,
    },
    overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
  );
  tester.view.physicalSize = const Size(390, 2400);
  c.read(routerProvider).go(Routes.plan);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] the subscription screen: three plans, no free-month copy', (tester) async {
      await _openSubscription(tester, code);
      expect(find.text(l.planTitle), findsOneWidget);
      expect(find.text(l.planSubline), findsOneWidget);
      expect(find.byKey(const Key('plan-monthly')), findsOneWidget);
      expect(find.byKey(const Key('plan-yearly')), findsOneWidget);
      expect(find.byKey(const Key('plan-company')), findsOneWidget);
      expect(find.text(l.planYearlyChip), findsOneWidget);
      expect(find.text(l.subscribeCta(129)), findsOneWidget);
      expect(find.text(l.planFooter), findsOneWidget);
    });

    testWidgets('[$code] AC1: Monthly with 200 in the wallet → 129 charged, plan active, on to Today',
        (tester) async {
      final c = await _openSubscription(tester, code, balance: 200);
      await tester.tap(find.byKey(const Key('plan-cta')));
      await tester.pumpAndSettle();
      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final plan = (await c.read(walletRepositoryProvider).getPlan(meId))!;
      expect(plan.type, PlanType.monthly);
      expect(plan.untilDate, rideTuesday.addMonths(1));
      expect((await c.read(walletRepositoryProvider).getWallet(meId)).balance, 71);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.text(l.priceSubscribed(40)), findsOneWidget, reason: 'AC2: no fee once subscribed');
    });

    testWidgets('[$code] Yearly shows its 1,290 price on the button', (tester) async {
      await _openSubscription(tester, code);
      await tester.tap(find.byKey(const Key('plan-yearly')));
      await tester.pumpAndSettle();
      expect(find.text(l.subscribeCta(1290)), findsOneWidget);
    });

    testWidgets('[$code] AC3: not enough balance → "top up first", nothing charged', (tester) async {
      final c = await _openSubscription(tester, code, balance: 100);
      await tester.tap(find.byKey(const Key('plan-cta')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sub-needs-top-up')), findsOneWidget);
      expect(find.text(l.subNeedsTopUp(29, 100)), findsOneWidget);
      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      expect(await c.read(walletRepositoryProvider).getPlan(meId), isNull);
      expect((await c.read(walletRepositoryProvider).getWallet(meId)).balance, 100);
    });

    testWidgets('[$code] AC4: Through my company verifies and costs nothing', (tester) async {
      final c = await _openSubscription(tester, code);
      await tester.tap(find.byKey(const Key('plan-company')));
      await tester.pumpAndSettle();
      expect(find.text(l.planCtaVerify), findsOneWidget);
      await tester.tap(find.byKey(const Key('plan-cta')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('verify-confirm')));
      await tester.pumpAndSettle();
      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      expect((await c.read(walletRepositoryProvider).getPlan(meId))!.type, PlanType.company);
      expect((await c.read(walletRepositoryProvider).getWallet(meId)).balance, 0);
      expect(find.byType(TodayScreen), findsOneWidget);
    });
  }
}
