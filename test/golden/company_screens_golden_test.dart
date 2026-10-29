import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 010 T050: the company home, consent sheet, invoice and dashboard in ar
/// (rtl) and en (ltr). Windows only, like the rest. Regenerate with
/// `flutter test --update-goldens test/golden` after an intended visual change.
final _now = at(rideTuesday, 10, 0);

Future<ProviderContainer> _pump(WidgetTester tester, String locale, {required bool hr, double height = 2400}) async {
  await loadAppFonts();
  addTearDown(tester.view.reset);
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale, withPlan: hr),
    overrides: dailyOverrides(TestClock(_now)),
  );
  tester.view.physicalSize = Size(390, height);
  if (hr) {
    await c
        .read(companyRepositoryProvider)
        .demoSetHrContact(CompanySeed.valeoId, c.read(dailyCommuteRepositoryProvider).meId, _now);
  }
  return c;
}

Future<void> _shot(WidgetTester tester, String name, String dir) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/company_${name}_$dir.png'));

void main() {
  for (final locale in locales) {
    final dir = locale == ar ? 'rtl' : 'ltr';
    final code = locale.languageCode;

    testWidgets('company home [$dir]', (tester) async {
      final c = await _pump(tester, code, hr: true);
      c.read(routerProvider).go(Routes.company);
      await tester.pumpAndSettle();
      await _shot(tester, 'home', dir);
    });

    testWidgets('consent sheet [$dir]', (tester) async {
      final c = await _pump(tester, code, hr: false, height: 1500);
      c.read(routerProvider).go(Routes.plan);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plan-company')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plan-cta')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('company-join')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('consent-agree')), findsOneWidget);
      await _shot(tester, 'consent', dir);
    });

    testWidgets('invoice [$dir]', (tester) async {
      final c = await _pump(tester, code, hr: true);
      c.read(routerProvider).go(Routes.company);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('company-invoices')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('invoice-2026-09')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('company-invoice-screen')), findsOneWidget);
      await _shot(tester, 'invoice', dir);
    });

    testWidgets('dashboard [$dir]', (tester) async {
      final c = await _pump(tester, code, hr: true, height: 3200);
      c.read(routerProvider).go(Routes.company);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('company-dashboard')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dashboard-month-2026-09')));
      await tester.pumpAndSettle();
      await _shot(tester, 'dashboard', dir);
    });
  }
}
