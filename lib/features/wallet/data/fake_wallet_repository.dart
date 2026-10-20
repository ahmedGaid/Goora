import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart' show Leg;
import '../../commute/domain/group.dart';
import '../../company/domain/company_rules.dart';
import '../../daily/domain/absence.dart';
import '../../daily/domain/charge.dart';
import '../../daily/domain/check_in.dart';
import '../../daily/domain/daily_commute_repository.dart';
import '../../daily/domain/ride.dart';
import '../../daily/domain/trust.dart';
import '../domain/activity_entry.dart';
import '../domain/cash_mark.dart';
import '../domain/cash_trial_policy.dart';
import '../domain/direct_pay.dart';
import '../domain/done_one_off.dart';
import '../domain/fee_balance.dart';
import '../domain/fee_savings_calculator.dart';
import '../domain/payment_method.dart';
import '../domain/payment_provider.dart';
import '../domain/plan.dart';
import '../domain/share.dart';
import '../domain/wallet.dart';
import '../domain/wallet_repository.dart';
import 'wallet_seed.dart';

/// Wallet/plan on fake data over shared_preferences (contracts/repositories.md).
/// The ledger (top-ups, withdrawals, subscriptions, Goora's fees) is this
/// feature's own; trips and 003's charges are derived from 003's records on
/// every read (004 research R3, R7) and priced here. The driver's share is
/// paid outside Goora (007): it is never debited or credited, only derived
/// as a [Share] whose status comes from the driver's mark and the rider's
/// claim (007 research R1, R2). One-off seats (005) record Goora's fee at
/// booking through [SeatLedger]; finished ones come in through the `oneOffs`
/// callback (research R9).
final class FakeWalletRepository implements WalletRepository, SeatLedger {
  FakeWalletRepository(
    this._prefs, {
    required this._daily,
    required this._role,
    required this._now,
    required this._provider,
    this._oneOffs = _noOneOffs,
    this._companyCoverage = _noCompanyCoverage,
  });

  static const planKey = 'wallet.plan';
  static const marksKey = 'wallet.cashMarks';
  static const claimsKey = 'wallet.paidClaims';
  static String methodKey(String personId) => 'wallet.method.$personId';
  static String instapayKey(String driverId) => 'wallet.instapay.$driverId';

  /// Set for a 004 rider who chose "wallet" and so gave up the cash trial
  /// (004 v2 US1): they stay out of the fee-free trial (007 research R6).
  static String noTrialKey(String personId) => 'wallet.noTrial.$personId';

  /// The day the rider set up payment; trips before it are not billed (003's
  /// seeded history is demo standing, not trips the rider owes for).
  static String sinceKey(String personId) => 'wallet.since.$personId';
  /// 010 research R8: the personal plan paused while enrolled. Under
  /// `company.` so it goes with the company network's data on reset.
  static String pausedKey(String personId) => 'company.paused.$personId';

  /// From this moment the rider has no fee-free trial (010 Q11 default: none
  /// once they joined a company); trips before it keep theirs.
  static String noTrialFromKey(String personId) => 'wallet.noTrialFrom.$personId';

  /// Windows in which an arrangement that has since been replaced (a
  /// personal plan until it was paused, a company enrollment once it ended)
  /// made trips fee-free, so switching never re-prices a trip already taken.
  static String coveredKey(String personId) => 'wallet.coveredBefore.$personId';
  static String _activityKey(String ownerId) => 'wallet.activity.$ownerId';
  static String _balanceKey(String ownerId) => 'wallet.balance.$ownerId';

  /// How far back trips and charges are read (v1's activity window).
  static const _window = 60;

  /// "≤ 40 chars, trimmed" (007 research R7).
  static const instapayMaxLength = 40;

  final SharedPreferences _prefs;
  final DailyCommuteRepository _daily;
  final MemberRole Function() _role;
  final Now _now;
  final PaymentProvider _provider;

  /// The finished one-off trips the marketplace knows about, one per (trip,
  /// rider); filtered here by person and role.
  final Future<List<DoneOneOff>> Function() _oneOffs;

  static Future<List<DoneOneOff>> _noOneOffs() async => const [];

  /// The company network's fee-free windows for a person (010 research R2,
  /// contracts § Seams); null = the network does not know them, so a stored
  /// company plan keeps its pre-010 meaning (covered from its start). A
  /// function read when called, never a provider watched while building, so
  /// wallet and company cannot form a provider cycle (005 lesson).
  final Future<List<Window>?> Function(String personId) _companyCoverage;

  static Future<List<Window>?> _noCompanyCoverage(String _) async => null;

  /// Settings → "Reset demo data" clears every wallet key.
  static Future<void> clearAll(SharedPreferences prefs) async {
    for (final key in prefs.getKeys().where((k) => k.startsWith('wallet.')).toList()) {
      await prefs.remove(key);
    }
  }

