import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/core/widgets/goora_status_chip.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/notice.dart';
import 'package:goora/features/daily/presentation/today/pickup_check_in.dart';
import 'package:goora/features/daily/presentation/today/today_screen.dart';
import 'package:goora/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/domain/anonymous_rider.dart';
import 'package:goora/features/marketplace/domain/booking.dart';
import 'package:goora/features/marketplace/domain/marketplace_repository.dart';
import 'package:goora/features/marketplace/domain/offered_trip.dart';
import 'package:goora/features/marketplace/presentation/find_riders/find_riders_controller.dart';
import 'package:goora/features/marketplace/presentation/find_riders/find_riders_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/cash_mark.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US3: driver Today and pickup check-in, ar + en (FR-013 – FR-016).
/// Rotation with three drivers (ahmed, me, mohamed) from Sun 4 Oct gives me
/// Monday and Thursday.
final _wed = rideTuesday.addDays(1);
final _thu = rideTuesday.addDays(2);

/// Ahmed and Mohamed (off duty) are away on Thursday, leaving Sara and Youssef.
Map<String, Object> _twoPassengers() => {
      FakeDailyCommuteRepository.absencesKey: jsonEncode([
        for (final id in ['ahmed', 'mohamed'])
          for (final leg in Leg.values)
            Absence(personId: id, date: _thu, leg: leg, madeAt: at(_wed, 12, 0), kind: AbsenceKind.freeCancel).toJson(),
      ]),
    };

