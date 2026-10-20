import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/core/widgets/goora_pill.dart';
import 'package:goora/core/widgets/goora_primary_button.dart';
import 'package:goora/features/commute/data/cairo_ismailia_seed.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/data/providers.dart';
import 'package:goora/features/marketplace/domain/anonymous_rider.dart';
import 'package:goora/features/marketplace/domain/booking.dart';
import 'package:goora/features/marketplace/domain/marketplace_repository.dart';
import 'package:goora/features/marketplace/domain/offered_trip.dart';
import 'package:goora/features/marketplace/presentation/offer_trip/offer_trip_controller.dart';
import 'package:goora/features/marketplace/presentation/offer_trip/offer_trip_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 005 US2: Offer a trip (C), ar + en. A verified driver with no group, on
/// Tuesday 20:00 — 7:30 AM resolves to tomorrow (Wednesday).
final _tue = rideTuesday;
final _wed = rideTuesday.addDays(1);

Session _driver() => Session(
      phone: testPhone,
      profile: Profile(
        phone: testPhone,
        firstName: 'Omar',
        lastName: 'Khaled',
        gender: Gender.male,
        role: Role.driver,
        frequency: Frequency.once,
      ),
    );

Future<ProviderContainer> _open(
  WidgetTester tester,
  String locale, {
  String? id,
  WallTime? now,
  bool member = false,
  Map<String, Object> extra = const {},
  List<Override> overrides = const [],

  /// 006: the launch corridor instead of the old one these tests were written on.
  bool cairo = false,
}) async {
  final clock = TestClock(now ?? at(_tue, 20, 0));
  final c = await pumpScreen(
    tester,
    OfferTripScreen(id: id),
    locale: Locale(locale),
    session: _driver(),
    prefs: {...memberPrefs(role: Role.driver, member: member, locale: locale), ...extra},
    overrides: [
      ...dailyOverrides(clock, corridor: cairo ? Corridors.cairoIsmailia : Corridors.sheikhZayedSmartVillage),
      ...overrides,
    ],
  );
  tester.view.physicalSize = const Size(390, 2800);
  await tester.pumpAndSettle();
  return c;
}

OfferedTrip _stored(String id, {Clock departure = const Clock.hm(9, 0)}) => OfferedTrip(
      id: id,
      driverId: 'me',
      leg: Leg.going,
      from: Area.sheikhZayed,
      to: Area.smartVillage,
      date: _wed,
      departure: departure,
      seats: 3,
      riderSeats: 3,
      tripCost: Corridors.sheikhZayedSmartVillage.tripCost,
      contribution: 40,
      repeat: Repeat.once,
      pickup: MarketSeed.pickupIn(Area.sheikhZayed, 'of-stop-$id', departure),
    );

Booking _booked(String id, String riderId, String name, {bool woman = true, double? rating = 4.6}) => Booking(
      id: id,
      riderId: riderId,
      riderName: name,
      rider: AnonymousRider(isWoman: woman, rating: rating),
      source: const BookingSource.offer('of-9'),
      date: _wed,
      leg: Leg.going,
      rideId: Booking.offerRideId('of-9'),
      price: MarketSeed.quote(40),
      paidBy: PaidBy.wallet,
      paid: 44,
      bookedAt: at(_tue, 10, 0),
      isSubscriber: false,
    );

Map<String, Object> _seed(List<OfferedTrip> trips, List<Booking> bookings) => {
      FakeMarketplaceRepository.offersKey: jsonEncode([for (final t in trips) t.toJson()]),
      FakeMarketplaceRepository.bookingsKey: jsonEncode([for (final b in bookings) b.toJson()]),
    };

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// The trips this driver published, as stored.
List<OfferedTrip> _published(ProviderContainer c) => [
      for (final m in (jsonDecode(c.read(sharedPreferencesProvider).getString(FakeMarketplaceRepository.offersKey)!) as List)
          .cast<Map<String, dynamic>>())
        OfferedTrip.fromJson(m),
    ];