  // ----------------------------------------------------------------- plan

  @override
  Future<Plan?> getPlan(String personId) async {
    final raw = _prefs.getString(planKey);
    if (raw == null) return null;
    final plan = Plan.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    if (plan.personId != personId) return null;
    if (plan.type != PlanType.company) return plan;
    final windows = await _companyCoverage(personId);
    return windows == null ? plan : plan.withCoverage(windows);
  }

  @override
  Future<SubscribeResult> subscribe(String personId, PlanType type, {required CalendarDate today}) async {
    if (type == PlanType.company) {
      await _markSince(personId, today);
      await _savePlan(Plan(personId: personId, type: type, status: PlanStatus.active, price: 0, startDate: _now()));
      return SubscribeResult.subscribed;
    }
    await _markSince(personId, today);
    final price = priceFor(type);
    final wallet = await getWallet(personId);
    if (wallet.balance < price) return SubscribeResult.needsTopUp;
    await _post(personId, kind: ActivityKind.subscription, amount: -price);
    await _savePlan(Plan(
      personId: personId,
      type: type,
      status: PlanStatus.active,
      price: price,
      startDate: _now(),
      untilDate: today.addMonths(type == PlanType.yearly ? 12 : 1),
    ));
    return SubscribeResult.subscribed;
  }

  @override
  Future<Plan> changePlan(String personId, PlanType newType) async {
    final current = await getPlan(personId);
    return _savePlan(Plan(
      personId: personId,
      type: newType,
      status: current?.status ?? PlanStatus.active,
      price: priceFor(newType),
      startDate: current?.startDate,
      untilDate: newType == PlanType.company ? null : current?.untilDate,
    ));
  }

  @override
  Future<void> startCompanyPlan(String personId, WallTime now) async {
    final current = await getPlan(personId);
    if (current != null) {
      await _keepCovered(personId, current, until: now);
      final until = current.untilDate;
      final daysLeft = current.type != PlanType.company && current.status == PlanStatus.active && until != null
          ? now.date.daysUntil(until)
          : 0;
      if (daysLeft > 0) {
        await _prefs.setString(
          pausedKey(personId),
          jsonEncode({'type': current.type.name, 'price': current.price, 'daysLeft': daysLeft}),
        );
      }
    }
    await _markSince(personId, now.date);
    if (!_prefs.containsKey(noTrialFromKey(personId))) await _prefs.setString(noTrialFromKey(personId), now.toJson());
    await _savePlan(Plan(personId: personId, type: PlanType.company, status: PlanStatus.active, price: 0, startDate: now));
  }

  @override
  Future<void> endCompanyPlan(String personId, WallTime now) async {
    final current = await getPlan(personId);
    if (current == null || current.type != PlanType.company) return;
    await _keepCovered(personId, current, until: now);
    final paused = await pausedPlan(personId);
    await _prefs.remove(pausedKey(personId));
    if (paused == null) {
      await _prefs.remove(planKey);
      return;
    }
    await _savePlan(Plan(
      personId: personId,
      type: paused.type,
      status: PlanStatus.active,
      price: paused.price,
      startDate: now,
      untilDate: now.date.addDays(paused.daysLeft),
    ));
  }

  @override
  Future<PausedPlan?> pausedPlan(String personId) async {
    final raw = _prefs.getString(pausedKey(personId));
    if (raw == null) return null;
    final j = (jsonDecode(raw) as Map).cast<String, Object?>();
    return (type: PlanType.values.byName(j['type']! as String), price: j['price']! as int, daysLeft: j['daysLeft']! as int);
  }

  /// Records what [plan] made fee-free up to [until], before it is replaced.
  Future<void> _keepCovered(String personId, Plan plan, {required WallTime until}) async {
    final end = SharePolicy.minuteOf(until);
    final List<Window> spans;
    if (plan.coverage != null) {
      spans = [
        for (final w in plan.coverage!) (from: w.from, to: w.to == null || w.to! > end ? end : w.to),
      ];
    } else {
      final from = plan.startDate == null ? 0 : SharePolicy.minuteOf(plan.startDate!);
      final paidTo = plan.untilDate == null ? null : SharePolicy.dayOf(plan.untilDate!.addDays(1)) * 24 * 60;
      final covers = plan.type == PlanType.company || plan.status == PlanStatus.active;
      spans = [if (covers) (from: from, to: paidTo == null || paidTo > end ? end : paidTo)];
    }
    final kept = [..._covered(personId), for (final w in spans) if (w.to! > w.from) w];
    await _prefs.setString(coveredKey(personId), jsonEncode([for (final w in kept) [w.from, w.to]]));
  }

