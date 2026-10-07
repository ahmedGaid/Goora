import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/l10n/app_localizations.dart';
import 'package:goora/core/theme/app_spacing.dart';
import 'package:goora/core/theme/app_theme.dart';
import 'package:goora/core/widgets/goora_balance_card.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/presentation/wallet/change_plan_sheet.dart';
import 'package:goora/features/wallet/presentation/wallet/top_up_sheet.dart';
import 'package:goora/features/wallet/presentation/wallet/withdraw_sheet.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 004 core widgets (T017) + full-screen/sheet coverage (T041). Regenerate
/// with `flutter test --update-goldens test/golden` after an intended
/// visual change.
void main() {
  for (final locale in locales) {
    final dir = locale == ar ? 'rtl' : 'ltr';
    final code = locale.languageCode;

    testWidgets('wallet widgets [$dir]', (tester) async {
      await loadAppFonts();
      tester.view.physicalSize = const Size(390, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: locales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(locale),
          home: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context);
              return Scaffold(
                body: Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.tabH),
                  child: GooraBalanceCard(
                    balanceLabel: l.balanceLabel,
                    balanceValue: l.egpAmount(320),
                    tripsCaption: l.coversTrips(4),
                    topUpLabel: l.topUp,
                    onTopUp: () {},
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/wallet_widgets_$dir.png'));
    });

    testWidgets('plan screen [$dir]', (tester) async {
      await loadAppFonts();
      addTearDown(tester.view.reset);
      await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.rider, locale: code, withPlan: false),
        overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
      );
      tester.view.physicalSize = const Size(390, 2200);
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/screen_plan_$dir.png'));
    });

    testWidgets('rider wallet [$dir]', (tester) async {
      await loadAppFonts();
      addTearDown(tester.view.reset);
      final c = await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.rider, locale: code, withPlan: true),
        overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
      );
      tester.view.physicalSize = const Size(390, 2600);
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/screen_wallet_rider_$dir.png'));
    });

    testWidgets('driver wallet [$dir]', (tester) async {
      await loadAppFonts();
      addTearDown(tester.view.reset);
      final c = await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.driver, locale: code),
        overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
      );
      tester.view.physicalSize = const Size(390, 2600);
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/screen_wallet_driver_$dir.png'));
    });

    testWidgets('top-up sheet [$dir]', (tester) async {
      await loadAppFonts();
      addTearDown(tester.view.reset);
      final c = await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.rider, locale: code, withPlan: true),
        overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
      );
      tester.view.physicalSize = const Size(390, 2600);
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('top-up')));
      await tester.pumpAndSettle();
      await expectLater(find.byType(TopUpSheet), matchesGoldenFile('goldens/sheet_top_up_$dir.png'));
    });

    testWidgets('change-plan sheet [$dir]', (tester) async {
      await loadAppFonts();
      addTearDown(tester.view.reset);
      final c = await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.rider, locale: code, withPlan: true),
        overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
      );
      tester.view.physicalSize = const Size(390, 2600);
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plan-change')));
      await tester.pumpAndSettle();
      await expectLater(find.byType(ChangePlanSheet), matchesGoldenFile('goldens/sheet_change_plan_$dir.png'));
    });

    testWidgets('withdraw sheet [$dir]', (tester) async {
      await loadAppFonts();
      addTearDown(tester.view.reset);
      final c = await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.driver, locale: code),
        overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
      );
      tester.view.physicalSize = const Size(390, 2600);
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('withdraw')));
      await tester.pumpAndSettle();
      await expectLater(find.byType(WithdrawSheet), matchesGoldenFile('goldens/sheet_withdraw_$dir.png'));
    });
  }
}
