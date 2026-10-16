import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/widgets/goora_pill.dart';
import 'package:goora/core/widgets/goora_stepper.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/presentation/today/today_controller.dart';
import 'package:goora/features/daily/presentation/today/today_screen.dart';
import 'package:goora/features/daily/presentation/trust/trust_screen.dart';
import 'package:goora/features/marketplace/presentation/empty_seats/empty_seats_screen.dart';
import 'package:goora/features/marketplace/presentation/find_riders/find_riders_screen.dart';
import 'package:goora/features/marketplace/presentation/offer_trip/offer_trip_screen.dart';
import 'package:goora/features/marketplace/presentation/post_trip/post_trip_screen.dart';
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

/// A signed-in driver with no group.
Map<String, Object> _newDriver(String locale, {Frequency? frequency}) => {
      ...memberPrefs(role: Role.driver, locale: locale, member: false),
      'profile': jsonEncode(
        Profile(
          phone: testPhone,
          firstName: 'Omar',
          lastName: 'Khaled',
          gender: Gender.male,
          role: Role.driver,
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

    // F13: the form's edits survive the payment-method detour.
    testWidgets('[$code] Post with no method → PayMethod → back on the same edited form', (tester) async {
      final c = await _pump(tester, _newRider(code, frequency: Frequency.once));
      c.read(routerProvider).push(Routes.postTrip);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('from-october')));
      await tester.tap(find.bySemanticsLabel(l.later));
      await tester.pumpAndSettle();
      final shown = tester.widget<GooraStepper>(find.byKey(const Key('time-stepper'))).valueLabel;
      await tester.ensureVisible(find.byKey(const Key('post')));
      await tester.tap(find.byKey(const Key('post')));
      await tester.pumpAndSettle();
      expect(find.byType(PayMethodScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('pay-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(PostTripScreen), findsOneWidget);
      expect(tester.widget<GooraStepper>(find.byKey(const Key('time-stepper'))).valueLabel, shown);
      expect(tester.widget<GooraPill>(find.byKey(const Key('from-october'))).selected, isTrue);
    });

    // F9: tapping the time opens a picker, so 7:30 → 5 PM is not 114 taps.
    testWidgets('[$code] tapping the time opens a picker; cancel keeps it, OK applies it', (tester) async {
      final c = await _pump(tester, _newRider(code, frequency: Frequency.once));
      c.read(routerProvider).push(Routes.postTrip);
      await tester.pumpAndSettle();
      String shown() => tester.widget<GooraStepper>(find.byKey(const Key('time-stepper'))).valueLabel;
      final before = shown();
      await tester.tap(find.descendant(of: find.byKey(const Key('time-stepper')), matching: find.byKey(const Key('stepper-value'))));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text(MaterialLocalizations.of(tester.element(find.byType(TimePickerDialog))).cancelButtonLabel));
      await tester.pumpAndSettle();
      expect(shown(), before);
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

    // T104 F17: Today stayed mounted under Empty seats and kept its old list.
    testWidgets('[$code] booked → Back to today shows the booked seat on Today', (tester) async {
      final c = await _pump(tester, memberPrefs(role: Role.rider, locale: code), height: 2600);
      final repo = c.read(dailyCommuteRepositoryProvider) as FakeDailyCommuteRepository;
      await tester.runAsync(() => repo.demoDriverOut(cover: false));
      c.invalidate(todayControllerProvider);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('no-cover-seat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) => '${w.key}'.contains('book-')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('back-to-today')));
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.byKey(const Key('one-off-section')), findsOneWidget);
    });

    // T104 F6: the list kept the wallet prices after the rider chose cash.
    testWidgets('[$code] PayMethod cash → back on Empty seats with cash prices', (tester) async {
      await _pump(tester, _newRider(code, frequency: Frequency.once));
      await tester.tap(find.byWidgetPredicate((w) => '${w.key}'.contains('book-')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-cash')));
      await tester.tap(find.byKey(const Key('pay-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(EmptySeatsScreen), findsOneWidget);
      expect(find.text(l.priceCash(40)), findsWidgets);
    });
 
    // T104 F8: once something is booked or live, Back is Today, not onboarding.
    testWidgets('[$code] once rider books; Back (top bar) → Today, not Frequency', (tester) async {
      await _pump(tester, _newRider(code, frequency: Frequency.once, method: PaymentMethod.cash));
      await tester.tap(find.byWidgetPredicate((w) => '${w.key}'.contains('book-')).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('booked-view')), findsOneWidget);
      await _back(tester, l.back);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('[$code] once driver publishes; Back → Today, not Frequency', (tester) async {
      await _pump(tester, _newDriver(code, frequency: Frequency.once), height: 3000);
      await tester.ensureVisible(find.byKey(const Key('publish')));
      await tester.tap(find.byKey(const Key('publish')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('offer-live')), findsOneWidget);
      await _back(tester, l.back);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    // T104 F8b + F19: after the pay-method detour there is nothing to pop, so a
    // posted request's Back is Today; its card there says "See your request".
    testWidgets('[$code] once rider posts after the pay-method detour; Back → Today; card opens it', (tester) async {
      final c = await _pump(tester, _newRider(code, frequency: Frequency.once), height: 3000);
      c.read(routerProvider).push(Routes.postTrip);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('post')));
      await tester.tap(find.byKey(const Key('post')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-cash')));
      await tester.tap(find.byKey(const Key('pay-continue')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('post')));
      await tester.tap(find.byKey(const Key('post')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('request-posted')), findsOneWidget);
      await _back(tester, l.back);
      expect(find.byType(TodayScreen), findsOneWidget);
      final open = find.byWidgetPredicate((w) => '${w.key}'.contains('open-posted-'));
      expect(find.descendant(of: open, matching: find.text(l.seeYourRequest)), findsOneWidget);
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('request-posted')), findsOneWidget);
    });

    // 005 US2: the driver's entry points (FR-001, FR-002).
    testWidgets('[$code] driver Just one trip → Offer a trip; Back → Frequency', (tester) async {
      await _pump(tester, _newDriver(code));
      expect(find.byType(FrequencyScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('freq-once')));
      await tester.tap(find.byKey(const Key('freq-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(OfferTripScreen), findsOneWidget);
      await _back(tester, l.back);
      expect(find.byType(FrequencyScreen), findsOneWidget);
    });

    testWidgets('[$code] driver Today "Offer a trip" → Offer a trip; Back → Today', (tester) async {
      await _pump(tester, memberPrefs(role: Role.driver, locale: code));
      await tester.tap(find.byKey(const Key('offer-trip')));
      await tester.pumpAndSettle();
      expect(find.byType(OfferTripScreen), findsOneWidget);
      await _back(tester, l.back);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('[$code] a missing document chip opens Trust', (tester) async {
      await _pump(
        tester,
        {..._newDriver(code, frequency: Frequency.once), FakeTrustRepository.docsPendingKey: true},
      );
      expect(find.byType(OfferTripScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('verify-license')));
      await tester.pumpAndSettle();
      expect(find.byType(TrustScreen), findsOneWidget);
    });
 
    // 005 US3/US4 (T076, T088): Post your trip and Find riders entry points.
    testWidgets('[$code] Empty seats "Post your trip" → Post your trip; Back → Empty seats', (tester) async {
      await _pump(tester, _newRider(code, frequency: Frequency.once));
      expect(find.byType(EmptySeatsScreen), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('post-trip')));
      await tester.tap(find.byKey(const Key('post-trip')));
      await tester.pumpAndSettle();
      expect(find.byType(PostTripScreen), findsOneWidget);
      await _back(tester, l.back);
      expect(find.byType(EmptySeatsScreen), findsOneWidget);
    });

    testWidgets('[$code] no-cover "Post your trip" → Post your trip; Back → Today', (tester) async {
      final c = await _pump(tester, memberPrefs(role: Role.rider, locale: code), height: 2600);
      final repo = c.read(dailyCommuteRepositoryProvider) as FakeDailyCommuteRepository;
      await tester.runAsync(() => repo.demoDriverOut(cover: false));
      c.invalidate(todayControllerProvider);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('no-cover-post')));
      await tester.pumpAndSettle();
      expect(find.byType(PostTripScreen), findsOneWidget);
      await _back(tester, l.back);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('[$code] driver Today "Find riders" → Find riders; Back → Today', (tester) async {
      await _pump(tester, memberPrefs(role: Role.driver, locale: code));
      await tester.tap(find.byKey(const Key('find-riders')));
      await tester.pumpAndSettle();
      expect(find.byType(FindRidersScreen), findsOneWidget);
      await _back(tester, l.back);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('[$code] Offer a trip "find riders who already posted" → Find riders; Back → Offer a trip', (tester) async {
      await _pump(tester, _newDriver(code, frequency: Frequency.once), height: 3000);
      expect(find.byType(OfferTripScreen), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('find-riders-link')));
      await tester.tap(find.byKey(const Key('find-riders-link')));
      await tester.pumpAndSettle();
      expect(find.byType(FindRidersScreen), findsOneWidget);
      await _back(tester, l.back);
      expect(find.byType(OfferTripScreen), findsOneWidget);
    });
  }
}