  List<Window> _covered(String personId) {
    final raw = _prefs.getString(coveredKey(personId));
    if (raw == null) return const [];
    return [
      for (final w in jsonDecode(raw) as List) (from: (w as List)[0] as int, to: w[1] as int?),
    ];
  }

  WallTime? _noTrialFrom(String personId) {
    final raw = _prefs.getString(noTrialFromKey(personId));
    return raw == null ? null : WallTime.fromJson(raw);
  }

  static int priceFor(PlanType type) => switch (type) {
        PlanType.monthly => 149,
        PlanType.yearly => 1490,
        PlanType.company => 0,
      };

  Future<Plan> _savePlan(Plan plan) async {
    await _prefs.setString(planKey, jsonEncode(plan.toJson()));
    return plan;
  }

  // --------------------------------------------------------------- method

  @override
  Future<PaymentMethod?> getMethod(String personId) async {
    final raw = _prefs.getString(methodKey(personId));
    return raw == null ? null : PaymentMethod.parse(raw);
  }

  @override
  Future<void> setMethod(String personId, PaymentMethod method) async {
    await _markSince(personId, _now().date);
    if (_prefs.getString(methodKey(personId)) == _legacyWallet) await _prefs.setBool(noTrialKey(personId), true);
    await _prefs.setString(methodKey(personId), method.name);
  }

  static const _legacyWallet = 'wallet';

  bool _trialForfeited(String personId) =>
      (_prefs.getBool(noTrialKey(personId)) ?? false) || _prefs.getString(methodKey(personId)) == _legacyWallet;

  Future<void> _markSince(String personId, CalendarDate date) async {
    if (!_prefs.containsKey(sinceKey(personId))) await _prefs.setString(sinceKey(personId), date.toIso());
  }

  @override
  Future<PaymentMethod?> methodOf(String riderId) async => await getMethod(riderId) ?? WalletSeed.methods[riderId];

  @override
  Future<String?> instapayHandleOf(String driverId) async =>
      _prefs.getString(instapayKey(driverId)) ?? WalletSeed.instapayHandles[driverId];

  @override
  Future<void> setInstapayHandle(String driverId, String? handle) async {
    var h = (handle ?? '').trim();
    if (h.length > instapayMaxLength) h = h.substring(0, instapayMaxLength);
    if (h.isEmpty) {
      await _prefs.remove(instapayKey(driverId));
    } else {
      await _prefs.setString(instapayKey(driverId), h);
    }
  }

  // ------------------------------------------------- marks, claims, shares

  @override
  Future<List<CashMark>> shareMarks(String rideId) async => [
        for (final m in _currentMarks().values)
          if (m.rideId == rideId) m,
      ];

  @override
  Future<void> markShare(CashMark mark) async {
    final now = _now();
    final end = await _tripEnd(mark.rideId, mark.riderId) ?? WallTime(mark.date, const Clock.hm(0, 0));
    final allowed = SharePolicy.canMark(
      current: _statusOf(mark.rideId, mark.riderId, end, now),
      outcome: mark.outcome,
      tripEnd: SharePolicy.minuteOf(end),
      now: SharePolicy.minuteOf(now),
      reversedOnce: _reversedOnce(mark.rideId, mark.riderId, end),
    );
    if (!allowed) return;
    final stamped = mark.markedAt == null ? _withMarkedAt(mark, now) : mark;
    await _prefs.setString(marksKey, jsonEncode([for (final m in [..._marks(), stamped]) m.toJson()]));
  }

  static CashMark _withMarkedAt(CashMark m, WallTime at) => CashMark(
        rideId: m.rideId,
        riderId: m.riderId,
        driverId: m.driverId,
        outcome: m.outcome,
        amount: m.amount,
        date: m.date,
        markedAt: at,
      );

  @override
  Future<void> claimPaid(String rideId, String riderId) async {
    final claim = PaidClaim(rideId: rideId, riderId: riderId, claimedAt: _now());
    await _prefs.setString(claimsKey, jsonEncode([for (final c in [..._claims(), claim]) c.toJson()]));
  }

  @override
  Future<List<Share>> openShares(String riderId) async {
    final shares = (await _riderTrips(riderId, await getMethod(riderId), await getPlan(riderId), _now().date)).shares;
    return _unconfirmedFirstDebts(shares);
  }

