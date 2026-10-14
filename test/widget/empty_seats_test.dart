import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/data/providers.dart';
import 'package:goora/features/marketplace/domain/anonymous_rider.dart';
import 'package:goora/features/marketplace/domain/booking.dart';
import 'package:goora/features/marketplace/domain/seat_offer.dart';
import 'package:goora/features/marketplace/presentation/empty_seats/empty_seats_controller.dart';
import 'package:goora/features/marketplace/presentation/empty_seats/empty_seats_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/plan.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 005 US1: Empty seats (A), ar + en. The seeded Tarek trip (Going, 7:30,
/// 44 EGP, 3 seats) and Heba (Return, 17:10, 40) are the cards.
/// Monday evening, before the 9 PM cut-off: Tarek's trip is tomorrow.
final _morning = at(rideTuesday.addDays(-1), 20, 0);

Session _rider() => Session(
      phone: testPhone,
      profile: Profile(
        phone: testPhone,
        firstName: 'Omar',
        lastName: 'Khaled',
        gender: Gender.male,
        role: Role.rider,
        frequency: Frequency.once,
      ),
    );

Future<ProviderContainer> _open(
  WidgetTester tester,
  String locale, {
  PaymentMethod? method = PaymentMethod.wallet,
  bool withPlan = false,
  WallTime? now,
  Leg leg = Leg.going,
  Map<String, Object> extra = const {},
  List<Override> overrides = const [],
}) async {
  final clock = TestClock(now ?? _morning);
  final c = await pumpScreen(
    tester,
    EmptySeatsScreen(leg: leg),
    locale: Locale(locale),
    session: _rider(),
    prefs: {
      ...memberPrefs(role: Role.rider, member: false, locale: locale, withPlan: false, method: method),
      if (withPlan)
        FakeWalletRepository.planKey: jsonEncode(
          const Plan(personId: DailySeed.meId, type: PlanType.company, status: PlanStatus.active, price: 0).toJson(),
        ),
      ...extra,
    },
    overrides: [...dailyOverrides(clock), ...overrides],
  );
  tester.view.physicalSize = const Size(390, 2400);
  await tester.pumpAndSettle();
  return c;
}

Future<void> _topUp(ProviderContainer c, int amount) =>
    c.read(walletRepositoryProvider).topUp(DailySeed.meId, method: 'card', amount: amount);

Future<int> _balance(ProviderContainer c) async => (await c.read(walletRepositoryProvider).getWallet(DailySeed.meId)).balance;

