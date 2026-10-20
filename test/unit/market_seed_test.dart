import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/corridor.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/commute/domain/pricing_service.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/domain/market_day.dart';

/// 006 T029: the marketplace seed per corridor. Same row counts on both,
/// nothing on one corridor points at the other's areas.
void main() {
  final now = WallTime(const CalendarDate.ymd(2026, 10, 19), const Clock.hm(5, 0));
  const cairo = Corridors.cairoIsmailia;
  const old = Corridors.sheikhZayedSmartVillage;

  void rowsStayInside(Corridor c, {required String name}) {
    final requests = MarketSeed.requests(now, corridor: c);
    final offers = MarketSeed.offers(now, corridor: c);

    group('$name seed rows', () {
      test('12 morning + 4 evening requests, 2 offers', () {
        expect(requests.where((r) => r.leg == Leg.going), hasLength(12));
        expect(requests.where((r) => r.leg == Leg.ret), hasLength(4));
        expect(offers, hasLength(2));
      });

      test('every request and offer uses only this corridor\'s areas', () {
        for (final r in requests) {
          expect(c.areas, containsAll([r.from, r.to]), reason: r.id);
          expect(c.areas, containsAll(r.detourFrom.keys), reason: '${r.id} detourFrom');
        }
        for (final o in offers) {
          expect(c.areas, containsAll([o.from, o.to]), reason: o.id);
        }
      });

      test('ids keep the seed prefix, unique', () {
        final ids = [for (final r in requests) r.id, for (final o in offers) o.id];
        expect(ids.toSet().length, ids.length);
        expect(ids.every(MarketSeed.isSeedId), isTrue);
      });

      test('price basis and contributions come from the corridor', () {
        final range = PricingService.range(c.tripCost, c.riderSeats);
        for (final r in requests) {
          expect(range.contains(r.price.contribution), isTrue, reason: r.id);
        }
        for (final o in offers) {
          expect(o.tripCost, c.tripCost, reason: o.id);
          expect(o.riderSeats, c.riderSeats, reason: o.id);
          expect(range.contains(o.contribution), isTrue, reason: o.id);
          expect(o.seats, lessThanOrEqualTo(c.riderSeats), reason: o.id);
        }
      });

      test('each row is on a running day, ahead of the demo clock', () {
        for (final r in requests) {
          expect(MarketDay.workdays, contains(r.date.weekday), reason: r.id);
          expect(MarketDay.isExpired(r.date, r.departure, now), isFalse, reason: r.id);
        }
        for (final o in offers) {
          expect(MarketDay.workdays, contains(o.date.weekday), reason: o.id);
          expect(MarketDay.isExpired(o.date, o.departure, now), isFalse, reason: o.id);
        }
      });

      test('pickup point is the area\'s public point, never a home', () {
        for (final r in requests) {
          expect(r.pickup.point, MarketSeed.pickupIn(r.from, 'x', r.departure).point, reason: r.id);
        }
        for (final o in offers) {
          expect(o.pickup.point, MarketSeed.pickupIn(o.from, 'x', o.departure).point, reason: o.id);
        }
      });
    });
  }

  rowsStayInside(old, name: 'Sheikh Zayed');
  rowsStayInside(cairo, name: 'Cairo ↔ Ismailia');

  test('the default corridor is the old one: existing callers see the same rows', () {
    expect([for (final r in MarketSeed.requests(now)) r.id], [for (final r in MarketSeed.requests(now, corridor: old)) r.id]);
    expect(MarketSeed.requests(now).every((r) => old.areas.contains(r.from)), isTrue);
    expect(MarketSeed.offers(now).first.contribution, 44);
  });

  group('Cairo ↔ Ismailia shape', () {
    final requests = MarketSeed.requests(now, corridor: cairo);

    test('mornings go New Cairo → Ismailia 06:30–07:30, evenings back 16:30–17:30', () {
      for (final r in requests.where((r) => r.leg == Leg.going)) {
        expect([r.from, r.to], [Area.newCairo, Area.ismailia]);
        expect(r.departure.minutes, inInclusiveRange(const Clock.hm(6, 30).minutes, const Clock.hm(7, 30).minutes));
      }
      for (final r in requests.where((r) => r.leg == Leg.ret)) {
        expect([r.from, r.to], [Area.ismailia, Area.newCairo]);
        expect(r.departure.minutes, inInclusiveRange(const Clock.hm(16, 30).minutes, const Clock.hm(17, 30).minutes));
      }
    });

    test('detours cover every Cairo-side area; a mix fits a driver (< 10) and some do not', () {
      final going = requests.where((r) => r.leg == Leg.going).toList();
      for (final r in going) {
        expect(r.detourFrom.keys, containsAll([Area.newCairo, Area.nasrCity, Area.heliopolis, Area.obour, Area.tenthOfRamadan]));
      }
      final fits = [for (final r in going) for (final d in r.detourFrom.values) d < 10];
      expect(fits, contains(true));
      expect(fits, contains(false));
    });

    test('offers: one just-once going, one every-workday return', () {
      final offers = MarketSeed.offers(now, corridor: cairo);
      expect(offers.first.leg, Leg.going);
      expect(offers.last.leg, Leg.ret);
      expect(offers.first.seats, 3);
    });
  });

  test('pickupIn and pointIn answer for every area', () {
    for (final a in Area.values) {
      expect(MarketSeed.pickupIn(a, 's', const Clock.hm(7, 0)).id, 's');
      MarketSeed.pointIn(a);
    }
  });
}
