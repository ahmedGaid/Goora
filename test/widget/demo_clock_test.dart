import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// T104 F23: Settings → Demo "Ride day 7:15" / "8:55 PM" / "9:05 PM" must move
/// the clock for a once rider who has no group, falling back to the next
/// Sun–Thu instead of silently doing nothing.
final _fri = CalendarDate(2026, 10, 9);

Map<String, Object> _prefs(String locale) => {
      ...memberPrefs(role: Role.rider, member: false, locale: locale, withPlan: false),
      'profile': jsonEncode(
        Profile(
          phone: testPhone,
          firstName: 'Omar',
          lastName: 'Khaled',
          gender: Gender.male,
          role: Role.rider,
          frequency: Frequency.once,
        ).toJson(),
      ),
    };

Future<String?> _tap(WidgetTester tester, ProviderContainer c, String key) async {
  unawaited(c.read(routerProvider).push(Routes.settings));
  await tester.pumpAndSettle();
  final button = find.byKey(Key(key));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  final demo = DemoClock.read(c.read(sharedPreferencesProvider));
  return demo == null ? null : '${demo.at.date.toIso()} ${demo.at.time.hour}:${demo.at.time.minute}';
}

void main() {
  for (final locale in locales) {
    final code = locale.languageCode;

    testWidgets('[$code] no group, Friday: "Ride day 7:15" jumps to Sunday 7:15', (tester) async {
      final c = await pumpGooraApp(tester, prefs: _prefs(code), overrides: dailyOverrides(TestClock(at(_fri, 12, 0))));
      expect(await _tap(tester, c, 'demo-ride-day'), '2026-10-11 7:15');
    });

    testWidgets('[$code] no group, Friday: "8:55 PM" and "9:05 PM" land on Saturday evening', (tester) async {
      final c = await pumpGooraApp(tester, prefs: _prefs(code), overrides: dailyOverrides(TestClock(at(_fri, 12, 0))));
      expect(await _tap(tester, c, 'demo-855'), '2026-10-10 20:55');
      expect(await _tap(tester, c, 'demo-905'), '2026-10-10 21:5');
    });
  }
}