  @override
  Future<List<Share>> driverShares(String driverId) async {
    final today = _now().date;
    final from = today.addDays(-_window);
    final shares = <String, Share>{};
    final group = driverId == _daily.meId ? await _daily.myGroup() : null;
    if (group != null) {
      for (var d = from; !d.isAfter(today); d = d.addDays(1)) {
        for (final leg in group.legs) {
          final ride = await _daily.ride(d, leg);
          if (ride == null || ride.driverId != driverId) continue;
          final end = ride.endedAt;
          if (end == null) continue;
          for (final o in await _daily.outcomes(ride.id)) {
            if (o.outcome != Outcome.pickedUp || o.personId == driverId) continue;
            final rider = group.member(o.personId);
            final method = await methodOf(o.personId) ?? PaymentMethod.cash;
            shares['${ride.id}|${o.personId}'] = _share(
              rideId: ride.id,
              riderId: o.personId,
              driverId: driverId,
              otherFirstName: rider?.firstName ?? '',
              amount: DirectPay.share(group.price,
                  method: method, tripCost: group.tripCost, riderSeats: group.riderSeats),
              method: method,
              tripEnd: end,
            );
          }
        }
      }
    }
    for (final o in await _oneOffs()) {
      if (o.driverId != driverId || o.date.isBefore(from)) continue;
      shares.putIfAbsent('${o.rideId}|${o.riderId}', () {
        final method = WalletSeed.methods[o.riderId] ?? PaymentMethod.cash;
        return _share(
          rideId: o.rideId,
          riderId: o.riderId,
          driverId: driverId,
          otherFirstName: o.riderName,
          amount: DirectPay.share(o.contribution, method: method, tripCost: o.tripCost, riderSeats: o.riderSeats),
          method: method,
          tripEnd: _oneOffEnd(o),
        );
      });
    }
    // A mark on a ride neither side knows (the seeded one) still shows.
    for (final m in _currentMarks().values) {
      if (m.driverId != driverId || m.date.isBefore(from)) continue;
      shares.putIfAbsent('${m.rideId}|${m.riderId}', () {
        final method = WalletSeed.methods[m.riderId] ?? PaymentMethod.cash;
        return _share(
          rideId: m.rideId,
          riderId: m.riderId,
          driverId: driverId,
          otherFirstName: WalletSeed.riderNames[m.riderId] ?? '',
          amount: m.amount,
          method: method,
          tripEnd: WallTime(m.date, const Clock.hm(0, 0)),
        );
      });
    }
    final list = shares.values.toList()..sort((a, b) => b.tripEnd.compareTo(a.tripEnd));
    return list;
  }

  @override
  Future<Share?> driverShareOn(String rideId, String riderId) async {
    for (final s in await driverShares(_daily.meId)) {
      if (s.rideId == rideId && s.riderId == riderId) return s;
    }
    return null;
  }

  @override
  Future<bool> disputeFlagged(String riderId) async {
    final days = [
      for (final m in _currentMarks().values)
        if (m.riderId == riderId && m.outcome == CashOutcome.didNotPay) SharePolicy.dayOf(m.date),
    ];
    return SharePolicy.disputeFlagged(days, SharePolicy.dayOf(_now().date));
  }

  /// Every mark ever written, oldest first (the history, data-model).
  List<CashMark> _marks() {
    final raw = _prefs.getString(marksKey);
    if (raw == null) return const [];
    return [for (final m in jsonDecode(raw) as List) CashMark.fromJson((m as Map).cast<String, Object?>())];
  }

  /// The latest mark per (ride, rider).
  Map<String, CashMark> _currentMarks() => {for (final m in _marks()) '${m.rideId}|${m.riderId}': m};

  List<PaidClaim> _claims() {
    final raw = _prefs.getString(claimsKey);
    if (raw == null) return const [];
    return [for (final c in jsonDecode(raw) as List) PaidClaim.fromJson((c as Map).cast<String, Object?>())];
  }

  ShareStatus _statusOf(String rideId, String riderId, WallTime tripEnd, WallTime now) {
    final mark = _currentMarks()['$rideId|$riderId'];
    final claim = _claims().where((c) => c.rideId == rideId && c.riderId == riderId).lastOrNull;
    return SharePolicy.status(
      mark: mark?.outcome,
      markedAt: mark == null ? null : SharePolicy.minuteOf(mark.markedAt ?? WallTime(mark.date, const Clock.hm(0, 0))),
      claimAt: claim == null ? null : SharePolicy.minuteOf(claim.claimedAt),
      tripEnd: SharePolicy.minuteOf(tripEnd),
      now: SharePolicy.minuteOf(now),
    );
  }

  /// A "didn't pay" written after the 24 hours had passed: the one reversal
  /// of an auto-received share (research R2).
  bool _reversedOnce(String rideId, String riderId, WallTime tripEnd) {
    final end = SharePolicy.minuteOf(tripEnd);
    return _marks().any((m) =>
        m.rideId == rideId &&
        m.riderId == riderId &&
        m.outcome == CashOutcome.didNotPay &&
        m.markedAt != null &&
        SharePolicy.minuteOf(m.markedAt!) - end >= SharePolicy.autoReceiveMinutes);
  }

