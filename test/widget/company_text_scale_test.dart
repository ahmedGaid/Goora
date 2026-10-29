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

/// 010 T051: at 1.3× text size the dashboard and the invoice screens still lay
/// out — an overflow or clipped line throws in a widget test, so reaching the
/// end without an exception is the check — ar + en.
final _now = at(rideTuesday, 10, 0);

Future<void> _open(WidgetTester tester, String locale, String buttonKey) async {
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale),
    overrides: dailyOverrides(TestClock(_now)),
  );
  tester.view.physicalSize = const Size(390, 2400);
  await c
      .read(companyRepositoryProvider)
      .demoSetHrContact(CompanySeed.valeoId, c.read(dailyCommuteRepositoryProvider).meId, _now);
  c.read(routerProvider).go(Routes.company);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(buttonKey)));
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in locales) {
    final code = locale.languageCode;

    testWidgets('[$code] dashboard at 1.3x text', (tester) async {
      await _open(tester, code, 'company-dashboard');
      expect(find.byKey(const Key('company-dashboard-screen')), findsOneWidget);
      expect(find.byKey(const Key('dash-saved-value')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('[$code] invoice list and invoice at 1.3x text', (tester) async {
      await _open(tester, code, 'company-invoices');
      expect(find.byKey(const Key('company-invoices-screen')), findsOneWidget);
      await tester.tap(find.byKey(const Key('invoice-2026-09')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('company-invoice-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
