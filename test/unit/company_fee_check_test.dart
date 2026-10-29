import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/group_catalog.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart' show Leg;
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/company/domain/company_rules.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/domain/anonymous_rider.dart';
import 'package:goora/features/marketplace/domain/booking.dart';
import 'package:goora/features/marketplace/domain/marketplace_repository.dart';
import 'package:goora/features/marketplace/domain/offered_trip.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/fake_payment_provider.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/domain/cash_mark.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:goora/features/wallet/domain/seat_price.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

/// 010 T028 (US2 AC3, AC5; FR-007, FR-008, SC-003): a covered employee pays
/// no Goora fee on a group trip or a one-off seat, the driver's share is
/// unchanged, they hold the subscriber's reclaim right on a full car and
/// lose it the minute they leave; the 007/008 blocks still come first.
/// On the real fakes, no mocks; coverage comes through the wallet seam.
final _tue = rideTuesday;
final _wed = _tue.addDays(1);
int _m(WallTime t) => SharePolicy.minuteOf(t);

typedef _World = ({FakeMarketplaceRepository repo, FakeWalletRepository wallet, TestClock clock, SharedPreferences prefs});

/// An InstaPay rider past the trial (seats carry the fee unless covered), on
/// a company plan since Tue 08:00 whose coverage is [windows].
Future<_World> _world(List<Window> windows, {Map<String, Object> extra = const {}}) async {
  SharedPreferences.setMockInitialValues({
    ...memberPrefs(role: Role.rider, member: false, method: PaymentMethod.instapay, pastTrial: true),
    FakeWalletRepository.planKey: jsonEncode(
      Plan(
        personId: DailySeed.meId,
        type: PlanType.company,
        status: PlanStatus.active,
        price: 0,
        startDate: at(_tue, 8, 0),
      ).toJson(),
    ),
    ...extra,
  });
  final prefs = await SharedPreferences.getInstance();
  final clock = TestClock(at(_tue, 20, 0));
  final person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: Role.rider);
  final catalog = GroupCatalog(prefs);
  final daily = FakeDailyCommuteRepository(
    prefs,
    commute: FakeCommuteRepository(prefs, catalog: catalog),
    person: () => person,
    now: clock.call,
    catalog: catalog,
  );
  late final FakeMarketplaceRepository repo;
  final wallet = FakeWalletRepository(
    prefs,
    daily: daily,
    role: () => MemberRole.rider,
    now: clock.call,
    provider: FakePaymentProvider(),
    oneOffs: () => repo.doneOneOffs(),
    companyCoverage: (_) async => windows,
  );
  repo = FakeMarketplaceRepository(
    prefs,
    catalog: catalog,
    daily: daily,
    commute: FakeCommuteRepository(prefs, catalog: catalog),
    notices: daily,
    ledger: () => wallet,
    wallet: () => wallet,
    trust: FakeTrustRepository(prefs, person: () => person, now: clock.call),
    now: clock.call,
    corridor: Corridors.sheikhZayedSmartVillage,
  );
  await wallet.topUp('me', method: 'card', amount: 200);
  return (repo: repo, wallet: wallet, clock: clock, prefs: prefs);
}

/// Enrolled at Tue 08:00, still enrolled.
final _covered = [(from: _m(at(_tue, 8, 0)), to: null)];

/// Enrolled at Tue 08:00, left at 19:59 — one minute before the clock.
final _leftAMinuteAgo = [(from: _m(at(_tue, 8, 0)), to: _m(at(_tue, 19, 59)))];

OfferedTrip _offer(String id, {required CalendarDate date, String driverId = 'khaled', int seats = 3, Clock departure = const Clock.hm(9, 0)}) =>
    OfferedTrip(
      id: id,
      driverId: driverId,
      leg: Leg.going,
      from: Area.sheikhZayed,
      to: Area.smartVillage,
      date: date,
      departure: departure,
      seats: seats,
      riderSeats: 3,
      tripCost: Corridors.sheikhZayedSmartVillage.tripCost,
      contribution: 40,
      repeat: Repeat.once,
      pickup: MarketSeed.offers(WallTime(date, departure)).first.pickup,
    );

Booking _booking(String id, {required String offerId, required CalendarDate date, String riderId = 'seed-rider-nadia', BookingStatus status = BookingStatus.booked, PaidBy paidBy = PaidBy.wallet, required WallTime bookedAt}) =>
    Booking(
      id: id,
      riderId: riderId,
      riderName: 'Nadia',
      rider: const AnonymousRider(isWoman: true, rating: 4.6),
      source: BookingSource.offer(offerId),
      date: date,
      leg: Leg.going,
      rideId: Booking.offerRideId(offerId),
      price: MarketSeed.quote(40),
      paidBy: paidBy,
      paid: paidBy == PaidBy.cash ? 0 : 44,
      bookedAt: bookedAt,
      isSubscriber: false,
      status: status,
    );