  Share _share({
    required String rideId,
    required String riderId,
    required String driverId,
    required String otherFirstName,
    required int amount,
    required PaymentMethod method,
    required WallTime tripEnd,
  }) =>
      Share(
        rideId: rideId,
        riderId: riderId,
        driverId: driverId,
        otherFirstName: otherFirstName,
        amount: amount,
        method: method,
        tripEnd: tripEnd,
        status: _statusOf(rideId, riderId, tripEnd, _now()),
        reversedOnce: _reversedOnce(rideId, riderId, tripEnd),
      );

  /// When a ride's trip ended, for the 24-hour rule: 003's recorded end,
  /// else the group's planned arrival; a one-off's own end.
  Future<WallTime?> _tripEnd(String rideId, String riderId) async {
    final at = Ride.parseId(rideId);
    if (at != null) {
      final ride = await _daily.ride(at.$1, at.$2);
      if (ride?.endedAt != null) return ride!.endedAt;
      final group = await _daily.myGroup();
      if (group != null && ride != null) return WallTime(at.$1, group.endFor(at.$2));
    }
    for (final o in await _oneOffs()) {
      if (o.rideId == rideId && o.riderId == riderId) return _oneOffEnd(o);
    }
    return null;
  }

  static WallTime _oneOffEnd(DoneOneOff o) => o.end ?? WallTime(o.date, const Clock.hm(23, 59));

  /// Open debts first (oldest first), then the rest newest first.
  static List<Share> _unconfirmedFirstDebts(List<Share> shares) {
    final debts = [for (final s in shares) if (s.status.isOpenDebt) s]
      ..sort((a, b) => a.tripEnd.compareTo(b.tripEnd));
    final pending = [for (final s in shares) if (s.status == ShareStatus.pending) s]
      ..sort((a, b) => b.tripEnd.compareTo(a.tripEnd));
    return [...debts, ...pending];
  }

  // --------------------------------------------------------------- wallet

  @override
  Future<Wallet> getWallet(String ownerId) async {
    final today = _now().date;
    if (_role() == MemberRole.driver) {
      await _ensureDriverSeeded(ownerId);
      final shares = await driverShares(ownerId);
      return Wallet(
        ownerId: ownerId,
        role: MemberRole.driver,
        balance: _ledger(ownerId),
        activity: _readActivity(ownerId),
        cashReceived: shares
            .where((s) =>
                (s.status == ShareStatus.received || s.status == ShareStatus.autoReceived) &&
                s.tripEnd.date.monthKey == today.monthKey)
            .fold(0, (sum, s) => sum + s.amount),
        shares: shares,
      );
    }
    final method = await getMethod(ownerId);
    final derived = await _riderTrips(ownerId, method, await getPlan(ownerId), today);
    final stored = _readActivity(ownerId);
    final activity = [...stored, ...derived.entries]..sort((a, b) => b.date.compareTo(a.date));
    final balance = _ledger(ownerId) - derived.debits;
    final due = FeeBalancePolicy.dueDate(_daySeries(stored, derived.entries, balance), today);
    return Wallet(
      ownerId: ownerId,
      role: MemberRole.rider,
      balance: balance,
      activity: activity,
      method: method,
      cashTrial: derived.cashTrial,
      feesThisMonth: FeeSavingsCalculator.feesInMonth(derived.entries, today.monthKey),
      shares: _unconfirmedFirstDebts(derived.shares),
      bundleTripsLeft: derived.bundleLeft,
      feeDue: due,
      feeOverdue: FeeBalancePolicy.isOverdue(due, today),
    );
  }

