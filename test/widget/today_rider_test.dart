import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/widgets/goora_status_chip.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/daily/presentation/safety/sos_sheet.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/data/providers.dart';
import 'package:goora/features/marketplace/domain/seat_offer.dart';
import 'package:goora/features/marketplace/presentation/empty_seats/empty_seats_controller.dart';
import 'package:goora/features/marketplace/presentation/today/one_off_section.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US1: rider Today with a fixed clock, ar + en (FR-003, FR-004, FR-034).
Future<void> pumpRider(
  WidgetTester tester,
  TestClock clock, {
  String locale = 'en',
  RecordingDialer? dialer,
  Clock ret = const Clock.hm(17, 0),
}) async {
  await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale, commute: corridorProfile(ret: ret)),
    overrides: dailyOverrides(clock, dialer: dialer),
  );
  tester.view.physicalSize = const Size(390, 2400);
  await tester.pumpAndSettle();
}

void main() {
  noGroupTodayTests();
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] every US1/AC2 element on a ride day', (tester) async {
      await pumpRider(tester, TestClock(at(rideTuesday, 7, 13, 30)), locale: code);
      expect(directionOf(tester, find.text(l.goodMorning('Omar'))), code == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      expect(find.text(l.todaySub), findsOneWidget);
      expect(find.byKey(const Key('today-logo')), findsOneWidget);
      // Hero: confirmed · my pickup time · route.
      expect(find.text(l.confirmed), findsOneWidget);
      expect(find.text(l.timeAm('7:25')), findsWidgets);
      expect(find.text(l.routeLine(l.areaSheikhZayed, l.areaSmartVillage)), findsOneWidget);
      // Legs card: Tuesday's rotation gives Ahmed both legs; both covered.
      expect(find.text(l.legRow(l.legGoing, 'Ahmed', l.timeAm('7:25'))), findsOneWidget);
      expect(find.text(l.legRow(l.legReturn, 'Ahmed', l.timePm('5:00'))), findsOneWidget);
      expect(find.widgetWithText(GooraStatusChip, l.covered), findsNWidgets(2));
      expect(find.text(l.legsNote), findsOneWidget);
      // Map card countdown: 7:13:30 → 7:25 = 12 min (rounded up).
      expect(find.text(l.pickupInMin(12)), findsOneWidget);
      // Driver card.
      expect(find.byKey(const Key('driver-card')), findsOneWidget);
      expect(find.text(l.verified), findsOneWidget);
      expect(find.text(l.carLine('Toyota Corolla', l.colourWhite, '4.9')), findsOneWidget);
      expect(find.text(l.callDriver), findsOneWidget);
      // Timeline: pickup at my nearest stop, passengers, arrival.
      expect(find.text(l.tlPickup(l.timeAm('7:25'))), findsOneWidget);
      expect(find.text(l.stopCentralSt), findsOneWidget);
      expect(find.text(l.tlPassengers(4, ['Mohamed', 'Sara', 'Youssef', l.youWord].join(l.listSep))), findsOneWidget);
      expect(find.text(l.tlArrival(l.timeAm('8:05'))), findsOneWidget);
      // Tiles: return time, price per trip — memberPrefs seeds a company plan, so no fee (004 v2 FR-004).
      expect(find.text(l.returnTime), findsOneWidget);
      expect(find.text(l.payPerTrip), findsOneWidget);
      expect(find.text(l.priceCompany(40)), findsOneWidget);
      // Safety + cancel + extra trip.
      expect(find.text(l.shareTrip), findsOneWidget);
      expect(find.text(l.sos), findsOneWidget);
      expect(find.text(l.cantCome), findsOneWidget);
      expect(find.text(l.cantComeNote), findsOneWidget);
      expect(find.text(l.extraTrip), findsOneWidget);
      // Shell: four labelled tabs.
      for (final tab in [l.tabToday, l.tabWeek, l.tabWallet, l.tabTrust]) {
        expect(find.text(tab), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('[$code] one-leg rider: only that leg, the other group named (US1/AC3)', (tester) async {
      // Return 5:25 PM: too far from this group's 5:00 PM. 002 matching picks
      // sz-0720 (5:10 PM, pickup 400 m) over sz-0715 (5:20 PM, pickup 700 m).
      await pumpRider(tester, TestClock(at(rideTuesday, 7, 13)), locale: code, ret: const Clock.hm(17, 25));
      expect(find.text(l.legRow(l.legGoing, 'Ahmed', l.timeAm('7:25'))), findsOneWidget);
      expect(find.byKey(const Key('leg-ret')), findsNothing);
      expect(find.text(l.returnLeg(l.timePm('5:10'))), findsOneWidget);
      expect(find.text(l.noReturnTrip), findsOneWidget);
    });

    testWidgets('[$code] not a ride day → next ride day, no countdown (US1/AC5)', (tester) async {
      final friday = rideTuesday.addDays(3);
      await pumpRider(tester, TestClock(at(friday, 10, 0)), locale: code);
      expect(find.text(l.nextRide(l.daySun)), findsOneWidget);
      expect(find.byKey(const Key('pickup-countdown')), findsNothing);
      expect(find.text(l.confirmed), findsNothing);
    });
  }

  testWidgets('Call driver dials the current driver only (US1/AC4)', (tester) async {
    final dialer = RecordingDialer();
    await pumpRider(tester, TestClock(at(rideTuesday, 7, 13)), dialer: dialer);
    await tester.tap(find.byKey(const Key('call-driver')));
    await tester.pumpAndSettle();
    expect(dialer.dialled, ['+201000000001']);
  });

  testWidgets('after the going trip, the card shows the return driver', (tester) async {
    final dialer = RecordingDialer();
    // Wednesday: Mohamed's turn (rotation: Sun Ahmed, Mon Mohamed, Tue Ahmed, Wed Mohamed).
    await pumpRider(tester, TestClock(at(rideTuesday.addDays(1), 12, 0)), dialer: dialer);
    final l = l10nFor(en);
    expect(find.text(l.carLine('Hyundai Elantra', l.colourSilver, '4.8')), findsOneWidget);
    await tester.tap(find.byKey(const Key('call-driver')));
    expect(dialer.dialled, ['+201000000002']);
  });

  testWidgets('extra trip routes to Empty seats today (US1/AC6)', (tester) async {
    await pumpRider(tester, TestClock(at(rideTuesday, 7, 13)));
    await tester.tap(find.byKey(const Key('extra-trip')));
    await tester.pumpAndSettle();
    expect(find.text(l10nFor(en).emptySeatsTitle), findsWidgets);
  });

  testWidgets("the only fee text is the rider's own price line (004 v2 FR-004)", (tester) async {
    await pumpRider(tester, TestClock(at(rideTuesday, 7, 13)));
    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').toList();
    final fees = texts.where((t) => t.toLowerCase().contains('fee')).toList();
    expect(fees, isNotEmpty);
    // memberPrefs seeds a company plan: fee-free, said once on the pay tile.
    expect(fees.every((t) => t.contains('no fees (company)')), isTrue, reason: '$fees');
  });

  testWidgets('screen fits at 1.3× text size', (tester) async {
    await pumpRider(tester, TestClock(at(rideTuesday, 7, 13)));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}

/// 005 T060: Today for someone with no daily group.
Map<String, Object> _oncePrefs(String locale) => {
      ...memberPrefs(role: Role.rider, locale: locale, member: false, withPlan: false, method: PaymentMethod.instapay, pastTrial: true),
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

Future<ProviderContainer> _openNoGroupToday(WidgetTester tester, String locale, {RecordingSharer? sharer, bool book = false}) async {
  final clock = TestClock(at(rideTuesday.addDays(-1), 18, 0));
  final c = await pumpGooraApp(tester, prefs: _oncePrefs(locale), overrides: dailyOverrides(clock, sharer: sharer));
  tester.view.physicalSize = const Size(390, 2600);
  if (book) {
    await c.read(walletRepositoryProvider).topUp(DailySeed.meId, method: 'card', amount: 200);
    final repo = c.read(marketplaceRepositoryProvider);
    final SeatOffer tarek = (await repo.seatOffers(Leg.going, now: clock.now)).firstWhere((o) => o.source.id == MarketSeed.tarekId);
    await repo.book(tarek, now: clock.now);
    // A once rider now starts on Today (walk N-11), so it is already built:
    // tell it a seat was booked behind its back.
    c
      ..invalidate(myBookingsProvider)
      ..invalidate(oneOffTodayProvider);
  }
  c.read(routerProvider).go(Routes.today);
  await tester.pumpAndSettle();
  return c;
}

void noGroupTodayTests() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] no group yet: a calm card and the two ways in, not the removed notice', (tester) async {
      await _openNoGroupToday(tester, code);
      expect(find.byKey(const Key('no-group-yet')), findsOneWidget);
      expect(find.text(l.fOnceRider), findsOneWidget);
      expect(find.text(l.removedTitle), findsNothing, reason: 'never in a group is not the same as being removed');
      expect(find.byKey(const Key('find-new-group')), findsNothing);
      expect(find.byKey(const Key('one-off-section')), findsNothing);
      await tester.tap(find.byKey(const Key('no-group-action')));
      await tester.pumpAndSettle();
      expect(find.text(l.emptySeatsTitle), findsWidgets);
    });

    testWidgets('[$code] a booked seat shows on Today with driver, pickup, price, cancel rule, Share and SOS', (tester) async {
      final sharer = RecordingSharer();
      await _openNoGroupToday(tester, code, sharer: sharer, book: true);
      expect(find.byKey(const Key('one-off-section')), findsOneWidget);
      expect(find.text(l.oneOffTrips), findsOneWidget);
      expect(find.text(l.priceWithFee(44, 4)), findsOneWidget);
      expect(find.text(l.cancelBooking), findsOneWidget);
      expect(find.text(l.cancelFreeNote), findsOneWidget);
      // Constitution V: Share and SOS are one tap away on a one-off trip.
      await tester.tap(find.textContaining(l.shareTrip).first);
      await tester.pumpAndSettle();
      expect(sharer.shared, hasLength(1));
      expect(sharer.shared.single, contains(l.areaSheikhZayed));
      await tester.tap(find.text(l.sos).first);
      await tester.pumpAndSettle();
      expect(find.byType(SosSheet), findsOneWidget);
    });

    testWidgets('[$code] cancelling before 9 PM gives everything back and clears the card', (tester) async {
      final c = await _openNoGroupToday(tester, code, book: true);
      final wallet = c.read(walletRepositoryProvider);
      expect((await wallet.getWallet(DailySeed.meId)).balance, 196, reason: "only Goora's 4 at booking (007 R5)");
      await tester.tap(find.text(l.cancelBooking));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('one-off-section')), findsNothing);
      expect((await wallet.getWallet(DailySeed.meId)).balance, 200);
    });
  }
}