bool _publishOn(WidgetTester tester) =>
    tester.widget<GooraPrimaryButton>(find.byKey(const Key('publish'))).onPressed != null;

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    // 006 P4: the launch corridor's areas, route, leg, duration and trip cost.
    group('[$code] Cairo ↔ Ismailia', () {
      const nasrToIsmailia = CommuteProfile(
        home: CairoIsmailiaSeed.homeNasrCity,
        work: CairoIsmailiaSeed.workIsmailia,
        departure: Clock.hm(6, 30),
        ret: CommuteProfile.defaultReturn,
        days: CommuteProfile.defaultDays,
        driver: DriverOffer(seats: 3, trips: DrivenTrips.both, contribution: 76),
      );
      final extra = {'commute.profile': jsonEncode(nasrToIsmailia.toJson())};

      testWidgets('the pills are the six corridor areas, from home to work, priced on 300 EGP', (tester) async {
        await _open(tester, code, cairo: true, extra: extra);
        for (final a in Corridors.cairoIsmailia.areas) {
          expect(find.byKey(Key('from-${a.name}')), findsOneWidget, reason: '$a');
          expect(find.byKey(Key('to-${a.name}')), findsOneWidget, reason: '$a');
        }
        expect(find.byKey(const Key('from-sheikhZayed')), findsNothing);
        expect(find.byKey(const Key('to-smartVillage')), findsNothing);
        bool on(String key) => tester.widget<GooraPill>(find.byKey(Key(key))).selected;
        expect(on('from-nasrCity'), isTrue);
        expect(on('to-ismailia'), isTrue);
        expect(find.text(l.egpAmount(76)), findsOneWidget, reason: '300 ÷ (3 + 1), nearest 2 EGP');
      });

      testWidgets('with no saved commute it starts New Cairo → Ismailia', (tester) async {
        final c = await _open(tester, code, cairo: true);
        await c.read(sharedPreferencesProvider).remove('commute.profile');
        c.invalidate(offerStartProvider);
        await tester.pumpAndSettle();
        bool on(String key) => tester.widget<GooraPill>(find.byKey(Key(key))).selected;
        expect(on('from-newCairo'), isTrue);
        expect(on('to-ismailia'), isTrue);
      });

      testWidgets('home → work is going: 105 min on a 300 EGP trip', (tester) async {
        final c = await _open(tester, code, cairo: true, extra: extra);
        await _tap(tester, find.byKey(const Key('publish')));
        final going = _published(c);
        expect(going.single.leg, Leg.going);
        expect(going.single.durationMinutes, 105);
        expect(going.single.tripCost, 300);
      });

      testWidgets('Ismailia → Nasr City is the way back', (tester) async {
        final c = await _open(tester, code, cairo: true, extra: extra);
        await _tap(tester, find.byKey(const Key('from-ismailia')));
        await _tap(tester, find.byKey(const Key('to-nasrCity')));
        await _tap(tester, find.byKey(const Key('publish')));
        final back = _published(c);
        expect(back.single.leg, Leg.ret);
        expect(back.single.durationMinutes, 105);
      });
    });

    group('[$code] form', () {
      testWidgets('starts at the suggested price, shows the rider price and the three rules, with no price field',
          (tester) async {
        await _open(tester, code);
        expect(find.text(l.offerTitle), findsWidgets);
        expect(find.text(l.egpAmount(40)), findsOneWidget);
        expect(find.text(l.suggestedPrice), findsOneWidget);
        expect(find.text(l.riderPaysLine(44)), findsOneWidget);
        expect(find.text('${l.heroTomorrow} · ${l.timeAm('7:30')}'), findsOneWidget);
        expect(find.text(l.ruleNoBidding), findsOneWidget);
        expect(find.text(l.ruleCostShare), findsOneWidget);
        expect(find.text(l.ruleRoute), findsOneWidget);
        expect(find.byType(TextField), findsNothing, reason: 'the price is never typed (FR-022)');
        expect(_publishOn(tester), isTrue);
        expect(tester.takeException(), isNull);
      });

      // T104 F22: the form ignored the commute and always said Sheikh Zayed 7:30.
      testWidgets('starts from the driver\'s saved commute: home → work at their time', (tester) async {
        const october = CommuteProfile(
          home: CorridorSeed.october,
          work: CorridorSeed.smartVillage,
          departure: Clock.hm(7, 45),
          ret: CommuteProfile.defaultReturn,
          days: CommuteProfile.defaultDays,
          driver: DriverOffer(seats: 4, trips: DrivenTrips.both, contribution: 40),
        );
        await _open(tester, code, extra: {'commute.profile': jsonEncode(october.toJson())});
        bool on(String key) => tester.widget<GooraPill>(find.byKey(Key(key))).selected;
        expect(on('from-october'), isTrue);
        expect(on('from-sheikhZayed'), isFalse);
        expect(on('to-smartVillage'), isTrue);
        expect(find.text('${l.heroTomorrow} · ${l.timeAm('7:45')}'), findsOneWidget);
      });

      testWidgets('the price moves in 2 EGP steps and stops at 32 and 48', (tester) async {
        await _open(tester, code);
        for (var i = 0; i < 4; i++) {
          await _tap(tester, find.bySemanticsLabel(l.raiseContribution));
        }
        expect(find.text(l.egpAmount(48)), findsOneWidget);
        expect(find.text(l.aboveSuggested(8)), findsOneWidget);
        expect(find.text(l.riderPaysLine(53)), findsOneWidget, reason: '48 + 5 service fee, half-up');

        // At the top the raise button is off: a tap changes nothing.
        await tester.tap(find.bySemanticsLabel(l.raiseContribution));
        await tester.pumpAndSettle();
        expect(find.text(l.egpAmount(48)), findsOneWidget);

        for (var i = 0; i < 8; i++) {
          await _tap(tester, find.bySemanticsLabel(l.lowerContribution));
        }
        expect(find.text(l.egpAmount(32)), findsOneWidget);
        expect(find.text(l.belowSuggested(8)), findsOneWidget);
      });

      testWidgets('fewer seats resets the price to that car\'s suggestion', (tester) async {
        await _open(tester, code);
        await _tap(tester, find.bySemanticsLabel(l.fewerSeats));
        // 160 across 2 seats: 160 / 3 = 53.3 → 54.
        expect(find.text(l.egpAmount(54)), findsOneWidget);
      });

      testWidgets('an unverified driver sees the missing checks as chips and Publish is off', (tester) async {
        await _open(tester, code, extra: {FakeTrustRepository.docsPendingKey: true});
        expect(find.text(l.verifyChip(l.checkLicense)), findsOneWidget);
        expect(find.text(l.verifyChip(l.checkVehicle)), findsOneWidget);
        expect(_publishOn(tester), isFalse);
      });

      testWidgets('Publish is off with the reason in words: joins, doesn\'t fit, limit', (tester) async {
        final c = await _open(tester, code, extra: _seed([], []));
        final repo = c.read(marketplaceRepositoryProvider);
        await repo.publish(
          const OfferDraft(
            leg: Leg.going,
            from: Area.sheikhZayed,
            to: Area.smartVillage,
            departure: Clock.hm(7, 30),
            seats: 3,
            contribution: 40,
            repeat: Repeat.once,
          ),
          now: at(_tue, 20, 0),
        );
        c.invalidate(offerCheckProvider);
        await tester.pumpAndSettle();
        expect(find.text(l.joinsTripInstead(l.timeAm('7:30'))), findsOneWidget);
        expect(_publishOn(tester), isFalse);

        // 40 minutes later is outside the join window: doesn't fit.
        for (var i = 0; i < 8; i++) {
          await _tap(tester, find.bySemanticsLabel(l.later));
        }
        expect(find.text(l.doesntFit), findsOneWidget);
        expect(_publishOn(tester), isFalse);

        // The way back is a second trip.
        await _tap(tester, find.byKey(const Key('from-smartVillage')));
        await _tap(tester, find.byKey(const Key('to-sheikhZayed')));
        expect(find.text(l.doesntFit), findsNothing);
        expect(_publishOn(tester), isTrue);
        await _tap(tester, find.byKey(const Key('publish')));
        expect(find.byKey(const Key('offer-live')), findsOneWidget);
      });

      testWidgets('a driver who leads a daily group cannot choose Every workday on a day off', (tester) async {
        await _open(tester, code, member: true);
        await _tap(tester, find.byKey(const Key('repeat-daily')));
        expect(find.text(l.oneGroupOnly), findsOneWidget);
        expect(_publishOn(tester), isFalse);
        await _tap(tester, find.byKey(const Key('repeat-once')));
        expect(find.text(l.oneGroupOnly), findsNothing);
        expect(_publishOn(tester), isTrue);
      });

      testWidgets('Every workday says the first booking makes a group', (tester) async {
        await _open(tester, code);
        await _tap(tester, find.byKey(const Key('repeat-daily')));
        expect(find.text(l.dailyOfferNote), findsOneWidget);
      });
    });

    group('[$code] live', () {
      testWidgets('publish → 0 of 3 seats booked, then fills, is full, and shows no names before departure',
          (tester) async {
        final c = await _open(tester, code);
        await _tap(tester, find.byKey(const Key('publish')));
        expect(find.text(l.seatsBooked(0, 3)), findsOneWidget);
        expect(find.byKey(const Key('offer-progress')), findsOneWidget);
        expect(find.text(l.noRidersYet), findsOneWidget);

        final repo = c.read(marketplaceRepositoryProvider);
        final now = at(_tue, 20, 0);
        await repo.demoRiderBooks(now: now);
        c.invalidate(offerLiveProvider('of-1'));
        await tester.pumpAndSettle();
        expect(find.text(l.seatsBooked(1, 3)), findsOneWidget);
        expect(find.text(l.verifiedRiderWoman), findsOneWidget);
        expect(find.text('Nadia'), findsNothing, reason: 'no name before departure (FR-023)');

        await repo.demoRiderBooks(now: now);
        await repo.demoRiderBooks(now: now);
        c.invalidate(offerLiveProvider('of-1'));
        await tester.pumpAndSettle();
        expect(find.text(l.seatsBooked(3, 3)), findsOneWidget);
        expect(find.text(l.carFull), findsOneWidget);
      });

      testWidgets('Cancel trip asks first, then says every rider got everything back', (tester) async {
        final c = await _open(tester, code);
        await _tap(tester, find.byKey(const Key('publish')));
        await c.read(marketplaceRepositoryProvider).demoRiderBooks(now: at(_tue, 20, 0));
        c.invalidate(offerLiveProvider('of-1'));
        await tester.pumpAndSettle();

        await _tap(tester, find.byKey(const Key('cancel-trip')));
        expect(find.text(l.cancelTripConfirm), findsOneWidget);
        await _tap(tester, find.byKey(const Key('keep-trip')));
        expect(find.byKey(const Key('cancel-trip')), findsOneWidget, reason: 'keeping the trip changes nothing');

        await _tap(tester, find.byKey(const Key('cancel-trip')));
        await _tap(tester, find.byKey(const Key('confirm-cancel-trip')));
        expect(find.text(l.tripCancelledState), findsOneWidget);
        expect(find.byKey(const Key('cancel-trip')), findsNothing);
        expect(find.byKey(const Key('no-riders')), findsNothing, reason: 'a rider booked and got a refund (T104 F11)');
      });

      testWidgets('re-entering with ?id= shows the trip; from departure the first names show', (tester) async {
        await _open(
          tester,
          code,
          id: 'of-9',
          now: at(_wed, 9, 5),
          extra: _seed([_stored('of-9')], [_booked('bk-1', 'seed-rider-nadia', 'Nadia')]),
        );
        expect(find.byKey(const Key('offer-live')), findsOneWidget);
        expect(find.text(l.tripDepartedState), findsOneWidget);
        expect(find.text('Nadia'), findsOneWidget);
        expect(find.byKey(const Key('cancel-trip')), findsNothing, reason: 'it already left');
      });

      testWidgets('loading is a spinner, not a blank screen (FR-027)', (tester) async {
        final never = Completer<OfferLive>();
        try {
          await pumpScreen(
            tester,
            const OfferTripScreen(id: 'of-1'),
            locale: Locale(code),
            session: _driver(),
            prefs: memberPrefs(role: Role.driver, member: false, locale: code),
            overrides: [offerLiveProvider('of-1').overrideWith((ref) => never.future)],
          );
        } catch (_) {
          // The spinner never stops, so the helper's pumpAndSettle times out —
          // the first frames are already on screen.
        }
        await tester.pump();
        expect(find.byKey(const Key('offer-loading')), findsOneWidget);
      });

      testWidgets('an error is a calm message with a retry (FR-027)', (tester) async {
        await pumpScreen(
          tester,
          const OfferTripScreen(id: 'of-1'),
          locale: Locale(code),
          session: _driver(),
          prefs: memberPrefs(role: Role.driver, member: false, locale: code),
          overrides: [offerLiveProvider('of-1').overrideWith((ref) => Future<OfferLive>.error('boom'))],
        );
        expect(find.byKey(const Key('offer-error')), findsOneWidget);
        expect(find.text(l.todayError), findsOneWidget);
        expect(find.byKey(const Key('offer-retry')), findsOneWidget);
      });
    });
  }
}
