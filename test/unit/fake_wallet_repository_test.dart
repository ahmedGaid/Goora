import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart' show Leg;
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/charge.dart';
import 'package:goora/features/daily/domain/daily_commute_repository.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/trust.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/domain/cash_mark.dart';
import 'package:goora/features/wallet/domain/cash_trial_policy.dart';
import 'package:goora/features/wallet/domain/done_one_off.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/payment_provider.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:goora/features/wallet/domain/wallet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thu 22 Oct 2026 — far enough in that 12 trips fit inside October.
final today = CalendarDate(2026, 10, 22);
final sz0725 = CorridorSeed.groups.first; // sz-0725, 40 EGP

String rideId(CalendarDate d, Leg leg) => Ride.idFor(sz0725.id, d, leg);

/// [n] completed rider trips on consecutive days from 1 Oct, going leg only
/// (one trip a day keeps the arithmetic obvious).
List<String> trips(int n) => [for (var i = 0; i < n; i++) rideId(CalendarDate(2026, 10, 1).addDays(i), Leg.going)];

/// Stand-in for 003's repository: the rider's settled trips (`events`), the
/// rides behind them, charges and absences (research R3, R7).
final class _StubDailyRepo implements DailyCommuteRepository {
  _StubDailyRepo({
    this.kept = const [],
    this.charges = const [],
    this.absences_ = const [],
    this.drivenByMe = const {},
    this.noGroup = false,
  });

  final List<String> kept;
  final List<Charge> charges;
  final List<Absence> absences_;
  final Set<String> drivenByMe;

  /// A once user (005): no group, only one-off trips.
  final bool noGroup;

  @override
  String get meId => 'me';

  @override
  Future<CommuteGroup?> myGroup() async => noGroup ? null : sz0725;

  @override
  Future<List<ReliabilityEvent>> events(CalendarDate from, CalendarDate to) async => [
        for (final id in kept)
          ReliabilityEvent(personId: 'me', rideId: id, date: Ride.parseId(id)!.$1, kind: ReliabilityEventKind.kept),
      ];

  @override
  Future<Ride?> ride(CalendarDate date, Leg leg) async {
    final id = Ride.idFor(sz0725.id, date, leg);
    return Ride(
      groupId: sz0725.id,
      date: date,
      leg: leg,
      driverId: drivenByMe.contains(id) ? 'me' : 'ahmed',
      passengers: const [],
      stops: const [],
    );
  }

  @override
  Future<List<Charge>> chargesOwed() async => charges;

  @override
  Future<List<Absence>> absences(CalendarDate from, CalendarDate to) async => absences_;

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName} not stubbed');
}

final class _Provider implements PaymentProvider {
  const _Provider({this.fail = false});

  final bool fail;

  @override
  Future<PaymentResult> topUp({required String method, required int amount}) async =>
      fail ? PaymentResult.failure : PaymentResult.success;

  @override
  Future<PaymentResult> withdraw({required int amount}) async => fail ? PaymentResult.failure : PaymentResult.success;

  @override
  Future<PaymentResult> debit({required int amount}) async => fail ? PaymentResult.failure : PaymentResult.success;
}

/// Payment set up on 1 Oct, so every seeded October trip is billable.
Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({FakeWalletRepository.sinceKey('me'): '2026-10-01'});
  return SharedPreferences.getInstance();
}

FakeWalletRepository _repo(
  SharedPreferences prefs, {
  DailyCommuteRepository? daily,
  bool fail = false,
  MemberRole role = MemberRole.rider,
  List<DoneOneOff> oneOffs = const [],
}) =>
    FakeWalletRepository(
      prefs,
      daily: daily ?? _StubDailyRepo(),
      role: () => role,
      now: () => WallTime(today, const Clock.hm(9, 0)),
      provider: _Provider(fail: fail),
      oneOffs: () async => oneOffs,
    );

/// A finished one-off seat at the demo basis (40 of 160/3).
DoneOneOff _oneOff(
  String rideId,
  CalendarDate date, {
  Leg leg = Leg.going,
  PaidBy paidBy = PaidBy.cash,
  String riderId = 'me',
  String driverId = 'ahmed',
}) =>
    DoneOneOff(
      rideId: rideId,
      date: date,
      leg: leg,
      paidBy: paidBy,
      contribution: 40,
      tripCost: 160,
      riderSeats: 3,
      riderId: riderId,
      driverId: driverId,
    );

