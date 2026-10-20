import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/widgets/goora_pill.dart';
import 'package:goora/features/commute/data/cairo_ismailia_seed.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/data/providers.dart';
import 'package:goora/features/marketplace/domain/anonymous_rider.dart';
import 'package:goora/features/marketplace/domain/booking.dart';
import 'package:goora/features/marketplace/domain/offered_trip.dart';
import 'package:goora/features/marketplace/domain/trip_request.dart';
import 'package:goora/features/marketplace/presentation/post_trip/post_trip_controller.dart';
import 'package:goora/features/marketplace/presentation/post_trip/post_trip_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/cash_mark.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/seat_price.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 005 US3: Post your trip (B), ar + en. A once rider with a wallet, on
/// Tuesday 20:00 — 7:30 AM resolves to tomorrow.
final _tue = rideTuesday;
final _wed = rideTuesday.addDays(1);

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

final class _Open {
  const _Open(this.c, this.clock);

  final ProviderContainer c;
  final TestClock clock;
}

Future<_Open> _open(
  WidgetTester tester,
  String locale, {
  String? id,
  PostTripDraft? draft,
  bool member = false,
  int balance = 0,
  List<Override> overrides = const [],

  /// 006: the launch corridor, with this commute, instead of the old one.
  CommuteProfile? cairo,
}) async {
  final clock = TestClock(at(_tue, 20, 0));
  final c = await pumpScreen(
    tester,
    PostTripScreen(id: id, draft: draft),
    locale: Locale(locale),
    session: _rider(),
    prefs: memberPrefs(
      role: Role.rider,
      member: member,
      locale: locale,
      method: PaymentMethod.instapay,
      pastTrial: true,
      commute: cairo,
    ),
    overrides: [
      ...dailyOverrides(clock, corridor: cairo == null ? Corridors.sheikhZayedSmartVillage : Corridors.cairoIsmailia),
      ...overrides,
    ],
  );
  tester.view.physicalSize = const Size(390, 2800);
  if (balance > 0) await c.read(walletRepositoryProvider).topUp(DailySeed.meId, method: 'card', amount: balance);
  await tester.pumpAndSettle();
  return _Open(c, clock);
}

