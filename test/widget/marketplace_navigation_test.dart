import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/presentation/today/today_controller.dart';
import 'package:goora/features/daily/presentation/today/today_screen.dart';
import 'package:goora/features/marketplace/presentation/empty_seats/empty_seats_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/frequency_screen.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/presentation/pay_method/pay_method_screen.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 005 US1 entry points and Back (FR-001, FR-002), ar + en.
final _mondayEvening = at(rideTuesday.addDays(-1), 18, 0);

/// A signed-in rider with no group and no payment arrangement.
Map<String, Object> _newRider(String locale, {Frequency? frequency, PaymentMethod? method}) => {
      ...memberPrefs(role: Role.rider, locale: locale, member: false, withPlan: false, method: method),
      'profile': jsonEncode(
        Profile(
          phone: testPhone,
          firstName: 'Omar',
          lastName: 'Khaled',
          gender: Gender.male,
          role: Role.rider,
          frequency: frequency,
        ).toJson(),
      ),
    };

Future<ProviderContainer> _pump(WidgetTester tester, Map<String, Object> prefs, {int height = 2400}) async {
  final c = await pumpGooraApp(tester, prefs: prefs, overrides: dailyOverrides(TestClock(_mondayEvening)));
  tester.view.physicalSize = Size(390, height.toDouble());
  await tester.pumpAndSettle();
  return c;
}

Future<void> _back(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] Just one trip → Empty seats; Back → Frequency', (tester) async {
      await _pump(tester, _newRider(code));
      expect(find.byType(FrequencyScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('freq-once')));
      await tester.tap(find.byKey(const Key('freq-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(EmptySeatsScreen), findsOneWidget);
      await _back(tester, l.back);
      expect(find.byType(FrequencyScreen), findsOneWidget);
    });

    testWidgets('[$code] Today "Need an extra trip?" → Empty seats; Back → Today', (tester) async {
      await _pump(tester, memberPrefs(role: Role.rider, locale: code));
      await tester.tap(find.byKey(const Key('extra-trip')));
      await tester.pumpAndSettle();
      expect(find.byType(EmptySeatsScreen), findsOneWidget);
      await _back(tester, l.back);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('[$code] no-cover "Book an empty seat" opens the leg the day lost; Back → Today', (tester) async {
      final c = await _pump(tester, memberPrefs(role: Role.rider, locale: code), height: 2600);
      final repo = c.read(dailyCommuteRepositoryProvider) as FakeDailyCommuteRepository;
      await tester.runAsync(() => repo.demoDriverOut(cover: false));
      c.invalidate(todayControllerProvider);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('no-cover-seat')));
      await tester.pumpAndSettle();
      expect(find.byType(EmptySeatsScreen), findsOneWidget);
      expect(tester.widget<EmptySeatsScreen>(find.byType(EmptySeatsScreen)).leg, Leg.going);
      await _back(tester, l.back);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('[$code] Book with no method → PayMethod → back to the same seat', (tester) async {
      await _pump(tester, _newRider(code, frequency: Frequency.once));
      expect(find.byType(EmptySeatsScreen), findsOneWidget);
      final book = find.byWidgetPredicate((w) => w.key is Key && '${w.key}'.contains('book-')).first;
      final key = (tester.widget(book).key! as ValueKey<String>).value.substring('book-'.length);
      await tester.tap(book);
      await tester.pumpAndSettle();
      expect(find.byType(PayMethodScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('pay-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(EmptySeatsScreen), findsOneWidget, reason: 'not Today');
      expect(find.byKey(const Key('seat-chosen')), findsOneWidget);
      expect(find.byKey(Key('book-$key')), findsOneWidget, reason: 'the same seat, still bookable');
    });

    testWidgets('[$code] booked upsell opens commute setup', (tester) async {
      await _pump(tester, _newRider(code, frequency: Frequency.once, method: PaymentMethod.cash));
      expect(find.byType(EmptySeatsScreen), findsOneWidget);
      await tester.tap(find.byWidgetPredicate((w) => '${w.key}'.contains('book-')).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('upsell-daily')), findsOneWidget);
      await tester.tap(find.byKey(const Key('upsell-daily')));
      await tester.pumpAndSettle();
      expect(find.text(l.whereGo), findsOneWidget);
    });

    // A member only sees seats on a leg they don't already ride, so the way in
    // is the day their driver can't cover.
    testWidgets('[$code] SC-001: a group member books in at most 3 taps from Today', (tester) async {
      final c = await _pump(tester, memberPrefs(role: Role.rider, locale: code), height: 2600);
      final repo = c.read(dailyCommuteRepositoryProvider) as FakeDailyCommuteRepository;
      await tester.runAsync(() => repo.demoDriverOut(cover: false));
      c.invalidate(todayControllerProvider);
      await tester.pumpAndSettle();
      var taps = 0;
      Future<void> tap(Finder f) async {
        await tester.tap(f);
        await tester.pumpAndSettle();
        taps++;
      }

      await tap(find.byKey(const Key('no-cover-seat')));
      await tap(find.byWidgetPredicate((w) => '${w.key}'.contains('book-')).first);
      expect(find.byKey(const Key('booked-view')), findsOneWidget);
      expect(taps, lessThanOrEqualTo(3));
    });
  }
}
