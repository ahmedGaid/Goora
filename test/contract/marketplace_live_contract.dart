import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/marketplace/domain/marketplace_repository.dart';

/// A signed-in verified rider with a payment method, and at least one seat offer
/// (from another driver) on the going leg.
typedef LiveMarketSetup = ({MarketplaceRepository repo, WallTime now});

/// 013 marketplace live-parity cases (ML1, ML2). The fake and the Supabase
/// implementation must agree.
void marketplaceLiveContract(String label, Future<LiveMarketSetup> Function() make) {
  group('marketplace live contract [$label]', () {
    test('ML1 every seat offer names its driver by first name and initials', () async {
      final s = await make();
      final offers = await s.repo.seatOffers(Leg.going, now: s.now);
      expect(offers, isNotEmpty);
      for (final o in offers) {
        expect(o.driver.firstName, isNotEmpty);
        expect(o.driver.initials, isNotEmpty);
      }
    });

    test('ML2 a booked seat is reclaimed once, with what was paid back', () async {
      final s = await make();
      final offer = (await s.repo.seatOffers(Leg.going, now: s.now)).first;
      final booked = await s.repo.book(offer, now: s.now);
      expect(booked, isA<Booked>());
      final booking = (booked as Booked).booking;
      expect([for (final b in await s.repo.myBookings(now: s.now)) b.id], contains(booking.id));

      final first = await s.repo.reclaim(booking.id, now: s.now);
      expect(first, isA<Reclaimed>());
      expect((first as Reclaimed).refund, booking.paid);
      expect([for (final b in await s.repo.myBookings(now: s.now)) b.id], isNot(contains(booking.id)));

      expect(await s.repo.reclaim(booking.id, now: s.now), isA<NotReclaimable>());
    });
  });
}