Future<ProviderContainer> _pump(WidgetTester tester, TestClock clock, String locale, {Map<String, Object> extra = const {}}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {...memberPrefs(role: Role.driver, locale: locale), ...extra},
    overrides: dailyOverrides(clock),
  );
  tester.view.physicalSize = const Size(390, 2400);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] hero: tomorrow, both ways, stops, contribution 2 × 40 × 2 = 160', (tester) async {
      await _pump(tester, TestClock(at(_wed, 20, 0)), code, extra: _twoPassengers());
      expect(find.text(l.drivingWhen(l.relTomorrowDay(l.dayThu))), findsOneWidget);
      expect(find.text(l.offerBtn), findsOneWidget);
      expect(find.text(l.browseBtn), findsOneWidget);
      expect(find.text(l.heroDriver(l.heroTomorrow, l.dirBoth, 2)), findsOneWidget);
      expect(find.text(l.pickupN(1, l.stopMainGate)), findsOneWidget);
      expect(find.text(l.pickupN(2, l.stopCentralSt)), findsOneWidget);
      expect(find.text(l.timeAm('7:20')), findsOneWidget);
      expect(find.text(l.timeAm('8:05')), findsOneWidget);
      expect(find.text(l.returnFrom(l.stopSmartVillageGate2)), findsOneWidget);
      expect(find.text(l.estContrib), findsOneWidget);
      expect(find.text(l.egpAmount(160)), findsOneWidget);
      expect(find.text(l.reqsOnRoute), findsOneWidget);
      expect(find.text(l.reqPrivacy), findsOneWidget);
      expect(find.text(l.sos), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('[$code] inbox: seat reclaimed shows its text and the two actions (T040)', (tester) async {
      final c = await _pump(tester, TestClock(at(_wed, 12, 0)), code);
      await (c.read(dailyCommuteRepositoryProvider) as NoticeSink)
          .post(NoticeKind.seatReclaimed, {'day': _thu.toIso(), 'amount': '44'});
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inbox')));
      await tester.pumpAndSettle();
      expect(find.text(l.seatReclaimed(l.dayThu, 44)), findsOneWidget);
      expect(find.byKey(const Key('notice-empty-seats')), findsOneWidget);
      expect(find.byKey(const Key('notice-post-trip')), findsOneWidget);
      expect(find.text(l.seeEmptySeats), findsOneWidget);
      expect(find.text(l.postReq), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('[$code] inbox: a cash seat reclaimed says nothing to refund, not "0 EGP back" (T104 F18)',
        (tester) async {
      final c = await _pump(tester, TestClock(at(_wed, 12, 0)), code);
      await (c.read(dailyCommuteRepositoryProvider) as NoticeSink)
          .post(NoticeKind.seatReclaimed, {'day': _thu.toIso(), 'amount': '0'});
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inbox')));
      await tester.pumpAndSettle();
      expect(find.text(l.seatReclaimedCash(l.dayThu)), findsOneWidget);
      expect(find.text(l.seatReclaimed(l.dayThu, 0)), findsNothing);
      expect(find.byKey(const Key('notice-empty-seats')), findsOneWidget);
      expect(find.byKey(const Key('notice-post-trip')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('[$code] confirm ⇄ undo confirmation', (tester) async {
      await _pump(tester, TestClock(at(_wed, 20, 0)), code);
      await tester.tap(find.byKey(const Key('confirm-drive')));
      await tester.pumpAndSettle();
      expect(find.text(l.confirmedNote), findsOneWidget);
      expect(find.text(l.undoConfirm), findsOneWidget);
      await tester.tap(find.byKey(const Key('undo-confirm')));
      await tester.pumpAndSettle();
      expect(find.text(l.confirmDrive), findsOneWidget);
    });

    testWidgets('[$code] report delay: 10 min shifts the stops and tells riders', (tester) async {
      await _pump(tester, TestClock(at(_wed, 20, 0)), code);
      await tester.tap(find.byKey(const Key('report-delay')));
      await tester.pumpAndSettle();
      expect(find.text(l.delayTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('delay-10')));
      await tester.pumpAndSettle();
      expect(find.text(l.delaySent(l.timeAm('7:30'))), findsOneWidget);
      expect(find.text(l.timeAm('7:35')), findsOneWidget, reason: 'Central St. 7:25 → 7:35');
    });

    testWidgets("[$code] can't drive: confirm, then the group is told", (tester) async {
      await _pump(tester, TestClock(at(_wed, 20, 0)), code);
      await tester.tap(find.byKey(const Key('cant-drive')));
      await tester.pumpAndSettle();
      expect(find.text(l.cantDriveConfirm), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-cant-drive')));
      await tester.pumpAndSettle();
      expect(find.text(l.cantDriveDone(l.relTomorrowDay(l.dayThu))), findsOneWidget);
      expect(find.text(l.heroDriver(l.heroTomorrow, l.dirBoth, 4)), findsNothing);
    });

    testWidgets('[$code] check-in: anonymous until picked up; no-show only at 5:00', (tester) async {
      final clock = TestClock(at(_thu, 7, 18));
      await _pump(tester, clock, code);
      expect(find.text(l.arrivedAt(l.stopMainGate)), findsOneWidget);
      clock.now = at(_thu, 7, 20);
      await tester.tap(find.byKey(const Key('arrived-main-gate')));
      await tester.pumpAndSettle();
      expect(find.text(l.arrivedNote), findsOneWidget);
      // Main Gate: Ahmed (off duty) and Sara, both anonymous.
      final checkIn = find.byType(PickupCheckIn);
      expect(find.descendant(of: checkIn, matching: find.text(l.verifiedRider)), findsOneWidget);
      expect(find.descendant(of: checkIn, matching: find.text(l.verifiedRiderWoman)), findsOneWidget);
      expect(find.text('Sara'), findsNothing);
      expect(find.text(l.stWaiting('5:00')), findsNWidgets(2));

      clock.now = at(_thu, 7, 24, 59);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(l.stWaiting('0:01')), findsNWidgets(2));
      await tester.tap(find.byKey(const Key('noshow-sara')));
      await tester.pumpAndSettle();
      expect(find.text(l.stNoShow), findsNothing, reason: 'disabled at 4:59');

      await tester.tap(find.byKey(const Key('picked-ahmed')));
      await tester.pumpAndSettle();
      expect(find.text('Ahmed'), findsOneWidget, reason: 'name shows once picked up');

      clock.now = at(_thu, 7, 25);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('picked-sara')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('noshow-sara')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(GooraStatusChip, l.stNoShow), findsOneWidget, reason: 'switch until start');
      expect(find.text(l.noShowNote), findsOneWidget);

      await tester.tap(find.byKey(const Key('arrived-central-st')));
      await tester.pumpAndSettle();
      clock.now = at(_thu, 7, 31);
      await tester.tap(find.byKey(const Key('picked-mohamed')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('picked-youssef')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-trip')));
      await tester.pumpAndSettle();
      expect(find.text(l.tripOnWay), findsOneWidget);
      expect(find.byKey(const Key('picked-sara')), findsNothing, reason: 'marks are final');

      // Inbox: what riders were told, including Sara's no-show charge.
      await tester.tap(find.byKey(const Key('inbox')));
      await tester.pumpAndSettle();
      expect(find.text(l.nNoShow(l.dayThu, 40)), findsOneWidget);
      expect(find.text(l.nDriverArrived(l.stopMainGate)), findsOneWidget);
      expect(find.text(l.sentToRiders), findsWidgets);
    });
  }

  testWidgets('inbox empty state is designed', (tester) async {
    await _pump(tester, TestClock(at(_wed, 12, 0)), 'en');
    await tester.tap(find.byKey(const Key('inbox')));
    await tester.pumpAndSettle();
    final l = l10nFor(en);
    expect(find.byKey(const Key('inbox-empty')), findsOneWidget);
    expect(find.text(l.inboxEmpty), findsOneWidget);
    expect(find.text(l.inboxEmptyBody), findsOneWidget);
  });

  testWidgets('off-duty day: "Riding today with …" card (FR-022a)', (tester) async {
    await _pump(tester, TestClock(at(rideTuesday, 7, 0)), 'en');
    final l = l10nFor(en);
    expect(find.text(l.rideWith(l.relToday, 'Mohamed')), findsOneWidget);
  });

  testWidgets('driver screen fits at 1.3× text size with labelled targets', (tester) async {
    await _pump(tester, TestClock(at(_wed, 20, 0)), 'en');
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  // 005 US2 (T065): the driver's offered trip on Today.
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    OfferedTrip trip() => OfferedTrip(
          id: 'of-9',
          driverId: 'me',
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
        );

    Booking booked(String id, String riderId, String name, {PaidBy paidBy = PaidBy.wallet, double? rating = 4.6}) =>
        Booking(
          id: id,
          riderId: riderId,
          riderName: name,
          rider: AnonymousRider(isWoman: true, rating: rating),
          source: const BookingSource.offer('of-9'),
          date: _wed,
          leg: Leg.going,
          rideId: Booking.offerRideId('of-9'),
          price: MarketSeed.quote(40),
          paidBy: paidBy,
          paid: paidBy == PaidBy.cash ? 0 : 44,
          bookedAt: at(rideTuesday, 10, 0),
          isSubscriber: false,
        );

    Map<String, Object> offered(List<Booking> bookings) => {
          FakeMarketplaceRepository.offersKey: jsonEncode([trip().toJson()]),
          FakeMarketplaceRepository.bookingsKey: jsonEncode([for (final b in bookings) b.toJson()]),
        };

    Future<ProviderContainer> pumpToday(WidgetTester tester, WallTime now, Map<String, Object> extra,
        {bool member = true}) async {
      final c = await pumpGooraApp(
        tester,
        prefs: {...memberPrefs(role: Role.driver, locale: code, member: member), ...extra},
        overrides: dailyOverrides(TestClock(now)),
      );
      tester.view.physicalSize = const Size(390, 3200);
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('[$code] offered trip card: progress, anonymous riders, Cancel trip — no Share/SOS before departure',
        (tester) async {
      await pumpToday(tester, at(rideTuesday, 20, 0), offered([booked('bk-1', 'seed-rider-nadia', 'Nadia')]));
      expect(find.byKey(const Key('driver-offer-of-9')), findsOneWidget);
      expect(find.text(l.oneOffTrips), findsOneWidget);
      expect(find.text(l.seatsBooked(1, 3)), findsOneWidget);
      final card = find.byKey(const Key('driver-offer-of-9'));
      expect(find.descendant(of: card, matching: find.text(l.verifiedRiderWoman)), findsOneWidget);
      expect(find.text('Nadia'), findsNothing, reason: 'no name before departure (FR-023)');
      expect(find.byKey(const Key('cancel-trip-of-9')), findsOneWidget);
      expect(find.byKey(const Key('offer-share-of-9')), findsNothing);
      expect(find.byKey(const Key('offer-sos-of-9')), findsNothing);
    });

    testWidgets('[$code] from departure: names, Share and SOS one tap away, nothing left to cancel', (tester) async {
      await pumpToday(tester, at(_wed, 9, 5), offered([booked('bk-1', 'seed-rider-nadia', 'Nadia')]));
      expect(find.text('Nadia'), findsOneWidget);
      expect(find.text(l.tripDepartedState), findsOneWidget);
      expect(find.byKey(const Key('offer-share-of-9')), findsOneWidget);
      expect(find.byKey(const Key('offer-sos-of-9')), findsOneWidget);
      expect(find.byKey(const Key('cancel-trip-of-9')), findsNothing);
    });

    testWidgets('[$code] a driver with no group and only a once trip still sees Share + SOS during it', (tester) async {
      // A once driver: the resume step lands on Today because a live offer exists (R12).
      final onceProfile = jsonEncode(
        Profile(
          phone: testPhone,
          firstName: 'Omar',
          lastName: 'Khaled',
          gender: Gender.male,
          role: Role.driver,
          frequency: Frequency.once,
        ).toJson(),
      );
      await pumpToday(
        tester,
        at(_wed, 9, 5),
        {...offered([booked('bk-1', 'seed-rider-nadia', 'Nadia')]), 'profile': onceProfile},
        member: false,
      );
      expect(find.byKey(const Key('driver-offer-of-9')), findsOneWidget);
      expect(find.byKey(const Key('offer-share-of-9')), findsOneWidget);
      expect(find.byKey(const Key('offer-sos-of-9')), findsOneWidget);
    });

    testWidgets('[$code] after done: cash riders get Received / Didn\'t pay, stored against offer:<id>', (tester) async {
      final c = await pumpToday(
        tester,
        at(_wed, 9, 45),
        offered([
          booked('bk-1', 'seed-rider-nadia', 'Nadia', paidBy: PaidBy.cash),
          booked('bk-2', 'seed-rider-omar', 'Omar'),
        ]),
      );
      expect(find.text(l.tripDoneState), findsOneWidget);
      expect(find.byKey(const Key('cash-received-seed-rider-nadia')), findsOneWidget);
      expect(find.text(l.cashReceived(40)), findsOneWidget);
      expect(find.byKey(const Key('cash-received-seed-rider-omar')), findsNothing, reason: 'a wallet rider paid already');

      final button = find.byKey(const Key('cash-received-seed-rider-nadia'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text(l.cashMarkedReceived), findsOneWidget);
      final marks = await c.read(walletRepositoryProvider).cashMarks(Booking.offerRideId('of-9'));
      expect(marks.map((m) => (m.rideId, m.riderId, m.outcome, m.amount)), [
        ('offer:of-9', 'seed-rider-nadia', CashOutcome.received, 40),
      ]);
    });
  }

  // 005 US5 (T090): driver Today's requests.
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    Future<ProviderContainer> pumpRequests(WidgetTester tester, WallTime now, {List<Override> overrides = const []}) async {
      final c = await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.driver, locale: code),
        overrides: [...dailyOverrides(TestClock(now)), ...overrides],
      );
      tester.view.physicalSize = const Size(390, 4200);
      await tester.pumpAndSettle();
      return c;
    }

    Future<void> tapIt(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    testWidgets('[$code] requests: the demand banner and up to 3 cards with detour and Accept', (tester) async {
      await pumpRequests(tester, at(rideTuesday, 20, 0));
      expect(
        find.text(l.demandBanner(12, l.routeLine(l.areaSheikhZayed, l.areaSmartVillage), 'morning')),
        findsOneWidget,
      );
      final cards = find.byWidgetPredicate((w) => '${w.key}'.startsWith("[<'request-rq-seed-"));
      expect(cards, findsNWidgets(3));
      expect(find.byKey(const Key('requests-see-all')), findsOneWidget);
      expect(find.byKey(const Key('accept-rq-seed-m02')), findsOneWidget);
      // "Omar" is the signed-in driver's own greeting, not a rider.
      for (final rider in MarketSeed.riders.where((r) => r.firstName != 'Omar')) {
        expect(find.textContaining(rider.firstName), findsNothing, reason: 'SC-004');
      }
    });

    testWidgets('[$code] off-duty day: Accept → Accepted ✓; a daily request says one group only', (tester) async {
      // Tuesday evening: the requests are for Wednesday, a day this driver does not drive.
      await pumpRequests(tester, at(rideTuesday, 20, 0));
      expect(find.byKey(const Key('blocked-rq-seed-m01')), findsOneWidget);
      expect(find.text(l.oneGroupOnly), findsOneWidget);
      await tapIt(tester, find.byKey(const Key('accept-rq-seed-m02')));
      await tapIt(tester, find.byKey(const Key('confirm-accept-rq-seed-m02')));
      expect(find.byKey(const Key('accepted-rq-seed-m02')), findsOneWidget);
      expect(find.text(l.accepted), findsOneWidget);
    });

    testWidgets('[$code] a day driving both legs: cards near the group trip are full, the rest over the limit', (tester) async {
      // Wednesday evening: the requests are for Thursday, when this driver drives both legs.
      await pumpRequests(tester, at(rideTuesday.addDays(1), 20, 0));
      expect(find.byWidgetPredicate((w) => '${w.key}'.startsWith("[<'accept-rq-seed-")), findsNothing);
      expect(find.text(l.yourCarFull), findsWidgets);
      expect(find.byKey(const Key('blocked-rq-seed-m01')), findsOneWidget);
    });

    testWidgets('[$code] See all opens Find riders; Back returns to Today', (tester) async {
      await pumpRequests(tester, at(rideTuesday, 20, 0));
      await tapIt(tester, find.byKey(const Key('requests-see-all')));
      expect(find.byType(FindRidersScreen), findsOneWidget);
      await tester.tap(find.byTooltip(l.back));
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('[$code] no matching requests: a calm message and the privacy caption, not a placeholder', (tester) async {
      await pumpRequests(
        tester,
        at(rideTuesday, 20, 0),
        overrides: [requestCardsProvider(null, PartOfDay.morning).overrideWith((ref) async => const [])],
      );
      expect(find.byKey(const Key('requests-empty')), findsOneWidget);
      expect(find.text(l.noRequests), findsOneWidget);
      expect(find.text(l.privacyCaption), findsOneWidget);
      expect(find.text(l.reqsPlaceholder), findsNothing);
    });
  }
}
