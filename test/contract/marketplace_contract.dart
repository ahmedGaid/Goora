import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/corridor.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/commute/domain/pricing_service.dart';
import 'package:goora/features/marketplace/domain/marketplace_repository.dart';
import 'package:goora/features/marketplace/domain/offered_trip.dart';
import 'package:goora/features/marketplace/domain/trip_request.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

/// A signed-in person of [Role] in no group, verified, with a payment method.
typedef MarketSetup = ({MarketplaceRepository repo, Corridor corridor});

/// 011 contracts/seam-contracts.md — Marketplace (M1–M5).
void marketplaceContract(String label, Future<MarketSetup> Function(Role role) make) {
  final now = WallTime(CalendarDate(2026, 11, 1), const Clock.hm(6, 0));

  OfferDraft offer(Corridor c, Leg leg, Clock at) {
    final going = leg == Leg.going;
    return OfferDraft(
      leg: leg,
      from: going ? Area.sheikhZayed : Area.smartVillage,
      to: going ? Area.smartVillage : Area.sheikhZayed,
      departure: at,
      seats: 3,
      contribution: PricingService.range(c.tripCost, 3).suggested,
      repeat: Repeat.once,
    );
  }

  const ask = TripDraft(
      leg: Leg.going, from: Area.sheikhZayed, to: Area.smartVillage, departure: Clock.hm(7, 30), repeat: Repeat.once);

  group('marketplace contract [$label]', () {
    test('M1 a verified driver publishes; offer() reads it back', () async {
      final s = await make(Role.driver);
      final r = await s.repo.publish(offer(s.corridor, Leg.going, const Clock.hm(7, 30)), now: now);
      final trip = (r as Published).trip;
      expect((trip.leg, trip.seats, trip.status), (Leg.going, 3, OfferStatus.open));
      final back = await s.repo.offer(trip.id, now: now);
      expect((back?.id, back?.contribution), (trip.id, trip.contribution));
    });

    test('M2 a third trip the same day is over the limit', () async {
      final s = await make(Role.driver);
      expect(await s.repo.publish(offer(s.corridor, Leg.going, const Clock.hm(7, 30)), now: now), isA<Published>());
      expect(await s.repo.publish(offer(s.corridor, Leg.ret, const Clock.hm(17, 0)), now: now), isA<Published>());
      expect(await s.repo.publish(offer(s.corridor, Leg.going, const Clock.hm(9, 0)), now: now), isA<OverLimit>());
    });

    test('M3 a rider posts; myRequests has it; cancelling removes it', () async {
      final s = await make(Role.rider);
      final posted = (await s.repo.post(ask, now: now) as Posted).request;
      expect(posted.status, RequestStatus.posted);
      expect([for (final r in await s.repo.myRequests(now: now)) r.id], [posted.id]);
      await s.repo.cancelRequest(posted.id);
      expect(await s.repo.myRequests(now: now), isEmpty);
    });

    test('M4 request(id) returns the posted request', () async {
      final s = await make(Role.rider);
      final posted = (await s.repo.post(ask, now: now) as Posted).request;
      final back = await s.repo.request(posted.id, now: now);
      expect((back?.id, back?.leg, back?.from, back?.departure), (posted.id, Leg.going, Area.sheikhZayed, ask.departure));
      expect(back?.price.contribution, posted.price.contribution);
    });

    test('M5 the driver cancels their own trip', () async {
      final s = await make(Role.driver);
      final trip = (await s.repo.publish(offer(s.corridor, Leg.going, const Clock.hm(7, 30)), now: now) as Published).trip;
      await s.repo.cancelOffer(trip.id, now: now);
      expect((await s.repo.offer(trip.id, now: now))?.status, OfferStatus.cancelled);
    });
  });
}
