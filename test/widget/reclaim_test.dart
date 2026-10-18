import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/domain/offered_trip.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 005 US6 (T094, T096): a subscriber takes a one-off seat before the 9 PM
/// cut-off and the booker gets everything back; after it the booking is final.
/// A once rider with a wallet books Khaled's trip on Wednesday at 9:00.
final _tue = rideTuesday;
final _wed = rideTuesday.addDays(1);

Map<String, Object> _prefs(String locale) => {
      ...memberPrefs(role: Role.rider, member: false, locale: locale, withPlan: false, method: PaymentMethod.instapay, pastTrial: true),
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
      FakeMarketplaceRepository.offersKey: jsonEncode([
        OfferedTrip(
          id: 'of-9',
          driverId: 'khaled',
          leg: Leg.going,
          from: Area.sheikhZayed,
          to: Area.smartVillage,
          date: _wed,
          departure: const Clock.hm(9, 0),
          seats: 3,
          riderSeats: 3,
          tripCost: MarketSeed.tripCost,
          contribution: 40,
          repeat: Repeat.once,
          pickup: MarketSeed.pickupIn(Area.sheikhZayed, 'of-stop-of-9', const Clock.hm(9, 0)),
        ).toJson(),
      ]),
    };

/// Books the seat on Empty seats, then opens Today.
Future<ProviderContainer> _booked(WidgetTester tester, TestClock clock, String locale) async {
  final c = await pumpGooraApp(tester, prefs: _prefs(locale), overrides: dailyOverrides(clock));
  tester.view.physicalSize = const Size(390, 3000);
  await c.read(walletRepositoryProvider).topUp(DailySeed.meId, method: 'card', amount: 200);
  await tester.pumpAndSettle();
  final book = find.byWidgetPredicate((w) => '${w.key}'.contains('book-offer:of-9'));
  await tester.ensureVisible(book);
  await tester.tap(book);
  await tester.pumpAndSettle();
  c.read(routerProvider).go(Routes.today);
  await tester.pumpAndSettle();
  return c;
}

/// Taps a Settings → Demo button, then comes back.
Future<void> _demo(WidgetTester tester, ProviderContainer c, String key) async {
  final router = c.read(routerProvider);
  unawaited(router.push(Routes.settings));
  await tester.pumpAndSettle();
  final button = find.byKey(Key(key));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] before 9 PM: the seat is taken, Today drops the trip and Wallet shows one Refund', (tester) async {
      final clock = TestClock(at(_tue, 12, 0));
      final c = await _booked(tester, clock, code);
      expect(find.byKey(const Key('one-off-bk-1')), findsOneWidget);
      var wallet = await c.read(walletRepositoryProvider).getWallet(DailySeed.meId);
      expect(wallet.balance, 196, reason: "only Goora's 4 at booking (007 R5)");

      await _demo(tester, c, 'demo-subscriber-takes');
      c.read(routerProvider).go(Routes.today);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('one-off-bk-1')), findsNothing);

      wallet = await c.read(walletRepositoryProvider).getWallet(DailySeed.meId);
      expect(wallet.balance, 200, reason: 'everything paid came back (SC-005)');
      expect(wallet.activity.where((e) => e.kind == ActivityKind.seatRefund), hasLength(1));

      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(l.actSeatRefund), 400, scrollable: find.byType(Scrollable).first);
      expect(find.text(l.actSeatRefund), findsOneWidget);
    });

    testWidgets('[$code] after 9 PM: "Too late to reclaim — this booking is final." and nothing moves', (tester) async {
      final clock = TestClock(at(_tue, 12, 0));
      final c = await _booked(tester, clock, code);
      clock.now = at(_tue, 21, 5);

      await _demo(tester, c, 'demo-subscriber-takes');
      expect(find.text(l.reclaimTooLate), findsOneWidget);
      final wallet = await c.read(walletRepositoryProvider).getWallet(DailySeed.meId);
      expect(wallet.balance, 196);
      expect(wallet.activity.where((e) => e.kind == ActivityKind.seatRefund), isEmpty);
    });

    testWidgets('[$code] a seat booked after 9 PM is final from the start: the demo says so (T104 F16)', (tester) async {
      final clock = TestClock(at(_tue, 21, 30));
      final c = await _booked(tester, clock, code);
      expect(find.byKey(const Key('one-off-bk-1')), findsOneWidget);

      await _demo(tester, c, 'demo-subscriber-takes');
      expect(find.text(l.reclaimTooLate), findsOneWidget);
      expect(find.text(l.demoNothingToDo), findsNothing, reason: 'that is the driver wording');
    });

    testWidgets('[$code] no seat booked yet: the demo asks for a booking, not a published trip (T104 F16)', (tester) async {
      final c = await pumpGooraApp(tester, prefs: _prefs(code), overrides: dailyOverrides(TestClock(at(_tue, 12, 0))));
      tester.view.physicalSize = const Size(390, 3000);

      await _demo(tester, c, 'demo-subscriber-takes');
      expect(find.text(l.demoBookSeatFirst), findsOneWidget);
      expect(find.text(l.demoNothingToDo), findsNothing);
    });
  }
}
