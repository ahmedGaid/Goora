import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// T066: Today, Week, Trust and the sheets at 1.3× text, with 44 pt tap
/// targets and labelled buttons (constitution VII), ar + en.
Future<void> _pump(WidgetTester tester, Role role, String locale) async {
  await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: role, locale: locale),
    overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 13))),
  );
  tester.view.physicalSize = const Size(390, 3600);
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  await tester.pumpAndSettle();
}

Future<void> _accessible(WidgetTester tester, String where) async {
  expect(tester.takeException(), isNull, reason: '$where overflowed at 1.3×');
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline), reason: where);
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline), reason: where);
  handle.dispose();
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] rider: Today, Week, Trust and sheets', (tester) async {
      await _pump(tester, Role.rider, code);
      await _accessible(tester, 'rider Today');

      await tester.tap(find.byKey(const Key('sos')));
      await tester.pumpAndSettle();
      await _accessible(tester, 'SOS sheet');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cant-come')));
      await tester.pumpAndSettle();
      await _accessible(tester, "can't-come sheet");
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l.tabWeek));
      await tester.pumpAndSettle();
      await _accessible(tester, 'Week');

      await tester.tap(find.text(l.tabTrust));
      await tester.pumpAndSettle();
      await _accessible(tester, 'Trust');
    });

    testWidgets('[$code] driver: Today', (tester) async {
      await _pump(tester, Role.driver, code);
      await _accessible(tester, 'driver Today');
    });
  }
}
