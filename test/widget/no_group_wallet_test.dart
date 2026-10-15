import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 005 T104 F3: a rider or driver with no group ("Just one trip") has no
/// group price, so the wallet must quote the corridor's standard 160 ÷ 3
/// basis (40 + 4 fee), not zeros.
Future<ProviderContainer> _open(
  WidgetTester tester,
  String locale, {
  required Role role,
  PaymentMethod method = PaymentMethod.wallet,
  String route = Routes.wallet,
  int balance = 0,
}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {
      ...memberPrefs(
        role: role,
        locale: locale,
        member: false,
        withPlan: false,
        method: method,
      ),
      if (balance > 0) 'wallet.balance.me': balance,
    },
    overrides: dailyOverrides(TestClock(at(rideTuesday, 21, 0))),
  );
  tester.view.physicalSize = const Size(390, 3400);
  c.read(routerProvider).go(route);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets(
      '[$code] F3: no-group rider on the wallet — plan card quotes the 4 EGP fee',
      (tester) async {
        await _open(tester, code, role: Role.rider);
        expect(find.text(l.planPerTripLine(4)), findsOneWidget);
        expect(find.text(l.planPerTripNoFeeLine), findsNothing);
      },
    );

    testWidgets(
      '[$code] F3: no-group rider — breakdown reads 40 + 4 = 44, not zeros',
      (tester) async {
        await _open(tester, code, role: Role.rider);
        final breakdown = find.byKey(const Key('breakdown'));
        expect(
          find.descendant(of: breakdown, matching: find.text(l.egpAmount(40))),
          findsOneWidget,
        );
        expect(
          find.descendant(of: breakdown, matching: find.text(l.egpAmount(4))),
          findsOneWidget,
        );
        expect(
          find.descendant(of: breakdown, matching: find.text(l.egpAmount(44))),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '[$code] F3: no-group rider at balance 156 — covers 1 round trip (156 ÷ 88)',
      (tester) async {
        await _open(tester, code, role: Role.rider, balance: 156);
        expect(find.text(l.coversTrips(1)), findsOneWidget);
        expect(find.text(l.coversTrips(0)), findsNothing);
      },
    );

    testWidgets(
      '[$code] F3: no-group cash rider — plan card says pay 40 cash, not 0',
      (tester) async {
        await _open(tester, code, role: Role.rider, method: PaymentMethod.cash);
        expect(find.text(l.priceCash(40)), findsOneWidget);
        expect(find.text(l.priceCash(0)), findsNothing);
      },
    );

    testWidgets(
      '[$code] F3: pay-method screen — wallet option shows 40 + 4 with no group',
      (tester) async {
        await _open(tester, code, role: Role.rider, route: Routes.payMethod);
        final wallet = find.byKey(const Key('pay-wallet'));
        expect(
          find.descendant(
            of: wallet,
            matching: find.text(l.priceWithFee(40, 4)),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('[$code] F3: no-group driver — no zero trip-cost breakdown', (
      tester,
    ) async {
      await _open(tester, code, role: Role.driver);
      expect(find.text(l.recoveredTitle), findsOneWidget);
      expect(find.text(l.driverBreakdownTitle), findsNothing);
    });
  }
}
