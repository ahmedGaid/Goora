import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart' show Leg;
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/charge.dart';
import 'package:goora/features/daily/domain/check_in.dart';
import 'package:goora/features/daily/domain/daily_commute_repository.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/trust.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/domain/cash_mark.dart';
import 'package:goora/features/wallet/domain/cash_trial_policy.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';
import 'package:goora/features/wallet/domain/done_one_off.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/payment_provider.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:goora/features/wallet/domain/wallet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thu 22 Oct 2026 — far enough in that 12 trips fit inside October.
final today = CalendarDate(2026, 10, 22);
final sz0725 = CorridorSeed.groups.first; // sz-0725, 40 EGP
final now = WallTime(today, const Clock.hm(9, 0));

String rideId(CalendarDate d, Leg leg) => Ride.idFor(sz0725.id, d, leg);

/// [n] completed rider trips on consecutive days from 1 Oct, going leg only
/// (one trip a day keeps the arithmetic obvious).
List<String> trips(int n) => [for (var i = 0; i < n; i++) rideId(CalendarDate(2026, 10, 1).addDays(i), Leg.going)];

/// [n] going trips ending on the [n] days before today — inside the 7-day
/// window where a driver may still turn an auto-received share around.
List<String> recentTrips(int n) => [for (var i = n; i >= 1; i--) rideId(today.addDays(-i), Leg.going)];

/// Stand-in for 003's repository: the rider's settled trips (`events`), the
/// rides behind them, charges and absences (research R3, R7).
final class _StubDailyRepo implements DailyCommuteRepository {
  _StubDailyRepo({
    this.kept = const [],
    this.charges = const [],
    this.absences_ = const [],
    this.drivenByMe = const {},
    this.boarded = const [],
    this.noGroup = false,
  });

  final List<String> kept;
  final List<Charge> charges;
  final List<Absence> absences_;
  final Set<String> drivenByMe;

  /// Who was picked up on each ride the person drove.
  final List<String> boarded;

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
    final mine = drivenByMe.contains(id);
    return Ride(
      groupId: sz0725.id,
      date: date,
      leg: leg,
      driverId: mine ? 'me' : 'ahmed',
      passengers: const [],
      stops: const [],
      endedAt: mine ? WallTime(date, sz0725.endFor(leg)) : null,
    );
  }

  @override
  Future<List<PassengerOutcome>> outcomes(String rideId) async => [
        for (final p in boarded)
          PassengerOutcome(rideId: rideId, personId: p, outcome: Outcome.pickedUp, markedAt: now),
      ];

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
  WallTime? at,
}) =>
    FakeWalletRepository(
      prefs,
      daily: daily ?? _StubDailyRepo(),
      role: () => role,
      now: () => at ?? now,
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
      riderName: riderId,
      driverName: 'Ahmed',
    );

/// Wallet top-up 200, then a seat whose 4 EGP fee is taken at booking (007
/// research R5); the 40 goes to the driver directly.
Future<void> _bookSeat(FakeWalletRepository repo, String rideId, {String bookingId = 'bk-1'}) async {
  await repo.topUp('me', method: 'instapay', amount: 200);
  await repo.debitSeat('me',
      bookingId: bookingId, rideId: rideId, fee: 4, share: 40, date: Ride.parseId(rideId)?.$1 ?? today);
}

Charge _lateCancel(String rideId) =>
    Charge(id: 'lc-$rideId', personId: 'me', rideId: rideId, reason: ChargeReason.lateCancel, amount: 20, owedTo: 'ahmed');

CashMark _mark(String rideId, CashOutcome outcome, {String riderId = 'me', CalendarDate? date}) => CashMark(
      rideId: rideId,
      riderId: riderId,
      driverId: 'ahmed',
      outcome: outcome,
      amount: 40,
      date: date ?? Ride.parseId(rideId)!.$1,
    );

