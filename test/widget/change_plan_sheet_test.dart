import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/plan.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US2: the change-plan sheet — switching plans leaves the current plan
/// card unchanged until the next billing date (FR-004, T033).
void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;
    final until = rideTuesday.addDays(10);

    testWidgets('[$code] switching Monthly → Yearly keeps the current paid-until date', (tester) async {
      final c = await pumpGooraApp(
        tester,
        prefs: {
          ...memberPrefs(role: Role.rider, locale: code, withPlan: false),
          FakeWalletRepository.planKey: jsonEncode(
            Plan(
                personId: 'me',
                type: PlanType.monthly,
                status: PlanStatus.active,
                price: 129,
                startDate: at(rideTuesday.addDays(-20), 0, 0),
                untilDate: until)
                .toJson(),
          ),
        },
        overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
      );
      tester.view.physicalSize = const Size(390, 2600);
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('plan-change')));
      await tester.pumpAndSettle();
      expect(find.text(l.changePlanTitle), findsOneWidget);
      expect(find.text(l.changePlanNote), findsOneWidget);

      await tester.tap(find.byKey(const Key('change-plan-yearly')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('change-plan-confirm')));
      await tester.pumpAndSettle();

      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final plan = await c.read(walletRepositoryProvider).getPlan(meId);
      expect(plan!.type, PlanType.yearly);
      expect(plan.price, 1290);
      expect(plan.untilDate, until, reason: 'FR-004: no pro-rating — current period unaffected');
    });
  }
}
