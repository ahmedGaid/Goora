import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/presentation/today/today_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/presentation/pay_method/pay_method_screen.dart';
import 'package:goora/features/wallet/presentation/plan/plan_screen.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// v2 US1: choosing how to pay right after joining, ar + en.
Future<ProviderContainer> _openAsNewRider(WidgetTester tester, String locale) async {
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale, withPlan: false),
    overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
  );
  tester.view.physicalSize = const Size(390, 2400);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] AC1: a rider with no arrangement lands here — cash, wallet and the subscribe link',
        (tester) async {
      await _openAsNewRider(tester, code);
      expect(find.byType(PayMethodScreen), findsOneWidget);
      expect(find.text(l.payMethodTitle), findsOneWidget);
      expect(find.text(l.payCash), findsOneWidget);
      expect(find.text(l.payWallet), findsOneWidget);
      expect(find.text(l.priceWithFee(40, 4)), findsOneWidget, reason: 'the wallet option shows its real price');
      expect(find.text(l.subscribeLink), findsOneWidget);
    });

    testWidgets('[$code] AC2: cash → Today shows "Pay 40 EGP cash to the driver"', (tester) async {
      final c = await _openAsNewRider(tester, code);
      await tester.tap(find.byKey(const Key('pay-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      expect(await c.read(walletRepositoryProvider).getMethod(meId), PaymentMethod.cash);
      expect(find.text(l.priceCash(40)), findsOneWidget);
    });

    testWidgets('[$code] AC3: wallet → Today shows "40 EGP to the driver + 4 EGP service fee"', (tester) async {
      await _openAsNewRider(tester, code);
      await tester.tap(find.byKey(const Key('pay-wallet')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.text(l.priceWithFee(40, 4)), findsOneWidget);
      expect(find.text(l.egpAmount(44)), findsOneWidget, reason: 'the pay tile shows what the rider pays');
    });

    testWidgets('[$code] AC4: the link opens the subscription screen', (tester) async {
      await _openAsNewRider(tester, code);
      await tester.tap(find.byKey(const Key('subscribe-link')));
      await tester.pumpAndSettle();
      expect(find.byType(PlanScreen), findsOneWidget);
    });

    testWidgets('[$code] AC5: a driver never sees the payment-method screen', (tester) async {
      await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.driver, locale: code),
        overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PayMethodScreen), findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('[$code] AC6: until a choice is made, Today keeps coming back here', (tester) async {
      final c = await _openAsNewRider(tester, code);
      c.read(routerProvider).go(Routes.today);
      await tester.pumpAndSettle();
      expect(find.byType(PayMethodScreen), findsOneWidget);
    });
  }
}