SeatOffer _tarek({int free = 1}) {
  final trip = MarketSeed.offers(_morning).first;
  return SeatOffer(
    source: BookingSource.offer(trip.id),
    driver: MarketSeed.drivers.first,
    pickup: trip.pickup,
    date: trip.date,
    leg: trip.leg,
    departure: trip.departure,
    freeSeats: free,
    price: MarketSeed.quote(44),
  );
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] loading shows a spinner, not a blank screen', (tester) async {
      final never = Completer<List<SeatOffer>>();
      try {
        await pumpScreen(
          tester,
          const EmptySeatsScreen(),
          locale: locale,
          session: _rider(),
          prefs: memberPrefs(role: Role.rider, member: false, locale: code, withPlan: false),
          overrides: [seatOffersProvider(Leg.going).overrideWith((ref) => never.future)],
        );
      } catch (_) {
        // The spinner never stops, so the helper's pumpAndSettle times out —
        // the first frames are already on screen.
      }
      await tester.pump();
      expect(find.byKey(const Key('seats-loading')), findsOneWidget);
      expect(find.text(l.emptySeatsTitle), findsOneWidget);
    });

    testWidgets('[$code] list: Tarek card has driver, rating, pickup, time, seats left and Book seat', (tester) async {
      await _open(tester, code);
      expect(find.text(l.legGoing), findsOneWidget);
      expect(find.text(l.legReturn), findsOneWidget);
      expect(find.text(l.ratingStars('4.8')), findsWidgets);
      expect(find.text(l.seatsLeft(3)), findsOneWidget);
      expect(find.textContaining(l.heroTomorrow), findsWidgets, reason: 'the day label');
      expect(find.byKey(Key('book-${seatKey(_tarek())}')), findsOneWidget);
      expect(find.text(l.seatRule), findsOneWidget);
      expect(find.text(l.nothingFits), findsOneWidget);
    });

    testWidgets('[$code] price by mode: wallet 48 = 44 + 4 fee', (tester) async {
      await _open(tester, code);
      expect(find.text(l.priceWithFee(44, 4)), findsOneWidget);
    });

    testWidgets('[$code] price by mode: cash rounds to 45', (tester) async {
      await _open(tester, code, method: PaymentMethod.cash);
      expect(find.text(l.priceCash(45)), findsOneWidget);
    });

    testWidgets('[$code] price by mode: a company rider pays no fee', (tester) async {
      await _open(tester, code, method: null, withPlan: true);
      expect(find.text(l.priceCompany(44)), findsOneWidget);
    });

    testWidgets('[$code] the Return toggle lists Heba at 40 + 4', (tester) async {
      await _open(tester, code);
      await tester.tap(find.byKey(const Key('leg-return')));
      await tester.pumpAndSettle();
      expect(find.text(l.ratingStars('4.9')), findsWidgets);
      expect(find.text(l.priceWithFee(40, 4)), findsWidgets);
    });

    testWidgets('[$code] empty: a calm line and the dashed card, not a blank page', (tester) async {
      await _open(tester, code, overrides: [seatOffersProvider(Leg.going).overrideWith((ref) async => <SeatOffer>[])]);
      expect(find.byKey(const Key('seats-empty')), findsOneWidget);
      expect(find.text(l.noSeatsOnRoute), findsOneWidget);
      expect(find.text(l.nothingFits), findsOneWidget);
    });

    testWidgets('[$code] error: a plain sentence and Try again', (tester) async {
      await _open(tester, code, overrides: [seatOffersProvider(Leg.going).overrideWith((ref) => throw StateError('down'))]);
      expect(find.text(l.todayError), findsOneWidget);
      expect(find.byKey(const Key('seats-retry')), findsOneWidget);
    });

    testWidgets('[$code] booking with enough balance shows the summary and the daily upsell', (tester) async {
      final c = await _open(tester, code);
      await _topUp(c, 200);
      c.invalidate(seatOffersProvider);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('book-${seatKey(_tarek())}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('booked-view')), findsOneWidget);
      expect(find.text(l.seatBookedTitle), findsOneWidget);
      expect(find.text(l.priceWithFee(44, 4)), findsOneWidget);
      expect(find.byKey(const Key('upsell-daily')), findsOneWidget);
      expect(find.byKey(const Key('back-to-today')), findsOneWidget);
      expect(await _balance(c), 152, reason: '200 − 44 − 4');
    });

    testWidgets('[$code] a subscriber sees Back to today and no upsell', (tester) async {
      await _open(tester, code, method: null, withPlan: true);
      await tester.tap(find.byKey(Key('book-${seatKey(_tarek())}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('booked-view')), findsOneWidget);
      expect(find.byKey(const Key('upsell-daily')), findsNothing);
      expect(find.byKey(const Key('back-to-today')), findsOneWidget);
    });

    testWidgets('[$code] top-up gate: "Top up 48 EGP first", nothing charged', (tester) async {
      final c = await _open(tester, code);
      await tester.tap(find.byKey(Key('book-${seatKey(_tarek())}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notice-top-up')), findsOneWidget);
      expect(find.text(l.topUpFirst(48)), findsOneWidget);
      expect(find.byKey(const Key('booked-view')), findsNothing);
      expect(await _balance(c), 0);
    });

    testWidgets('[$code] the seat just went: a calm banner and a refreshed list', (tester) async {
      final trip = MarketSeed.offers(_morning).first;
      final taken = [
        for (var i = 0; i < 3; i++)
          Booking(
            id: 'bk-$i',
            riderId: 'seed-rider-$i',
            riderName: 'Rider $i',
            rider: const AnonymousRider(isWoman: false, rating: 4.5),
            source: BookingSource.offer(trip.id),
            date: trip.date,
            leg: Leg.going,
            rideId: Booking.offerRideId(trip.id),
            price: MarketSeed.quote(44),
            paidBy: PaidBy.wallet,
            paid: 48,
            bookedAt: at(rideTuesday.addDays(-1), 12, 0),
            isSubscriber: false,
          ).toJson(),
      ];
      final c = await _open(
        tester,
        code,
        extra: {FakeMarketplaceRepository.bookingsKey: jsonEncode(taken)},
        overrides: [seatOffersProvider(Leg.going).overrideWith((ref) async => [_tarek()])],
      );
      await _topUp(c, 200);
      await tester.tap(find.byKey(Key('book-${seatKey(_tarek())}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notice-taken')), findsOneWidget);
      expect(find.text(l.seatJustTaken), findsOneWidget);
      expect(await _balance(c), 200, reason: 'a lost race changes nothing (SC-006)');
    });

    testWidgets('[$code] already riding that leg: a plain sentence, nothing charged', (tester) async {
      final c = await _open(tester, code, overrides: [seatOffersProvider(Leg.going).overrideWith((ref) async => [_tarek()])]);
      await _topUp(c, 200);
      await c.read(marketplaceRepositoryProvider).book(_tarek(), now: _morning);
      final before = await _balance(c);
      await tester.tap(find.byKey(Key('book-${seatKey(_tarek())}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notice-already-riding')), findsOneWidget);
      expect(find.text(l.alreadyRiding), findsOneWidget);
      expect(await _balance(c), before);
    });

    testWidgets('[$code] after 9 PM the evening before, the half-share note is shown before the tap', (tester) async {
      await _open(tester, code, now: at(rideTuesday.addDays(-1), 21, 30));
      expect(find.text(l.lateBookingNote), findsWidgets);
    });

    testWidgets('[$code] before 9 PM there is no late note', (tester) async {
      await _open(tester, code);
      expect(find.text(l.lateBookingNote), findsNothing);
    });
  }
}