Future<BookResult> _bookOffer(_World w, String offerId) async {
  final seats = await w.repo.seatOffers(Leg.going, now: w.clock.now);
  final seat = seats.where((s) => s.source == BookingSource.offer(offerId)).firstOrNull;
  if (seat == null) return const SeatTaken();
  return w.repo.book(seat, now: w.clock.now);
}

void main() {
  group('no Goora fee while covered, the driver share unchanged (FR-007, SC-003)', () {
    test('group trip: the mode is company, fee 0, same share as a per-trip rider', () async {
      final w = await _world(_covered);
      final plan = (await w.wallet.getPlan('me'))!;
      final mode = PricingMode.of(plan: plan, now: w.clock.now, trialAvailable: false);
      expect(mode, PricingMode.company);
      const trip = Corridors.sheikhZayedSmartVillage;
      final covered = SeatPrice.of(40, tripCost: trip.tripCost, riderSeats: 3, mode: mode, method: PaymentMethod.instapay);
      final paying =
          SeatPrice.of(40, tripCost: trip.tripCost, riderSeats: 3, mode: PricingMode.perTrip, method: PaymentMethod.instapay);
      expect(covered.fee, 0);
      expect(paying.fee, greaterThan(0));
      expect(covered.share, paying.share, reason: 'the fee pays only Goora; the share is the driver\'s');
    });

    test('one-off seat: fee 0 while covered, the fee one minute after leaving, the same share both times', () async {
      final covered = await _world(_covered);
      final a = (await _bookOffer(covered, MarketSeed.tarekId) as Booked).booking;
      expect(a.price.fee, 0);
      expect((await covered.wallet.getWallet('me')).balance, 200);

      final left = await _world(_leftAMinuteAgo);
      final b = (await _bookOffer(left, MarketSeed.tarekId) as Booked).booking;
      expect(b.price.fee, greaterThan(0));
      expect(a.price.share, b.price.share);
    });
  });

  group('the subscriber reclaim right (005 US6, FR-008)', () {
    Map<String, Object> fullCar() => {
          FakeMarketplaceRepository.offersKey: jsonEncode([
            _offer('of-9', date: _wed, seats: 1).toJson(),
          ]),
          FakeMarketplaceRepository.bookingsKey: jsonEncode([
            _booking('bk-1', offerId: 'of-9', date: _wed, bookedAt: at(_tue, 10, 0)).toJson(),
          ]),
        };

    test('covered: takes the newest reclaimable seat of a full car', () async {
      final w = await _world(_covered, extra: fullCar());
      final r = await _bookOffer(w, 'of-9');
      expect(r, isA<Booked>());
      final stored = (jsonDecode(w.prefs.getString(FakeMarketplaceRepository.bookingsKey)!) as List)
          .cast<Map<String, Object?>>();
      expect({for (final b in stored) b['id']: b['status']}['bk-1'], BookingStatus.reclaimed.name);
    });

    test('one minute after leaving: the full car is gone, nobody loses their seat', () async {
      final w = await _world(_leftAMinuteAgo, extra: fullCar());
      expect(await _bookOffer(w, 'of-9'), isA<SeatTaken>());
      final stored = (jsonDecode(w.prefs.getString(FakeMarketplaceRepository.bookingsKey)!) as List)
          .cast<Map<String, Object?>>();
      expect(stored.single['status'], BookingStatus.booked.name);
    });
  });

  group('007/008 blocks still come first for a covered employee (US2 AC5)', () {
    test('a share the driver marked as not received blocks booking', () async {
      final day = _tue;
      final w = await _world(_covered, extra: {
        FakeMarketplaceRepository.offersKey: jsonEncode([
          _offer('of-owed', date: day, departure: const Clock.hm(7, 0)).toJson(),
        ]),
        FakeMarketplaceRepository.bookingsKey: jsonEncode([
          _booking('bk-owed',
                  offerId: 'of-owed',
                  date: day,
                  riderId: 'me',
                  status: BookingStatus.done,
                  paidBy: PaidBy.cash,
                  bookedAt: at(day.addDays(-1), 12, 0))
              .toJson(),
        ]),
      });
      await w.wallet.markShare(CashMark(
        rideId: Booking.offerRideId('of-owed'),
        riderId: 'me',
        driverId: 'khaled',
        outcome: CashOutcome.didNotPay,
        amount: 40,
        date: day,
      ));
      expect(await _bookOffer(w, MarketSeed.tarekId), isA<BookOwesDriver>());
    });
  });
}