/// A trial seat on Khaled's trip earlier today that Khaled marked
/// "ماستلمتش" — an open debt (007 FR-005).
Future<void> _oweKhaled(_Open o) async {
  final prefs = o.c.read(sharedPreferencesProvider);
  final day = o.clock.now.date;
  final trip = OfferedTrip(
    id: 'of-owed',
    driverId: 'khaled',
    leg: Leg.going,
    from: Area.sheikhZayed,
    to: Area.smartVillage,
    date: day,
    departure: const Clock.hm(7, 0),
    seats: 3,
    riderSeats: 3,
    tripCost: Corridors.sheikhZayedSmartVillage.tripCost,
    contribution: 40,
    repeat: Repeat.once,
    pickup: MarketSeed.pickupIn(Area.sheikhZayed, 'of-stop-owed', const Clock.hm(7, 0)),
  );
  final booking = Booking(
    id: 'bk-owed',
    riderId: DailySeed.meId,
    riderName: 'Omar',
    rider: const AnonymousRider(isWoman: false, rating: 4.6),
    source: const BookingSource.offer('of-owed'),
    date: day,
    leg: Leg.going,
    rideId: Booking.offerRideId('of-owed'),
    price: MarketSeed.quote(40),
    paidBy: PaidBy.cash,
    paid: 0,
    bookedAt: at(day, 6, 0),
    isSubscriber: false,
    status: BookingStatus.done,
  );
  await prefs.setString(FakeMarketplaceRepository.offersKey, jsonEncode([trip.toJson()]));
  await prefs.setString(FakeMarketplaceRepository.bookingsKey, jsonEncode([booking.toJson()]));
  await o.c.read(walletRepositoryProvider).markShare(CashMark(
        rideId: Booking.offerRideId('of-owed'),
        riderId: DailySeed.meId,
        driverId: 'khaled',
        outcome: CashOutcome.didNotPay,
        amount: 40,
        date: day,
      ));
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _refresh(WidgetTester tester, ProviderContainer c) async {
  c
    ..invalidate(postedRequestProvider)
    ..invalidate(sentToProvider);
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    // 006 P4: the launch corridor's areas, route, leg and price.
    group('[$code] Cairo ↔ Ismailia', () {
      const heliToIsmailia = CommuteProfile(
        home: CairoIsmailiaSeed.homeHeliopolis,
        work: CairoIsmailiaSeed.workIsmailia,
        departure: Clock.hm(6, 30),
        ret: CommuteProfile.defaultReturn,
        days: CommuteProfile.defaultDays,
      );

      testWidgets('the pills are the six corridor areas, from home to work, priced on 300 EGP', (tester) async {
        await _open(tester, code, cairo: heliToIsmailia, balance: 200);
        for (final a in Corridors.cairoIsmailia.areas) {
          expect(find.byKey(Key('from-${a.name}')), findsOneWidget, reason: '$a');
        }
        expect(find.byKey(const Key('from-sheikhZayed')), findsNothing);
        expect(tester.widget<GooraPill>(find.byKey(const Key('from-heliopolis'))).selected, isTrue);
        expect(tester.widget<GooraPill>(find.byKey(const Key('to-ismailia'))).selected, isTrue);
        final price = SeatPrice.of(76, tripCost: 300, riderSeats: 3, mode: PricingMode.perTrip, method: PaymentMethod.instapay);
        expect(find.text(l.priceWithFee(76, price.fee)), findsOneWidget, reason: '300 ÷ (3 + 1), nearest 2 EGP');
      });

      testWidgets('with no saved commute it starts New Cairo → Ismailia', (tester) async {
        final o = await _open(tester, code, cairo: heliToIsmailia);
        await o.c.read(sharedPreferencesProvider).remove('commute.profile');
        o.c.invalidate(postStartProvider);
        await tester.pumpAndSettle();
        expect(tester.widget<GooraPill>(find.byKey(const Key('from-newCairo'))).selected, isTrue);
        expect(tester.widget<GooraPill>(find.byKey(const Key('to-ismailia'))).selected, isTrue);
      });

      // Two pumps, not cancel → post again: cancel pops the route, and
      // pumpScreen has no GoRouter.
      testWidgets('home → Ismailia is going', (tester) async {
        final o = await _open(tester, code, cairo: heliToIsmailia);
        await _tap(tester, find.byKey(const Key('post')));
        final mine = await o.c.read(marketplaceRepositoryProvider).myRequests(now: o.clock.now);
        expect(mine.single.from, Area.heliopolis);
        expect(mine.single.leg, Leg.going);
      });

      testWidgets('Ismailia → home is the way back', (tester) async {
        final o = await _open(tester, code, cairo: heliToIsmailia);
        await _tap(tester, find.byKey(const Key('from-ismailia')));
        await _tap(tester, find.byKey(const Key('to-heliopolis')));
        await _tap(tester, find.byKey(const Key('post')));
        final mine = await o.c.read(marketplaceRepositoryProvider).myRequests(now: o.clock.now);
        expect(mine.single.from, Area.ismailia);
        expect(mine.single.leg, Leg.ret);
      });
    });

    group('[$code] form', () {
      testWidgets('starts from the rider\'s route with one fixed price and the three rules', (tester) async {
        await _open(tester, code, balance: 100);
        expect(find.text(l.postReq), findsWidgets);
        expect(tester.widget<GooraPill>(find.byKey(const Key('from-sheikhZayed'))).selected, isTrue);
        expect(tester.widget<GooraPill>(find.byKey(const Key('to-smartVillage'))).selected, isTrue);
        expect(find.text(l.priceWithFee(40, 4)), findsOneWidget);
        expect(find.text(l.ruleNoBidding), findsOneWidget);
        expect(find.text(l.ruleCostShare), findsOneWidget);
        expect(find.text(l.ruleRoute), findsOneWidget);
        expect(find.byType(TextField), findsNothing, reason: 'no price field (FR-022)');
        expect(find.byKey(const Key('post')), findsOneWidget);
      });

      testWidgets('a rider in a daily group has Every workday off, with the reason in words', (tester) async {
        await _open(tester, code, member: true, balance: 100);
        expect(tester.widget<GooraPill>(find.byKey(const Key('repeat-daily'))).onTap, isNull);
        expect(find.text(l.dailyNeedsNoGroup), findsOneWidget);
        expect(tester.widget<GooraPill>(find.byKey(const Key('repeat-once'))).selected, isTrue);
      });

      testWidgets('an empty wallet still posts: the Goora fee never blocks (007 R5)', (tester) async {
        await _open(tester, code);
        await _tap(tester, find.byKey(const Key('post')));
        expect(find.byKey(const Key('request-posted')), findsOneWidget);
      });
    });

    group('[$code] posted', () {
      testWidgets('Sent to N drivers, waiting, Cancel request — and nothing charged', (tester) async {
        final o = await _open(tester, code, balance: 100);
        await _tap(tester, find.byKey(const Key('post')));
        expect(find.byKey(const Key('request-posted')), findsOneWidget);
        expect(find.text(l.sentToDrivers(4)), findsOneWidget);
        expect(find.text(l.waitingDriver), findsOneWidget);
        expect(find.byKey(const Key('cancel-request')), findsOneWidget);
        final wallet = await o.c.read(walletRepositoryProvider).getWallet(DailySeed.meId);
        expect(wallet.balance, 100);
      });

      testWidgets('accepted (once): the driver, pickup, time and price line', (tester) async {
        final o = await _open(tester, code, balance: 100);
        await _tap(tester, find.byKey(const Key('post')));
        await o.c.read(marketplaceRepositoryProvider).demoDriverAccepts(now: o.clock.now);
        await _refresh(tester, o.c);
        expect(find.byKey(const Key('request-accepted')), findsOneWidget);
        expect(find.text(l.requestAccepted), findsOneWidget);
        expect(find.text('Tarek'), findsOneWidget);
        expect(find.text('${l.heroTomorrow} · ${l.timeAm('7:30')}'), findsOneWidget);
        expect(find.text(l.priceWithFee(40, 4)), findsOneWidget);
        expect(find.byKey(const Key('now-group')), findsNothing);
        expect(find.text(l.backToToday), findsOneWidget);
      });

      testWidgets('accepted (daily): "You\'re now a commute group" and Continue', (tester) async {
        final o = await _open(tester, code, balance: 100);
        await _tap(tester, find.byKey(const Key('repeat-daily')));
        await _tap(tester, find.byKey(const Key('post')));
        await o.c.read(marketplaceRepositoryProvider).demoDriverAccepts(now: o.clock.now);
        await _refresh(tester, o.c);
        expect(find.text(l.nowGroup), findsOneWidget);
        expect(find.text(l.continueBtn), findsOneWidget);
      });

      testWidgets('expired: nothing was charged, with Post again and See empty seats', (tester) async {
        final o = await _open(tester, code, balance: 100);
        await _tap(tester, find.byKey(const Key('post')));
        o.clock.now = at(_wed, 7, 30);
        await _refresh(tester, o.c);
        expect(find.byKey(const Key('request-expired')), findsOneWidget);
        expect(find.text(l.requestExpired), findsOneWidget);
        expect(find.byKey(const Key('see-empty-seats')), findsOneWidget);
        expect((await o.c.read(walletRepositoryProvider).getWallet(DailySeed.meId)).balance, 100);

        await _tap(tester, find.byKey(const Key('post-again')));
        expect(find.byKey(const Key('post')), findsOneWidget, reason: 'back on the form');
      });

      testWidgets('withdrawn: a driver marked a share unpaid before accept — nothing charged (007 FR-005)',
          (tester) async {
        final o = await _open(tester, code, balance: 44);
        await _tap(tester, find.byKey(const Key('post')));
        await _oweKhaled(o);
        await o.c.read(marketplaceRepositoryProvider).demoDriverAccepts(now: o.clock.now);
        await _refresh(tester, o.c);
        expect(find.byKey(const Key('request-withdrawn')), findsOneWidget);
        expect(find.text(l.requestWithdrawn), findsOneWidget);
      });

      testWidgets('N-8: the owe-a-driver notice on the form has an "I paid" action', (tester) async {
        final o = await _open(tester, code, balance: 44);
        await _oweKhaled(o);
        // Khaled's mark is stamped after the trip, so Omar's claim comes after it.
        await o.c.read(walletRepositoryProvider).markShare(CashMark(
              rideId: Booking.offerRideId('of-owed'),
              riderId: DailySeed.meId,
              driverId: 'khaled',
              outcome: CashOutcome.didNotPay,
              amount: 40,
              date: o.clock.now.date,
              markedAt: at(o.clock.now.date, 9, 0),
            ));
        await _tap(tester, find.byKey(const Key('post')));
        expect(find.text(l.owesDriver(40, 'Khaled')), findsOneWidget);
        expect(find.text(l.iPaid), findsOneWidget);
        await _tap(tester, find.text(l.iPaid));
        expect(find.text(l.iPaidSent('Khaled')), findsOneWidget, reason: 'the claim is recorded and shown');
        expect(find.text(l.iPaid), findsNothing);
      });

      testWidgets('loading is a spinner, not a blank screen (FR-027)', (tester) async {
        final never = Completer<TripRequest?>();
        try {
          await pumpScreen(
            tester,
            const PostTripScreen(id: 'rq-1'),
            locale: Locale(code),
            session: _rider(),
            prefs: memberPrefs(role: Role.rider, member: false, locale: code, method: PaymentMethod.instapay, pastTrial: true),
            overrides: [postedRequestProvider('rq-1').overrideWith((ref) => never.future)],
          );
        } catch (_) {
          // The spinner never stops, so the helper's pumpAndSettle times out.
        }
        await tester.pump();
        expect(find.byKey(const Key('posted-loading')), findsOneWidget);
      });

      testWidgets('an error is a calm message with a retry (FR-027)', (tester) async {
        await pumpScreen(
          tester,
          const PostTripScreen(id: 'rq-1'),
          locale: Locale(code),
          session: _rider(),
          prefs: memberPrefs(role: Role.rider, member: false, locale: code, method: PaymentMethod.instapay, pastTrial: true),
          overrides: [postedRequestProvider('rq-1').overrideWith((ref) => Future<TripRequest?>.error('boom'))],
        );
        expect(find.byKey(const Key('posted-error')), findsOneWidget);
        expect(find.text(l.todayError), findsOneWidget);
        expect(find.byKey(const Key('posted-retry')), findsOneWidget);
      });
    });
  }
}