  /// 004 research R8, 007 R5/R6: walk the rider's completed trips and 003
  /// charges in order. Every trip and charge is a share the rider pays the
  /// driver directly — never debited here. While the fee-free trial allows
  /// it a trip carries no Goora fee; after it each trip debits only Goora's
  /// fee ([DirectPay.fee]). A charge (late cancel, no-show) is the driver's
  /// alone, with no fee.
  ///
  /// 005 adds finished one-off trips (research R9) and counts each rideId
  /// once per person (R10, "one ride, one charge"): a group trip or charge on
  /// a ride whose fee was taken at booking (`seatBooked`) is skipped, and a
  /// trial one-off on a group ride is that ride's one trial trip.
  Future<_Derived> _riderTrips(String ownerId, PaymentMethod? method, Plan? plan, CalendarDate today) async {
    final sinceRaw = _prefs.getString(sinceKey(ownerId));
    final since = sinceRaw == null ? plan?.startDate?.date : CalendarDate.parse(sinceRaw);
    if (since == null) {
      return _Derived(
          bundleLeft: TripBundle.trips * _readActivity(ownerId).where((e) => e.kind == ActivityKind.bundle).length);
    }
    final payBy = method ?? PaymentMethod.cash;
    final noTrial = _trialForfeited(ownerId);
    final noTrialFrom = _noTrialFrom(ownerId);
    final coveredBefore = _covered(ownerId);
    final window = today.addDays(-_window);
    final from = since.isAfter(window) ? since : window;
    final marks = _currentMarks().values.where((m) => m.riderId == ownerId).toList();
    final paidAtBooking = {
      for (final e in _readActivity(ownerId))
        if (e.kind == ActivityKind.seatBooked) e.rideId,
    };

    final shares = <Share>[];
    final trialOneOffs = <String, _Item>{};
    for (final o in await _oneOffs()) {
      if (o.riderId != ownerId || o.date.isBefore(from) || o.date.isAfter(today)) continue;
      if (paidAtBooking.contains(o.rideId)) {
        // Goora's fee was taken at booking; the share is still the driver's.
        shares.add(_share(
          rideId: o.rideId,
          riderId: ownerId,
          driverId: o.driverId,
          otherFirstName: o.driverName,
          amount: DirectPay.share(o.contribution, method: payBy, tripCost: o.tripCost, riderSeats: o.riderSeats),
          method: payBy,
          tripEnd: _oneOffEnd(o),
        ));
        continue;
      }
      if (o.paidBy != PaidBy.cash) continue;
      trialOneOffs.putIfAbsent(o.rideId, () => _Item(o.date, o.leg, rideId: o.rideId, oneOff: o));
    }
    bool billedElsewhere(String rideId) => paidAtBooking.contains(rideId) || trialOneOffs.containsKey(rideId);

    final items = <_Item>[...trialOneOffs.values];
    final group = ownerId == _daily.meId ? await _daily.myGroup() : null;
    if (group != null) {
      for (final e in await _daily.events(from, today)) {
        if (e.kind != ReliabilityEventKind.kept || billedElsewhere(e.rideId)) continue;
        final at = Ride.parseId(e.rideId);
        if (at == null || at.$1.isBefore(from)) continue;
        final ride = await _daily.ride(at.$1, at.$2);
        // A trip the person drove is not a rider trip.
        if (ride == null || ride.driverId == ownerId) continue;
        items.add(_Item(at.$1, at.$2, rideId: e.rideId, ride: ride));
      }
      for (final c in await _daily.chargesOwed()) {
        if (paidAtBooking.contains(c.rideId)) continue;
        final at = Ride.parseId(c.rideId);
        if (at == null || at.$1.isBefore(from)) continue;
        items.add(_Item(at.$1, at.$2, rideId: c.rideId, charge: c, ride: await _daily.ride(at.$1, at.$2)));
      }
    }
    items.sort((a, b) => a.compareTo(b));

    final entries = <ActivityEntry>[];
    var debits = 0;
    // A bundle covers trips from the day it was bought, never earlier ones.
    final purchases = [
      for (final e in _readActivity(ownerId))
        if (e.kind == ActivityKind.bundle) e.date,
    ];
    var bundleUsed = 0;
    int bundleLeftOn(CalendarDate day) =>
        TripBundle.trips * purchases.where((p) => !p.isAfter(day)).length - bundleUsed;
    var trialDone = 0;
    var strikes = 0;
    for (final item in items) {
      final oneOff = item.oneOff;
      // A one-off has no group time: a plan covers it only if it started
      // before that day (never re-prices a trip after the fact, 004 R14).
      final itemAt = oneOff != null
          ? WallTime(item.date, const Clock.hm(0, 0))
          : WallTime(item.date, item.leg == Leg.going ? group!.going : group!.ret);
      final feeFree = (plan != null && plan.coversTrip(itemAt)) ||
          CompanyRules.covered(coveredBefore, SharePolicy.minuteOf(itemAt));
      final inTrial = !feeFree &&
          !noTrial &&
          (noTrialFrom == null || itemAt.isBefore(noTrialFrom)) &&
          CashTrialPolicy.available(trialDone, strikes);
      final contribution = oneOff?.contribution ?? group!.price;
      final tripCost = oneOff?.tripCost ?? group!.tripCost;
      final riderSeats = oneOff?.riderSeats ?? group!.riderSeats;
      final driverId = oneOff?.driverId ?? item.ride?.driverId ?? group!.driverFor(item.leg)?.id ?? '';
      final driverName = oneOff?.driverName ?? group?.member(driverId)?.firstName ?? '';
      final tripEnd = oneOff != null
          ? _oneOffEnd(oneOff)
          : (item.ride?.endedAt ?? WallTime(item.date, group!.endFor(item.leg)));
      final charge = item.charge;
      final share = charge?.amount ??
          DirectPay.share(contribution, method: payBy, tripCost: tripCost, riderSeats: riderSeats);
      if (share > 0) {
        shares.add(_share(
          rideId: item.rideId,
          riderId: ownerId,
          driverId: driverId,
          otherFirstName: driverName,
          amount: share,
          method: payBy,
          tripEnd: tripEnd,
        ));
      }
      if (charge == null) {
        if (inTrial) {
          trialDone++;
          strikes += marks.where((m) => m.rideId == item.rideId && m.outcome == CashOutcome.didNotPay).length;
          entries.add(ActivityEntry(
            id: 'cash:${item.rideId}',
            kind: ActivityKind.cashTrip,
            amount: 0,
            date: item.date,
            rideId: item.rideId,
            shareToDriver: share,
          ));
        } else {
          final fee = DirectPay.fee(contribution,
              share: share, tripCost: tripCost, riderSeats: riderSeats, feeFree: feeFree);
          if (TripBundle.useBundle(fee, bundleLeftOn(item.date))) {
            // 008 FR-008: a bundle trip covers Goora's fee; nothing is owed.
            bundleUsed++;
            entries.add(ActivityEntry(
              id: 'bundle-trip:${item.rideId}',
              kind: ActivityKind.bundleTrip,
              amount: 0,
              date: item.date,
              rideId: item.rideId,
              shareToDriver: share,
            ));
          } else {
            debits += fee;
            entries.add(ActivityEntry(
              id: 'trip:${item.rideId}',
              kind: ActivityKind.trip,
              amount: fee,
              fee: fee,
              date: item.date,
              rideId: item.rideId,
              shareToDriver: share,
            ));
          }
        }
      } else {
        entries.add(ActivityEntry(
          id: 'charge:${charge.id}',
          kind: charge.reason == ChargeReason.lateCancel ? ActivityKind.lateCancelCharge : ActivityKind.tripDeduction,
          amount: 0,
          date: item.date,
          rideId: charge.rideId,
          shareToDriver: charge.amount,
        ));
      }
    }
    for (final absence in group == null ? const <Absence>[] : await _daily.absences(from, today)) {
      if (absence.personId == ownerId && absence.kind == AbsenceKind.freeCancel) {
        entries.add(ActivityEntry(
          id: 'absence:${absence.personId}:${absence.date.toIso()}:${absence.leg.name}',
          kind: ActivityKind.freeCancelZero,
          amount: 0,
          date: absence.date,
        ));
      }
    }
    return _Derived(
      entries: entries,
      debits: debits,
      bundleLeft: TripBundle.trips * purchases.length - bundleUsed,
      cashTrial: noTrial || noTrialFrom != null ? null : CashTrialStatus(tripsDone: trialDone, strikes: strikes),
      shares: shares,
    );
  }

