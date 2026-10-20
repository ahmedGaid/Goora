import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/l10n/app_localizations.dart';
import 'package:goora/core/theme/app_spacing.dart';
import 'package:goora/core/theme/app_theme.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/core/widgets/goora_card.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/domain/anonymous_rider.dart';
import 'package:goora/features/marketplace/domain/booking.dart';
import 'package:goora/features/marketplace/domain/driver_day_rules.dart';
import 'package:goora/features/marketplace/domain/marketplace_repository.dart';
import 'package:goora/features/marketplace/domain/seat_offer.dart';
import 'package:goora/features/marketplace/presentation/empty_seats/seat_card.dart';
import 'package:goora/features/marketplace/presentation/find_riders/request_card.dart';
import 'package:goora/features/marketplace/presentation/offer_trip/live_parts.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 005 (T099): the marketplace's own cards, RTL and LTR. Regenerate with
/// `flutter test --update-goldens test/golden/marketplace_golden_test.dart`
/// after an intended visual change, on Windows.
final _now = at(rideTuesday, 20, 0);

SeatOffer _seat() {
  final trip = MarketSeed.offers(_now).first;
  return SeatOffer(
    source: BookingSource.offer(trip.id),
    driver: MarketSeed.drivers.first,
    pickup: trip.pickup,
    date: trip.date,
    leg: trip.leg,
    departure: trip.departure,
    freeSeats: 2,
    price: MarketSeed.quote(44),
  );
}

/// 006 T036: Tarek's New Cairo → Ismailia seat on the launch corridor.
SeatOffer _cairoSeat() {
  const cairo = Corridors.cairoIsmailia;
  final trip = MarketSeed.offers(_now, corridor: cairo).first;
  return SeatOffer(
    source: BookingSource.offer(trip.id),
    driver: MarketSeed.driverById(trip.driverId)!,
    pickup: trip.pickup,
    date: trip.date,
    leg: trip.leg,
    departure: trip.departure,
    freeSeats: 2,
    price: MarketSeed.quote(trip.contribution, corridor: cairo),
  );
}

RequestCard _request(TripFit fit, {Clock? joinTime}) {
  final r = MarketSeed.requests(_now).first;
  return RequestCard(
    requestId: r.id,
    leg: r.leg,
    from: r.from,
    to: r.to,
    rider: const AnonymousRider(isWoman: true, rating: 4.9),
    pickup: r.pickup,
    date: r.date,
    departure: r.departure,
    repeat: r.repeat,
    price: r.price,
    detourMinutes: 3,
    fit: fit,
    joinTime: joinTime,
  );
}

Future<void> _golden(WidgetTester tester, Locale locale, String name, Widget Function(WallTime now) build) async {
  await loadAppFonts();
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: locales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(locale),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsetsDirectional.all(AppSpacing.tabH), child: build(_now)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final dir = locale == ar ? 'rtl' : 'ltr';
  await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/marketplace_${name}_$dir.png'));
}

void main() {
  for (final locale in locales) {
    final dir = locale == ar ? 'rtl' : 'ltr';

    testWidgets('seat card [$dir]', (tester) async {
      await _golden(tester, locale, 'seat_card', (now) => SeatCard(offer: _seat(), now: now, busy: false, onBook: () {}));
    });

    testWidgets('seat card, Cairo ↔ Ismailia [$dir]', (tester) async {
      await _golden(
          tester, locale, 'seat_card_cairo', (now) => SeatCard(offer: _cairoSeat(), now: now, busy: false, onBook: () {}));
    });

    testWidgets('request cards: create, join, limit [$dir]', (tester) async {
      await _golden(
        tester,
        locale,
        'request_cards',
        (now) => Column(
          children: [
            RequestCardView(card: _request(const TripFit.create(1)), now: now, onAccept: () {}),
            const SizedBox(height: AppSpacing.md),
            RequestCardView(
              card: _request(const TripFit.join('of-1'), joinTime: const Clock.hm(7, 30)),
              now: now,
              onAccept: () {},
            ),
            const SizedBox(height: AppSpacing.md),
            RequestCardView(card: _request(const TripFit.limitReached()), now: now, onAccept: () {}),
          ],
        ),
      );
    });

    testWidgets('offered trip live card [$dir]', (tester) async {
      final trip = MarketSeed.offers(_now).first;
      final live = OfferLive(
        trip: trip,
        riders: const [
          LiveRider(rider: AnonymousRider(isWoman: true, rating: 4.6)),
          LiveRider(rider: AnonymousRider(isWoman: false)),
        ],
      );
      await _golden(
        tester,
        locale,
        'offer_live',
        (now) => GooraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OfferProgress(live: live),
              const SizedBox(height: AppSpacing.md),
              LiveRidersList(riders: live.riders),
            ],
          ),
        ),
      );
    });
  }
}