void main() {
  group('the share goes to the driver directly; Goora takes only its fee (007 US1)', () {
    test('top-up 200 gives exactly 200 (no fee at top-up)', () async {
      final repo = _repo(await _prefs());
      await repo.setMethod('me', PaymentMethod.instapay);
      await repo.topUp('me', method: 'instapay', amount: 200);
      expect((await repo.getWallet('me')).balance, 200);
    });

    test('after the trial a 40 EGP trip takes only the 4 fee; the 40 never moves (SC-001)', () async {
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: trips(7)));
      await repo.setMethod('me', PaymentMethod.instapay);
      await repo.topUp('me', method: 'instapay', amount: 200);
      final w = await repo.getWallet('me');
      expect(w.balance, 200 - 2 * 4);
      final trip = w.activity.firstWhere((e) => e.kind == ActivityKind.trip);
      expect(trip.amount, 4);
      expect(trip.fee, 4);
      expect(trip.toDriver, 40);
      expect(w.feesThisMonth, 8);
    });

    test('a subscriber pays 0 per trip and the share is still direct', () async {
      final kept = [...trips(5), rideId(today, Leg.ret)];
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: kept));
      await repo.setMethod('me', PaymentMethod.cash);
      await repo.subscribe('me', PlanType.company, today: today);
      final row = (await repo.getWallet('me')).activity.firstWhere((e) => e.rideId == kept.last);
      expect([row.kind, row.amount, row.fee, row.toDriver], [ActivityKind.trip, 0, 0, 40]);
    });

    test('a trip the person drove is not a rider trip', () async {
      final kept = trips(2);
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: kept, drivenByMe: {kept.first}));
      await repo.setMethod('me', PaymentMethod.cash);
      expect((await repo.getWallet('me')).activity.where((e) => e.kind == ActivityKind.cashTrip), hasLength(1));
    });

    test('a late-cancel charge is the driver\'s, paid directly, with no fee and no wallet movement', () async {
      final kept = trips(1);
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(charges: [_lateCancel(kept.first)]));
      await repo.setMethod('me', PaymentMethod.cash);
      final w = await repo.getWallet('me');
      expect(w.balance, 0);
      final row = w.activity.single;
      expect([row.kind, row.amount, row.fee, row.toDriver], [ActivityKind.lateCancelCharge, 0, 0, 20]);
    });

    test('free cancellations stay zero-amount rows (v1 FR-007)', () async {
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

    test('a legacy "wallet" method reads as cash (007 R6)', () async {
      final prefs = await _prefs();
      await prefs.setString(FakeWalletRepository.methodKey('me'), 'wallet');
      expect(await _repo(prefs).getMethod('me'), PaymentMethod.cash);
    });
  });

  test("trips before payment was set up are not billed (003's seeded history)", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _repo(prefs, daily: _StubDailyRepo(kept: trips(8)));
    expect((await repo.getWallet('me')).activity, isEmpty, reason: 'no method, no plan: nothing billed');
    await repo.setMethod('me', PaymentMethod.cash);
    expect((await repo.getWallet('me')).balance, 0, reason: 'the 8 trips predate today, the setup day');
  });

  group('fee-free trial for every rider (brief §6.7 C, 007 R6)', () {
    test('2 trial trips: no wallet movement, no fee, 3 left', () async {
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: trips(2)));
      await repo.setMethod('me', PaymentMethod.cash);
      final w = await repo.getWallet('me');
      expect(w.balance, 0);
      expect(w.activity.where((e) => e.kind == ActivityKind.cashTrip), hasLength(2));
      expect(w.feesThisMonth, 0);
      expect(w.cashTrial!.tripsLeft, 3);
      expect(w.cashTrial!.showTopUpBanner, isFalse);
    });

    test('InstaPay riders get the same trial', () async {
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: trips(2)));
      await repo.setMethod('me', PaymentMethod.instapay);
      final w = await repo.getWallet('me');
      expect(w.activity.where((e) => e.kind == ActivityKind.cashTrip), hasLength(2));
      expect(w.cashTrial!.tripsLeft, 3);
    });

    test('after 3 trial trips the banner shows', () async {
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: trips(3)));
      await repo.setMethod('me', PaymentMethod.cash);
      expect((await repo.getWallet('me')).cashTrial!.showTopUpBanner, isTrue);
    });

    test('the 6th trip carries the 4 fee; the trial ended by trips used', () async {
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: trips(6)));
      await repo.setMethod('me', PaymentMethod.cash);
      final w = await repo.getWallet('me');
      expect(w.activity.where((e) => e.kind == ActivityKind.cashTrip), hasLength(5));
      expect(w.activity.where((e) => e.kind == ActivityKind.trip).single.amount, 4);
      expect(w.balance, -4, reason: 'a fee owed to Goora (007 FR-009), never the 40');
      expect(w.cashTrial!.endedBy, CashTrialEnd.tripsUsed);
    });

    test('2 "didn\'t get it" marks end the trial at once', () async {
      final kept = recentTrips(4);
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: kept));
      await repo.setMethod('me', PaymentMethod.cash);
      await repo.markShare(_mark(kept[0], CashOutcome.didNotPay));
      await repo.markShare(_mark(kept[1], CashOutcome.didNotPay));
      final w = await repo.getWallet('me');
      expect(w.activity.where((e) => e.kind == ActivityKind.cashTrip), hasLength(2));
      expect(w.activity.where((e) => e.kind == ActivityKind.trip), hasLength(2));
      expect(w.cashTrial!.endedBy, CashTrialEnd.strikes);
    });
  });

  group('the driver confirms receipt (007 US2, research R2)', () {
    test('Youssef is seeded as paying cash, Sara by InstaPay', () async {
      final repo = _repo(await _prefs());
      expect(await repo.methodOf('youssef'), PaymentMethod.cash);
      expect(await repo.methodOf('sara'), PaymentMethod.instapay);
    });

    test('within 24 hours a later mark replaces the earlier one', () async {
      final id = rideId(today, Leg.going); // ended 8:05, now 9:00
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: [id]));
      await repo.markShare(_mark(id, CashOutcome.received));
      await repo.markShare(_mark(id, CashOutcome.didNotPay));
      expect((await repo.shareMarks(id)).single.outcome, CashOutcome.didNotPay);
    });

    test('no answer for 24 hours: received automatically', () async {
      final id = rideId(today.addDays(-2), Leg.going);
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: [id]));
      await repo.setMethod('me', PaymentMethod.cash);
      expect(await repo.openShares('me'), isEmpty, reason: 'auto-received is not open');
      final fresh = _repo(await _prefs(), daily: _StubDailyRepo(kept: [rideId(today, Leg.going)]));
      await fresh.setMethod('me', PaymentMethod.cash);
      expect((await fresh.openShares('me')).single.status, ShareStatus.pending);
    });

    test('a mark before the trip ends is ignored', () async {
      final id = rideId(today, Leg.ret); // ends late afternoon, now 9:00
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: [id]));
      await repo.markShare(_mark(id, CashOutcome.didNotPay));
      expect(await repo.shareMarks(id), isEmpty);
    });

    test('after 24 hours a "received" answer is frozen', () async {
      final id = rideId(today.addDays(-3), Leg.going);
      final prefs = await _prefs();
      final early = _repo(prefs, daily: _StubDailyRepo(kept: [id]), at: WallTime(today.addDays(-3), const Clock.hm(9, 0)));
      await early.markShare(_mark(id, CashOutcome.received));
      final repo = _repo(prefs, daily: _StubDailyRepo(kept: [id]));
      await repo.markShare(_mark(id, CashOutcome.didNotPay));
      expect((await repo.shareMarks(id)).single.outcome, CashOutcome.received);
    });

    test('drivers keep no Goora balance: shares received show apart, this month only', () async {
      final repo = _repo(await _prefs(), role: MemberRole.driver);
      final seeded = await repo.getWallet('ahmed');
      expect(seeded.balance, 0, reason: 'Goora moves no driver money (007 R8)');
      expect(seeded.activity, isEmpty);
      expect(seeded.cashReceived, 40, reason: 'seeded: Youssef paid 40 cash yesterday');
      expect(seeded.shares.single.status, ShareStatus.received);
    });

    test("a driver's own ride lists every boarded passenger's share", () async {
      final id = rideId(today, Leg.going);
      final daily = _StubDailyRepo(drivenByMe: {id}, boarded: ['youssef', 'sara']);
      final repo = _repo(await _prefs(), role: MemberRole.driver, daily: daily);
      final shares = await repo.driverShares('me');
      expect(shares.map((s) => (s.riderId, s.amount, s.method, s.status)), [
        ('youssef', 40, PaymentMethod.cash, ShareStatus.pending),
        ('sara', 40, PaymentMethod.instapay, ShareStatus.pending),
      ]);
      await repo.markShare(CashMark(
          rideId: id, riderId: 'sara', driverId: 'me', outcome: CashOutcome.received, amount: 40, date: today));
      expect((await repo.driverShareOn(id, 'sara'))!.status, ShareStatus.received);
    });
  });

  group('an unpaid share blocks the rider (007 US3)', () {
    test('"didn\'t get it" is an open debt to the named driver', () async {
      final id = rideId(today, Leg.going);
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: [id]));
      await repo.setMethod('me', PaymentMethod.cash);
      await repo.markShare(_mark(id, CashOutcome.didNotPay));
      final debt = (await repo.openShares('me')).single;
      expect([debt.status, debt.amount, debt.otherFirstName], [ShareStatus.notReceived, 40, 'Ahmed']);
    });

    test('"دفعت" makes it disputed; the driver\'s "received" clears it', () async {
      final id = rideId(today, Leg.going);
      final prefs = await _prefs();
      final repo = _repo(prefs, daily: _StubDailyRepo(kept: [id]));
      await repo.setMethod('me', PaymentMethod.cash);
      await repo.markShare(_mark(id, CashOutcome.didNotPay));
      final later = _repo(prefs, daily: _StubDailyRepo(kept: [id]), at: now.plusMinutes(5));
      await later.claimPaid(id, 'me');
      expect((await later.openShares('me')).single.status, ShareStatus.disputed);
      // Days later, past every window: clearing a debt is always allowed.
      final days = _repo(prefs, daily: _StubDailyRepo(kept: [id]), at: WallTime(today.addDays(9), const Clock.hm(9, 0)));
      await days.markShare(_mark(id, CashOutcome.received));
      expect((await days.getWallet('me')).openDebts, isEmpty);
    });

    test('two "didn\'t get it" in 30 days flags the rider for review (FR-007)', () async {
      final kept = recentTrips(2);
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: kept));
      await repo.markShare(_mark(kept[0], CashOutcome.didNotPay));
      expect(await repo.disputeFlagged('me'), isFalse);
      await repo.markShare(_mark(kept[1], CashOutcome.didNotPay));
      expect(await repo.disputeFlagged('me'), isTrue);
    });
  });

  group('InstaPay handle (007 R7)', () {
    test('"≤ 40 chars, trimmed; empty → null"', () async {
      final repo = _repo(await _prefs());
      await repo.setInstapayHandle('me', '  karim@instapay  ');
      expect(await repo.instapayHandleOf('me'), 'karim@instapay');
      await repo.setInstapayHandle('me', 'x' * 60);
      expect((await repo.instapayHandleOf('me'))!.length, 40);
      await repo.setInstapayHandle('me', '   ');
      expect(await repo.instapayHandleOf('me'), isNull);
    });
  });

  group('subscription (brief §6.7 B, research R10)', () {
    test('Monthly with 200 in the wallet: 149 leaves, plan active one month', () async {
      final repo = _repo(await _prefs());
      await repo.topUp('me', method: 'instapay', amount: 200);
      expect(await repo.subscribe('me', PlanType.monthly, today: today), SubscribeResult.subscribed);
      final plan = (await repo.getPlan('me'))!;
      expect(plan.status, PlanStatus.active);
      expect(plan.startDate, now);
      expect(plan.untilDate, today.addMonths(1));
      final w = await repo.getWallet('me');
      expect(w.balance, 51);
      expect(w.activity.first.kind, ActivityKind.subscription);
    });

    test('Yearly is 1,490 for 12 months', () async {
      final repo = _repo(await _prefs());
      await repo.topUp('me', method: 'instapay', amount: 1500);
      await repo.subscribe('me', PlanType.yearly, today: today);
      expect((await repo.getPlan('me'))!.untilDate, today.addMonths(12));
      expect((await repo.getWallet('me')).balance, 10);
    });

    test('not enough balance: nothing charged, no plan', () async {
      final repo = _repo(await _prefs());
      await repo.topUp('me', method: 'instapay', amount: 100);
      expect(await repo.subscribe('me', PlanType.monthly, today: today), SubscribeResult.needsTopUp);
      expect(await repo.getPlan('me'), isNull);
      expect((await repo.getWallet('me')).balance, 100);
    });

    test(
        'research R14: a trip that settled earlier the SAME DAY the rider subscribes keeps its '
        'fee — only a trip after the exact subscribe moment is fee-free', () async {
      // now() is 9:00 AM `today`. The going leg (7:25 AM) settles before that;
      // the return leg (5:00 PM) settles after it. Five earlier trips use the trial up.
      final earlierToday = rideId(today, Leg.going);
      final laterToday = rideId(today, Leg.ret);
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(kept: [...trips(5), earlierToday, laterToday]));
      await repo.setMethod('me', PaymentMethod.cash);
      await repo.topUp('me', method: 'instapay', amount: 400);
      await repo.subscribe('me', PlanType.monthly, today: today);
      final rows = {for (final e in (await repo.getWallet('me')).activity) e.rideId: e};
      expect(rows[earlierToday]!.fee, 4, reason: 'settled before subscribing, even same-day — keeps its fee');
      expect(rows[laterToday]!.fee, 0, reason: 'settled after subscribing — fee-free');
      expect(rows[laterToday]!.toDriver, 40);
    });

    test("changePlan doesn't affect the current period", () async {
      final repo = _repo(await _prefs());
      await repo.topUp('me', method: 'instapay', amount: 200);
      await repo.subscribe('me', PlanType.monthly, today: today);
      final changed = await repo.changePlan('me', PlanType.yearly);
      expect(changed.untilDate, today.addMonths(1));
      expect(changed.startDate, now);
    });
  });

  group('seat ledger — Goora\'s fee only (005 T037, 007 R5)', () {
    test('a seat takes its 4 fee in one row; the 40 is shown, never debited', () async {
      final repo = _repo(await _prefs());
      await _bookSeat(repo, 'offer:t1');
      final w = await repo.getWallet('me');
      expect(w.balance, 196);
      final row = w.activity.singleWhere((e) => e.kind == ActivityKind.seatBooked);
      expect([row.amount, row.fee, row.toDriver, row.rideId], [4, 4, 40, 'offer:t1']);
    });

    test('a refund of the fee puts the balance back: one row each way', () async {
      final repo = _repo(await _prefs());
      await _bookSeat(repo, 'offer:t1');
      await repo.refundSeat('me', bookingId: 'bk-1', rideId: 'offer:t1', amount: 4, date: today);
      final w = await repo.getWallet('me');
      expect(w.balance, 200);
      expect(w.activity.singleWhere((e) => e.kind == ActivityKind.seatRefund).amount, 4);
    });

    test('a refund of 0 writes no row', () async {
      final repo = _repo(await _prefs());
      await _bookSeat(repo, 'offer:t1');
      await repo.refundSeat('me', bookingId: 'bk-1', rideId: 'offer:t1', amount: 0, date: today);
      expect((await repo.getWallet('me')).activity.where((e) => e.kind == ActivityKind.seatRefund), isEmpty);
    });

    test('the fee is an internal line: a failing provider still records it, below zero = owed', () async {
      final repo = _repo(await _prefs(), fail: true);
      await repo.debitSeat('me', bookingId: 'bk-1', rideId: 'offer:t1', fee: 4, share: 40, date: today);
      expect((await repo.getWallet('me')).balance, -4);
    });

    test('one debit and at most one credit per booking, however often called', () async {
      final repo = _repo(await _prefs());
      await _bookSeat(repo, 'offer:t1');
      await repo.debitSeat('me', bookingId: 'bk-1', rideId: 'offer:t1', fee: 4, share: 40, date: today);
      await repo.refundSeat('me', bookingId: 'bk-1', rideId: 'offer:t1', amount: 4, date: today);
      await repo.refundSeat('me', bookingId: 'bk-1', rideId: 'offer:t1', amount: 4, date: today);
      final w = await repo.getWallet('me');
      expect(w.balance, 200);
      expect(w.activity.where((e) => e.kind == ActivityKind.seatBooked), hasLength(1));
      expect(w.activity.where((e) => e.kind == ActivityKind.seatRefund), hasLength(1));
    });
  });

  group('one-off trips into the wallet (005 T038, research R9, R10)', () {
    test('one ride, one share: a seat paid at booking + the kept group trip on that ride (FR-016)', () async {
      final ride = rideId(today, Leg.going);
      final repo = _repo(await _prefs(),
          daily: _StubDailyRepo(kept: [ride]), oneOffs: [_oneOff(ride, today, paidBy: PaidBy.wallet)]);
      await repo.setMethod('me', PaymentMethod.cash);
      await _bookSeat(repo, ride);
      final w = await repo.getWallet('me');
      expect(w.balance, 200 - 4);
      expect(w.activity.where((e) => e.kind == ActivityKind.trip || e.kind == ActivityKind.cashTrip), isEmpty);
      expect(w.shares.where((s) => s.rideId == ride), hasLength(1));
    });

    test("a 003 charge on a ride paid at booking isn't billed again", () async {
      final ride = trips(1).single;
      final repo = _repo(await _prefs(), daily: _StubDailyRepo(charges: [_lateCancel(ride)]));
      await repo.setMethod('me', PaymentMethod.cash);
      await _bookSeat(repo, ride);
      expect((await repo.getWallet('me')).balance, 200 - 4);
    });

    test('a trial one-off on a group ride is one trial trip, not two', () async {
      final ride = trips(1).single;
      final repo = _repo(
        await _prefs(),
        daily: _StubDailyRepo(kept: [ride]),
        oneOffs: [_oneOff(ride, Ride.parseId(ride)!.$1)],
      );
      await repo.setMethod('me', PaymentMethod.instapay);
      final w = await repo.getWallet('me');
      expect(w.activity.where((e) => e.kind == ActivityKind.cashTrip).single.rideId, ride);
      expect(w.activity.where((e) => e.kind == ActivityKind.trip), isEmpty);
      expect(w.balance, 0);
    });

    test('trial one-offs count toward the 5, in date then leg order with group trips', () async {
      final kept = trips(5); // 1–5 Oct, going
      final repo = _repo(
        await _prefs(),
        daily: _StubDailyRepo(kept: kept),
        oneOffs: [_oneOff('offer:t1', CalendarDate(2026, 10, 1), leg: Leg.ret)],
      );
      await repo.setMethod('me', PaymentMethod.cash);
      final w = await repo.getWallet('me');
      expect(w.activity.where((e) => e.kind == ActivityKind.cashTrip).map((e) => e.rideId), contains('offer:t1'));
      expect(w.activity.where((e) => e.kind == ActivityKind.trip).single.rideId, kept.last,
          reason: "1 Oct return is the 2nd trip, so 5 Oct is the 6th: the trial's over");
      expect(w.balance, -4);
      expect(w.cashTrial!.endedBy, CashTrialEnd.tripsUsed);
    });

    test('after 3 trips mixing group and one-off trial trips, the banner shows', () async {
      final repo = _repo(
        await _prefs(),
        daily: _StubDailyRepo(kept: trips(1)),
        oneOffs: [
          _oneOff('offer:t1', CalendarDate(2026, 10, 10)),
          _oneOff('offer:t2', CalendarDate(2026, 10, 11)),
        ],
      );
      await repo.setMethod('me', PaymentMethod.cash);
      final trial = (await repo.getWallet('me')).cashTrial!;
      expect(trial.tripsDone, 3);
      expect(trial.showTopUpBanner, isTrue);
    });

    test('"didn\'t get it" on two one-off trips ends the trial; the next one carries the fee', () async {
      final days = [today.addDays(-3), today.addDays(-2), today.addDays(-1)];
      final repo = _repo(
        await _prefs(),
        daily: _StubDailyRepo(noGroup: true),
        oneOffs: [
          _oneOff('offer:a', days[0]),
          _oneOff('offer:b', days[1]),
          _oneOff('offer:c', days[2]),
        ],
      );
      await repo.setMethod('me', PaymentMethod.cash);
      await repo.markShare(_mark('offer:a', CashOutcome.didNotPay, date: days[0]));
      await repo.markShare(_mark('offer:b', CashOutcome.didNotPay, date: days[1]));
      final w = await repo.getWallet('me');
      expect(w.cashTrial!.endedBy, CashTrialEnd.strikes);
      final trip = w.activity.singleWhere((e) => e.kind == ActivityKind.trip);
      expect([trip.rideId, trip.amount, trip.fee], ['offer:c', 4, 4]);
    });

    test('a once user with no group still gets their trial trips counted', () async {
      final repo = _repo(
        await _prefs(),
        daily: _StubDailyRepo(noGroup: true),
        oneOffs: [_oneOff('offer:t1', CalendarDate(2026, 10, 5))],
      );
      await repo.setMethod('me', PaymentMethod.cash);
      expect((await repo.getWallet('me')).cashTrial!.tripsDone, 1);
    });

    test("fee and plan one-offs, and other riders' ones, are not billed by the fold", () async {
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

    test('driver: no trip income is ever written; each rider is one share', () async {
      final oneOffs = [
        _oneOff('offer:t1', today, paidBy: PaidBy.wallet, riderId: 'sara'),
        _oneOff('offer:t1', today, paidBy: PaidBy.plan, riderId: 'mona'),
        _oneOff('offer:t1', today, riderId: 'youssef'),
        _oneOff('offer:t9', today, paidBy: PaidBy.wallet, riderId: 'sara', driverId: 'karim'),
      ];
      final repo = _repo(await _prefs(), role: MemberRole.driver, oneOffs: oneOffs);
      await repo.getWallet('ahmed');
      final w = await repo.getWallet('ahmed');
      expect(w.activity, isEmpty);
      expect(w.balance, 0);
      expect(w.shares.where((s) => s.rideId == 'offer:t1').map((s) => s.riderId),
          unorderedEquals(['sara', 'mona', 'youssef']));
    });
  });
}