  /// A driver's first-ever wallet read seeds one confirmed share (research
  /// R11, 007 R8), once. Goora moves no driver money, so no income rows: the
  /// ledger starts empty. A driver with no group (005 "Just one trip", T104)
  /// starts with nothing at all.
  Future<void> _ensureDriverSeeded(String ownerId) async {
    if (_prefs.containsKey(_activityKey(ownerId))) return;
    await _writeActivity(ownerId, const []);
    if (ownerId == _daily.meId && await _daily.myGroup() == null) return;
    final today = _now().date;
    final seed = WalletSeed.driverCashMark(ownerId, today);
    await _prefs.setString(marksKey, jsonEncode([for (final m in [..._marks(), seed]) m.toJson()]));
  }

  // ------------------------------------------------------------ seat ledger

  @override
  Future<void> debitSeat(String personId,
      {required String bookingId,
      required String rideId,
      required int fee,
      required int share,
      required CalendarDate date}) async {
    final id = 'seat:$bookingId';
    if (_readActivity(personId).any((e) => e.id == id)) return;
    await _append(
        personId,
        ActivityEntry(
            id: id,
            kind: ActivityKind.seatBooked,
            amount: fee,
            fee: fee,
            date: date,
            rideId: rideId,
            shareToDriver: share),
        delta: -fee);
  }

  @override
  Future<void> refundSeat(String personId,
      {required String bookingId, required String rideId, required int amount, required CalendarDate date}) async {
    final id = 'refund:$bookingId';
    if (amount == 0 || _readActivity(personId).any((e) => e.id == id)) return;
    await _append(personId, ActivityEntry(id: id, kind: ActivityKind.seatRefund, amount: amount, date: date, rideId: rideId),
        delta: amount);
  }

  // --------------------------------------------------------------- ledger

  @override
  Future<PaymentResult> topUp(String ownerId, {required String method, required int amount}) async {
    final result = await _provider.topUp(method: method, amount: amount);
    if (result == PaymentResult.success) await _post(ownerId, kind: ActivityKind.topUp, amount: amount);
    return result;
  }

  @override
  Future<PaymentResult> withdraw(String ownerId, {required int amount}) async {
    final result = await _provider.withdraw(amount: amount);
    if (result == PaymentResult.success) await _post(ownerId, kind: ActivityKind.withdrawal, amount: -amount);
    return result;
  }