/// Wallet top-up 200, then a 44 seat (40 + 4 fee) paid at booking.
Future<void> _bookSeat(FakeWalletRepository repo, String rideId, {String bookingId = 'bk-1'}) async {
  await repo.topUp('me', method: 'instapay', amount: 200);
  await repo.debitSeat('me', bookingId: bookingId, rideId: rideId, total: 44, fee: 4, date: Ride.parseId(rideId)?.$1 ?? today);
}

Charge _lateCancel(String rideId) =>
    Charge(id: 'lc-$rideId', personId: 'me', rideId: rideId, reason: ChargeReason.lateCancel, amount: 20, owedTo: 'ahmed');

CashMark _mark(String rideId, CashOutcome outcome) => CashMark(
      rideId: rideId,
      riderId: 'me',
      driverId: 'ahmed',
      outcome: outcome,
      amount: 40,
      date: Ride.parseId(rideId)!.$1,
    );

void main() {
  group('wallet rider — 10% service fee per completed trip (brief §6.7 A)', () {
    test('top-up 200 gives exactly 200 (no fee at top-up)', () async {
      final repo = _repo(await _prefs());
      await repo.setMethod('me', PaymentMethod.wallet);
      await repo.topUp('me', method: 'instapay', amount: 200);
      expect((await repo.getWallet('me')).balance, 200);
    });

    test('a 40 EGP trip takes 44 from the wallet: 40 to the driver, 4 fee, one row', () async {
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: trips(2)));
      await repo.setMethod('me', PaymentMethod.wallet);
      await repo.topUp('me', method: 'instapay', amount: 200);
      final w = await repo.getWallet('me');
      expect(w.balance, 200 - 2 * 44);
      final trip = w.activity.firstWhere((e) => e.kind == ActivityKind.trip);
      expect(trip.amount, 44);
      expect(trip.fee, 4);
      expect(trip.toDriver, 40);
      expect(w.feesThisMonth, 8);
    });

    test('a trip the person drove is not a rider trip', () async {
      final kept = trips(2);
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: kept, drivenByMe: {kept.first}));
      await repo.setMethod('me', PaymentMethod.wallet);
      expect((await repo.getWallet('me')).activity.where((e) => e.kind == ActivityKind.trip), hasLength(1));
    });

    test('a late-cancel charge goes to the driver with no service fee', () async {
      final kept = trips(1);
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(charges: [_lateCancel(kept.first)]));
      await repo.setMethod('me', PaymentMethod.wallet);
      final w = await repo.getWallet('me');
      expect(w.balance, -20);
      final row = w.activity.single;
      expect(row.kind, ActivityKind.lateCancelCharge);
      expect(row.amount, 20);
      expect(row.fee, 0);
    });

    test("free cancellations stay zero-amount rows (v1 FR-007)", () async {
      final repo = _repo(
        await _prefs(),
        daily: _StubDailyRepo(absences_: [
          Absence(
            personId: 'me',
            date: today.addDays(-1),
            leg: Leg.going,
            madeAt: WallTime(today.addDays(-2), const Clock.hm(18, 0)),
            kind: AbsenceKind.freeCancel,
          ),
        ]),
      );
      final row = (await repo.getWallet('me')).activity.single;
      expect(row.kind, ActivityKind.freeCancelZero);
      expect(row.amount, 0);
    });

    test('top-up/withdraw failure changes neither balance nor activity', () async {
      final repo = _repo(await _prefs(), fail: true);
      expect(await repo.topUp('me', method: 'instapay', amount: 200), PaymentResult.failure);
      final w = await repo.getWallet('me');
      expect(w.balance, 0);
      expect(w.activity, isEmpty);
    });
  });

  test("trips before payment was set up are not billed (003's seeded history)", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _repo(prefs, daily: _StubDailyRepo(kept: trips(5)));
    expect((await repo.getWallet('me')).activity, isEmpty, reason: 'no method, no plan: nothing billed');
    await repo.setMethod('me', PaymentMethod.wallet);
    expect((await repo.getWallet('me')).balance, 0, reason: 'the 5 trips predate today, the setup day');
  });

  group('cash trial (brief §6.7 C)', () {
    test('3 cash trips: no wallet movement, no fee, 7 left', () async {
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: trips(3)));
      await repo.setMethod('me', PaymentMethod.cash);
      final w = await repo.getWallet('me');
      expect(w.balance, 0);
      expect(w.activity.where((e) => e.kind == ActivityKind.cashTrip), hasLength(3));
      expect(w.feesThisMonth, 0);
      expect(w.cashTrial!.tripsLeft, 7);
      expect(w.cashTrial!.showTopUpBanner, isFalse);
    });

    test('after 7 cash trips the top-up banner shows', () async {
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: trips(7)));
      await repo.setMethod('me', PaymentMethod.cash);
      expect((await repo.getWallet('me')).cashTrial!.showTopUpBanner, isTrue);
    });

    test('the 11th trip is a wallet trip at 44; cash ended by trips used', () async {
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: trips(11)));
      await repo.setMethod('me', PaymentMethod.cash);
      final w = await repo.getWallet('me');
      expect(w.activity.where((e) => e.kind == ActivityKind.cashTrip), hasLength(10));
      expect(w.activity.where((e) => e.kind == ActivityKind.trip).single.amount, 44);
      expect(w.balance, -44);
      expect(w.cashTrial!.endedBy, CashTrialEnd.tripsUsed);
    });

    test('2 "didn\'t pay" marks turn cash off at once', () async {
      final kept = trips(4);
      final prefs = await _prefs();
      final repo = _repo(prefs, daily: _StubDailyRepo(kept: kept));
      await repo.setMethod('me', PaymentMethod.cash);
      await repo.markCash(_mark(kept[0], CashOutcome.didNotPay));
      await repo.markCash(_mark(kept[1], CashOutcome.didNotPay));
      final w = await repo.getWallet('me');
      expect(w.activity.where((e) => e.kind == ActivityKind.cashTrip), hasLength(2));
      expect(w.activity.where((e) => e.kind == ActivityKind.trip), hasLength(2));
      expect(w.cashTrial!.endedBy, CashTrialEnd.strikes);
    });

    test('a late cancel during the cash trial is not collected (reliability only)', () async {
      final kept = trips(2);
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: kept, charges: [_lateCancel(kept.last)]));
      await repo.setMethod('me', PaymentMethod.cash);
      final w = await repo.getWallet('me');
      final charge = w.activity.firstWhere((e) => e.kind == ActivityKind.lateCancelCharge);
      expect(charge.amount, 0);
      expect(charge.notCollected, isTrue);
      expect(w.balance, 0);
    });
  });

  group('subscription (brief §6.7 B, research R10)', () {
    test('Monthly with 200 in the wallet: 129 leaves, plan active one month', () async {
      final repo = _repo(await _prefs());
      await repo.topUp('me', method: 'instapay', amount: 200);
      expect(await repo.subscribe('me', PlanType.monthly, today: today), SubscribeResult.subscribed);
      final plan = (await repo.getPlan('me'))!;
      expect(plan.status, PlanStatus.active);
      expect(plan.startDate, WallTime(today, const Clock.hm(9, 0)));
      expect(plan.untilDate, today.addMonths(1));
      final w = await repo.getWallet('me');
      expect(w.balance, 71);
      expect(w.activity.first.kind, ActivityKind.subscription);
    });

    test('Yearly is 1,290 for 12 months', () async {
      final repo = _repo(await _prefs());
      await repo.topUp('me', method: 'instapay', amount: 1500);
      await repo.subscribe('me', PlanType.yearly, today: today);
      expect((await repo.getPlan('me'))!.untilDate, today.addMonths(12));
      expect((await repo.getWallet('me')).balance, 210);
    });

    test('not enough balance: nothing charged, no plan', () async {
      final repo = _repo(await _prefs());
      await repo.topUp('me', method: 'instapay', amount: 100);
      expect(await repo.subscribe('me', PlanType.monthly, today: today), SubscribeResult.needsTopUp);
      expect(await repo.getPlan('me'), isNull);
      expect((await repo.getWallet('me')).balance, 100);
    });

    test('company: no charge, fee-free trips', () async {
      // The return leg (5 PM) settles after _repo's now() (9 AM today).
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: [rideId(today, Leg.ret)]));
      await repo.setMethod('me', PaymentMethod.wallet);
      await repo.subscribe('me', PlanType.company, today: today);
      final w = await repo.getWallet('me');
      expect(w.activity.single.amount, 40);
      expect(w.activity.single.fee, 0);
    });

    test('trips before the subscription keep their fee; trips after cost 40', () async {
      final before = rideId(today.addDays(-1), Leg.going);
      // The return leg (5 PM) settles after _repo's now() (9 AM today).
      final after = rideId(today, Leg.ret);
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: [before, after]));
      await repo.setMethod('me', PaymentMethod.wallet);
      await repo.topUp('me', method: 'instapay', amount: 400);
      await repo.subscribe('me', PlanType.monthly, today: today);
      final rows = {for (final e in (await repo.getWallet('me')).activity) e.rideId: e};
      expect(rows[before]!.amount, 44);
      expect(rows[after]!.amount, 40);
    });

    test(
        'research R14: a trip that settled earlier the SAME DAY the rider subscribes keeps its '
        'fee — only a trip after the exact subscribe moment is fee-free', () async {
      // _repo's now() is 9:00 AM `today`. The going leg (7:25 AM) settles before that;
      // the return leg (5:00 PM) settles after it.
      final earlierToday = rideId(today, Leg.going);
      final laterToday = rideId(today, Leg.ret);
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: [earlierToday, laterToday]));
      await repo.setMethod('me', PaymentMethod.wallet);
      await repo.topUp('me', method: 'instapay', amount: 400);
      await repo.subscribe('me', PlanType.monthly, today: today);
      final rows = {for (final e in (await repo.getWallet('me')).activity) e.rideId: e};
      expect(rows[earlierToday]!.amount, 44, reason: 'settled before subscribing, even same-day — keeps its fee');
      expect(rows[earlierToday]!.fee, 4);
      expect(rows[laterToday]!.amount, 40, reason: 'settled after subscribing — fee-free');
      expect(rows[laterToday]!.fee, 0);
    });

    test("changePlan doesn't affect the current period", () async {
      final repo = _repo(await _prefs());
      await repo.topUp('me', method: 'instapay', amount: 200);
      await repo.subscribe('me', PlanType.monthly, today: today);
      final changed = await repo.changePlan('me', PlanType.yearly);
      expect(changed.untilDate, today.addMonths(1));
      expect(changed.startDate, WallTime(today, const Clock.hm(9, 0)));
    });
  });

  group('driver cash (brief §6.7 C, research R11)', () {
    test('Youssef is seeded as a cash rider, Sara as wallet', () async {
      final repo = _repo(await _prefs());
      expect(await repo.methodOf('youssef'), PaymentMethod.cash);
      expect(await repo.methodOf('sara'), PaymentMethod.wallet);
    });

    test('the first mark for a (ride, rider) stands', () async {
      final repo = _repo(await _prefs());
      final id = rideId(today, Leg.going);
      await repo.markCash(_mark(id, CashOutcome.received));
      await repo.markCash(_mark(id, CashOutcome.didNotPay));
      expect((await repo.cashMarks(id)).single.outcome, CashOutcome.received);
    });

    test('cash received is shown apart and never withdrawn', () async {
      final repo = _repo(await _prefs(), role: MemberRole.driver);
      final seeded = await repo.getWallet('ahmed');
      expect(seeded.cashReceived, 40, reason: 'seeded: Youssef paid 40 cash yesterday');
      await repo.markCash(CashMark(
        rideId: 'r2',
        riderId: 'youssef',
        driverId: 'ahmed',
        outcome: CashOutcome.received,
        amount: 40,
        date: today,
      ));
      await repo.withdraw('ahmed', amount: seeded.balance);
      final w = await repo.getWallet('ahmed');
      expect(w.balance, 0);
      expect(w.cashReceived, 80);
    });
  });

  group('seat ledger (005 T037, SC-005, SC-006)', () {
    test('a 44 seat debit takes 44 (fee 4 recorded) in one row', () async {
      final repo = _repo(await _prefs());
      await _bookSeat(repo, 'offer:t1');
      final w = await repo.getWallet('me');
      expect(w.balance, 156);
      final row = w.activity.singleWhere((e) => e.kind == ActivityKind.seatBooked);
      expect(row.amount, 44);
      expect(row.fee, 4);
      expect(row.toDriver, 40);
      expect(row.rideId, 'offer:t1');
    });

    test('a full refund puts the balance back: one row each way', () async {
      final repo = _repo(await _prefs());
      await _bookSeat(repo, 'offer:t1');
      await repo.refundSeat('me', bookingId: 'bk-1', rideId: 'offer:t1', amount: 44, date: today);
      final w = await repo.getWallet('me');
      expect(w.balance, 200);
      expect(w.activity.where((e) => e.kind == ActivityKind.seatBooked), hasLength(1));
      expect(w.activity.singleWhere((e) => e.kind == ActivityKind.seatRefund).amount, 44);
    });

    test('a refund of 0 writes no row', () async {
      final repo = _repo(await _prefs());
      await _bookSeat(repo, 'offer:t1');
      await repo.refundSeat('me', bookingId: 'bk-1', rideId: 'offer:t1', amount: 0, date: today);
      expect((await repo.getWallet('me')).activity.where((e) => e.kind == ActivityKind.seatRefund), isEmpty);
    });

    test('a payment failure leaves balance and activity untouched', () async {
      final repo = _repo(await _prefs(), fail: true);
      final result = await repo.debitSeat('me', bookingId: 'bk-1', rideId: 'offer:t1', total: 44, fee: 4, date: today);
      expect(result, PaymentResult.failure);
      final w = await repo.getWallet('me');
      expect(w.balance, 0);
      expect(w.activity, isEmpty);
    });

    test('one debit and at most one credit per booking, however often called', () async {
      final repo = _repo(await _prefs());
      await _bookSeat(repo, 'offer:t1');
      await repo.debitSeat('me', bookingId: 'bk-1', rideId: 'offer:t1', total: 44, fee: 4, date: today);
      await repo.refundSeat('me', bookingId: 'bk-1', rideId: 'offer:t1', amount: 44, date: today);
      await repo.refundSeat('me', bookingId: 'bk-1', rideId: 'offer:t1', amount: 44, date: today);
      final w = await repo.getWallet('me');
      expect(w.balance, 200);
      expect(w.activity.where((e) => e.kind == ActivityKind.seatBooked), hasLength(1));
      expect(w.activity.where((e) => e.kind == ActivityKind.seatRefund), hasLength(1));
    });
  });

  group('one-off trips into the wallet (005 T038, research R9, R10)', () {
    test('one ride, one charge: a seat paid at booking + the kept group trip on that ride = 44 once', () async {
      final ride = trips(1).single;
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: [ride]));
      await repo.setMethod('me', PaymentMethod.wallet);
      await _bookSeat(repo, ride);
      final w = await repo.getWallet('me');
      expect(w.balance, 200 - 44);
      expect(w.activity.where((e) => e.kind == ActivityKind.trip), isEmpty);
    });

    test("a 003 charge on a ride paid at booking isn't billed again", () async {
      final ride = trips(1).single;
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(charges: [_lateCancel(ride)]));
      await repo.setMethod('me', PaymentMethod.wallet);
      await _bookSeat(repo, ride);
      expect((await repo.getWallet('me')).balance, 200 - 44);
    });

    test('a cash one-off on a group ride is one cash trip, not two', () async {
      final ride = trips(1).single;
      final repo = _repo(
        await _prefs(),
        daily: _StubDailyRepo(kept: [ride]),
        oneOffs: [_oneOff(ride, Ride.parseId(ride)!.$1)],
      );
      // The method moved to wallet since: the ride was still booked as cash.
      await repo.setMethod('me', PaymentMethod.wallet);
      final w = await repo.getWallet('me');
      expect(w.activity.where((e) => e.kind == ActivityKind.cashTrip).single.rideId, ride);
      expect(w.activity.where((e) => e.kind == ActivityKind.trip), isEmpty);
      expect(w.balance, 0);
    });

    test('cash one-offs count toward the 10, in date then leg order with group trips', () async {
      final kept = trips(10); // 1–10 Oct, going
      final repo = _repo(
        await _prefs(),
        daily: _StubDailyRepo(kept: kept),
        oneOffs: [_oneOff('offer:t1', CalendarDate(2026, 10, 1), leg: Leg.ret)],
      );
      await repo.setMethod('me', PaymentMethod.cash);
      final w = await repo.getWallet('me');
      expect(w.activity.where((e) => e.kind == ActivityKind.cashTrip).map((e) => e.rideId), contains('offer:t1'));
      expect(w.activity.where((e) => e.kind == ActivityKind.trip).single.rideId, kept.last,
          reason: "1 Oct return is the 2nd trip, so 10 Oct is the 11th: the trial's over");
      expect(w.balance, -44);
      expect(w.cashTrial!.endedBy, CashTrialEnd.tripsUsed);
    });

    test('after 7 trips mixing group and one-off cash, the top-up banner shows', () async {
      final repo = _repo(
        await _prefs(),
        daily: _StubDailyRepo(kept: trips(5)),
        oneOffs: [
          _oneOff('offer:t1', CalendarDate(2026, 10, 10)),
          _oneOff('offer:t2', CalendarDate(2026, 10, 11)),
        ],
      );
      await repo.setMethod('me', PaymentMethod.cash);
      final trial = (await repo.getWallet('me')).cashTrial!;
      expect(trial.tripsDone, 7);
      expect(trial.showTopUpBanner, isTrue);
    });

    test('"didn\'t pay" on two one-off trips ends cash; the next one is a wallet trip at its basis', () async {
      final repo = _repo(
        await _prefs(),
        daily: _StubDailyRepo(noGroup: true),
        oneOffs: [
          _oneOff('offer:a', CalendarDate(2026, 10, 1)),
          _oneOff('offer:b', CalendarDate(2026, 10, 2)),
          _oneOff('offer:c', CalendarDate(2026, 10, 3)),
        ],
      );
      await repo.setMethod('me', PaymentMethod.cash);
      for (final (id, day) in [('offer:a', 1), ('offer:b', 2)]) {
        await repo.markCash(CashMark(
          rideId: id,
          riderId: 'me',
          driverId: 'ahmed',
          outcome: CashOutcome.didNotPay,
          amount: 40,
          date: CalendarDate(2026, 10, day),
        ));
      }
      final w = await repo.getWallet('me');
      expect(w.cashTrial!.endedBy, CashTrialEnd.strikes);
      final trip = w.activity.singleWhere((e) => e.kind == ActivityKind.trip);
      expect(trip.rideId, 'offer:c');
      expect(trip.amount, 44);
      expect(trip.fee, 4);
    });

    test('a once user with no group still gets their cash trips counted', () async {
      final repo = _repo(
        await _prefs(),
        daily: _StubDailyRepo(noGroup: true),
        oneOffs: [_oneOff('offer:t1', CalendarDate(2026, 10, 5))],
      );
      await repo.setMethod('me', PaymentMethod.cash);
      expect((await repo.getWallet('me')).cashTrial!.tripsDone, 1);
    });

    test("wallet and plan one-offs, and other riders' ones, are not billed by the fold", () async {
      final repo = _repo(
        await _prefs(),
        daily: _StubDailyRepo(noGroup: true),
        oneOffs: [
          _oneOff('offer:t1', CalendarDate(2026, 10, 5), paidBy: PaidBy.wallet),
          _oneOff('offer:t2', CalendarDate(2026, 10, 6), paidBy: PaidBy.plan),
          _oneOff('offer:t3', CalendarDate(2026, 10, 7), riderId: 'sara'),
        ],
      );
      await repo.setMethod('me', PaymentMethod.cash);
      final w = await repo.getWallet('me');
      expect(w.activity, isEmpty);
      expect(w.balance, 0);
      expect(w.cashTrial!.tripsDone, 0);
    });

    test('driver: one trip income per non-cash rider, written once', () async {
      final prefs = await _prefs();
      final oneOffs = [
        _oneOff('offer:t1', today, paidBy: PaidBy.wallet, riderId: 'sara'),
        _oneOff('offer:t1', today, paidBy: PaidBy.plan, riderId: 'mona'),
        _oneOff('offer:t1', today, riderId: 'youssef'), // cash: paid in the car
        _oneOff('offer:t9', today, paidBy: PaidBy.wallet, riderId: 'sara', driverId: 'karim'),
      ];
      final seeded = await _repo(prefs, role: MemberRole.driver).getWallet('ahmed');
      final repo = _repo(prefs, role: MemberRole.driver, oneOffs: oneOffs);
      await repo.getWallet('ahmed');
      final w = await repo.getWallet('ahmed');
      final income = w.activity.where((e) => e.id.startsWith('income:')).toList();
      expect(income.map((e) => e.otherPersonId), unorderedEquals(['sara', 'mona']));
      expect(income.every((e) => e.kind == ActivityKind.tripIncome && e.amount == 40), isTrue);
      expect(w.balance, seeded.balance + 80);
    });
  });
}