  @override
  Future<PaymentResult> settle(String riderId, {required String method}) async {
    final owed = (await getWallet(riderId)).owed;
    if (owed == 0) return PaymentResult.success;
    final result = await _provider.debit(amount: owed);
    if (result == PaymentResult.success) await _post(riderId, kind: ActivityKind.settlement, amount: owed);
    return result;
  }

  @override
  Future<PaymentResult> buyBundle(String riderId, {required String method}) async {
    final result = await _provider.debit(amount: TripBundle.price);
    if (result == PaymentResult.success) {
      // Paid outside the balance (008 R4): a row, no delta.
      await _append(
        riderId,
        ActivityEntry(
          id: 'bundle${DateTime.now().microsecondsSinceEpoch}',
          kind: ActivityKind.bundle,
          amount: TripBundle.price,
          date: _now().date,
        ),
        delta: 0,
      );
    }
    return result;
  }

  /// End-of-day balances for [FeeBalancePolicy.dueDate] (008 R2): the opening
  /// balance (what the ledger held before any row) plus each day's moves,
  /// ending at [balance].
  static List<DayBalance> _daySeries(List<ActivityEntry> stored, List<ActivityEntry> derived, int balance) {
    int delta(ActivityEntry e) => switch (e.kind) {
          ActivityKind.topUp || ActivityKind.seatRefund || ActivityKind.settlement => e.amount,
          ActivityKind.withdrawal || ActivityKind.subscription || ActivityKind.seatBooked || ActivityKind.trip => -e.amount,
          ActivityKind.tripIncome || ActivityKind.feeReceived => e.amount,
          _ => 0,
        };
    final byDay = <CalendarDate, int>{};
    var total = 0;
    for (final e in [...stored, ...derived]) {
      final d = delta(e);
      if (d == 0) continue;
      byDay[e.date] = (byDay[e.date] ?? 0) + d;
      total += d;
    }
    final days = byDay.keys.toList()..sort();
    var running = balance - total;
    return [
      for (final day in days) (date: day, balance: running += byDay[day]!),
    ];
  }

  int _ledger(String ownerId) => _prefs.getInt(_balanceKey(ownerId)) ?? 0;

  Future<void> _post(String ownerId, {required ActivityKind kind, required int amount}) => _append(
        ownerId,
        ActivityEntry(
          id: '${kind.name}${DateTime.now().microsecondsSinceEpoch}',
          kind: kind,
          amount: amount.abs(),
          date: _now().date,
        ),
        delta: amount,
      );

  /// Writes [entry] first in the activity and moves the balance by [delta].
  Future<void> _append(String ownerId, ActivityEntry entry, {required int delta}) async {
    await _prefs.setInt(_balanceKey(ownerId), _ledger(ownerId) + delta);
    await _writeActivity(ownerId, [entry, ..._readActivity(ownerId)]);
  }

  List<ActivityEntry> _readActivity(String ownerId) {
    final raw = _prefs.getString(_activityKey(ownerId));
    if (raw == null) return const [];
    return [for (final e in jsonDecode(raw) as List) ActivityEntry.fromJson((e as Map).cast<String, Object?>())];
  }

  Future<void> _writeActivity(String ownerId, List<ActivityEntry> items) =>
      _prefs.setString(_activityKey(ownerId), jsonEncode([for (final i in items) i.toJson()]));
}

final class _Derived {
  const _Derived({
    this.entries = const [],
    this.debits = 0,
    this.bundleLeft = 0,
    this.cashTrial = const CashTrialStatus(tripsDone: 0, strikes: 0),
    this.shares = const [],
  });

  final List<ActivityEntry> entries;

  /// Goora's fees only — never a driver's share.
  final int debits;

  /// Bundle trips not used by the walk (008).
  final int bundleLeft;
  /// Null when the rider gave up the trial in 004.
  final CashTrialStatus? cashTrial;
  final List<Share> shares;
}

/// One trip or charge, ordered by date then leg (going before return), a
/// charge after the trip of the same ride. [oneOff] set = a 005 trial one-off.
final class _Item implements Comparable<_Item> {
  _Item(this.date, this.leg, {required this.rideId, this.charge, this.oneOff, this.ride});

  final CalendarDate date;
  final Leg leg;
  final String rideId;
  final Charge? charge;
  final DoneOneOff? oneOff;
  final Ride? ride;

  @override
  int compareTo(_Item other) {
    final byDate = date.compareTo(other.date);
    if (byDate != 0) return byDate;
    final byLeg = leg.index.compareTo(other.leg.index);
    if (byLeg != 0) return byLeg;
    return (charge == null ? 0 : 1).compareTo(other.charge == null ? 0 : 1);
  }
}
