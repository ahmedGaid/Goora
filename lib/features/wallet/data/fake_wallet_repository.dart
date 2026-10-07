import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/now_provider.dart';
import '../../commute/domain/commute_profile.dart' show Leg;
import '../../commute/domain/group.dart';
import '../../commute/domain/pricing_service.dart';
import '../../daily/domain/absence.dart';
import '../../daily/domain/charge.dart';
import '../../daily/domain/daily_commute_repository.dart';
import '../../daily/domain/ride.dart';
import '../../daily/domain/trust.dart';
import '../domain/activity_entry.dart';
import '../domain/cash_mark.dart';
import '../domain/cash_trial_policy.dart';
import '../domain/fee_savings_calculator.dart';
import '../domain/payment_method.dart';
import '../domain/payment_provider.dart';
import '../domain/plan.dart';
import '../domain/wallet.dart';
import '../domain/wallet_repository.dart';
import 'wallet_seed.dart';

/// Wallet/plan on fake data over shared_preferences (contracts/repositories.md).
/// The ledger (top-ups, withdrawals, subscriptions) is this feature's own;
/// trips and 003's charges are derived from 003's records on every read
/// (research R3, R7) and priced here, so a rider's balance is the ledger
/// minus those debits.
final class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository(
    this._prefs, {
    required this._daily,
    required this._role,
    required this._now,
    required this._provider,
  });

  static const planKey = 'wallet.plan';
  static const marksKey = 'wallet.cashMarks';
  static String methodKey(String personId) => 'wallet.method.$personId';

  /// The day the rider set up payment; trips before it are not billed (003's
  /// seeded history is demo standing, not trips the rider owes for).
  static String sinceKey(String personId) => 'wallet.since.$personId';
  static String _activityKey(String ownerId) => 'wallet.activity.$ownerId';
  static String _balanceKey(String ownerId) => 'wallet.balance.$ownerId';

  /// How far back trips and charges are read (v1's activity window).
  static const _window = 60;

  final SharedPreferences _prefs;
  final DailyCommuteRepository _daily;
  final MemberRole Function() _role;
  final Now _now;
  final PaymentProvider _provider;

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
    return plan.personId == personId ? plan : null;
  }

  @override
  Future<SubscribeResult> subscribe(String personId, PlanType type, {required CalendarDate today}) async {
    if (type == PlanType.company) {
      await _markSince(personId, today);
      await _savePlan(Plan(personId: personId, type: type, status: PlanStatus.active, price: 0, startDate: today));
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
      startDate: today,
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

  static int priceFor(PlanType type) => switch (type) {
        PlanType.monthly => 129,
        PlanType.yearly => 1290,
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
    return raw == null ? null : PaymentMethod.values.byName(raw);
  }

  @override
  Future<void> setMethod(String personId, PaymentMethod method) async {
    await _markSince(personId, _now().date);
    await _prefs.setString(methodKey(personId), method.name);
  }

  Future<void> _markSince(String personId, CalendarDate date) async {
    if (!_prefs.containsKey(sinceKey(personId))) await _prefs.setString(sinceKey(personId), date.toIso());
  }

  @override
  Future<PaymentMethod?> methodOf(String riderId) async => await getMethod(riderId) ?? WalletSeed.methods[riderId];

  // ----------------------------------------------------------- cash marks

  @override
  Future<List<CashMark>> cashMarks(String rideId) async => _marks().where((m) => m.rideId == rideId).toList();

  @override
  Future<void> markCash(CashMark mark) async {
    final marks = _marks();
    if (marks.any((m) => m.rideId == mark.rideId && m.riderId == mark.riderId)) return;
    await _prefs.setString(marksKey, jsonEncode([for (final m in [...marks, mark]) m.toJson()]));
  }

  List<CashMark> _marks() {
    final raw = _prefs.getString(marksKey);
    if (raw == null) return const [];
    return [for (final m in jsonDecode(raw) as List) CashMark.fromJson((m as Map).cast<String, Object?>())];
  }

  // --------------------------------------------------------------- wallet

  @override
  Future<Wallet> getWallet(String ownerId) async {
    final today = _now().date;
    if (_role() == MemberRole.driver) {
      await _ensureDriverSeeded(ownerId);
      return Wallet(
        ownerId: ownerId,
        role: MemberRole.driver,
        balance: _ledger(ownerId),
        activity: _readActivity(ownerId),
        cashReceived: _marks()
            .where((m) => m.driverId == ownerId && m.outcome == CashOutcome.received)
            .fold(0, (sum, m) => sum + m.amount),
      );
    }
    final method = await getMethod(ownerId);
    final derived = await _riderTrips(ownerId, method, await getPlan(ownerId), today);
    final activity = [..._readActivity(ownerId), ...derived.entries]..sort((a, b) => b.date.compareTo(a.date));
    return Wallet(
      ownerId: ownerId,
      role: MemberRole.rider,
      balance: _ledger(ownerId) - derived.debits,
      activity: activity,
      method: method,
      cashTrial: method == PaymentMethod.cash ? derived.cashTrial : null,
      feesThisMonth: FeeSavingsCalculator.feesInMonth(derived.entries, today.monthKey),
    );
  }

  /// Research R8: walk the rider's completed trips and 003 charges in order.
  /// While cash is the method and the trial allows it, a trip is paid in cash
  /// (nothing moves here, no fee) and a charge is not collected; otherwise a
  /// trip costs [PricingService.riderTotal] and a charge its own amount.
  Future<_Derived> _riderTrips(String ownerId, PaymentMethod? method, Plan? plan, CalendarDate today) async {
    if (ownerId != _daily.meId) return const _Derived();
    final group = await _daily.myGroup();
    if (group == null) return const _Derived();
    final sinceRaw = _prefs.getString(sinceKey(ownerId));
    final since = sinceRaw == null ? plan?.startDate : CalendarDate.parse(sinceRaw);
    if (since == null) return const _Derived();
    final window = today.addDays(-_window);
    final from = since.isAfter(window) ? since : window;
    final marks = _marks().where((m) => m.riderId == ownerId).toList();

    final items = <_Item>[];
    for (final e in await _daily.events(from, today)) {
      if (e.kind != ReliabilityEventKind.kept) continue;
      final at = Ride.parseId(e.rideId);
      if (at == null || at.$1.isBefore(from)) continue;
      final ride = await _daily.ride(at.$1, at.$2);
      // A trip the person drove is income, not a rider trip.
      if (ride == null || ride.driverId == ownerId) continue;
      items.add(_Item(at.$1, at.$2, rideId: e.rideId));
    }
    for (final c in await _daily.chargesOwed()) {
      final at = Ride.parseId(c.rideId);
      if (at != null && !at.$1.isBefore(from)) items.add(_Item(at.$1, at.$2, rideId: c.rideId, charge: c));
    }
    items.sort((a, b) => a.compareTo(b));

    final entries = <ActivityEntry>[];
    var debits = 0;
    var cashDone = 0;
    var strikes = 0;
    for (final item in items) {
      final feeFree = plan != null && plan.coversDate(item.date);
      final inCash = method == PaymentMethod.cash && !feeFree && CashTrialPolicy.available(cashDone, strikes);
      final charge = item.charge;
      if (charge == null) {
        if (inCash) {
          cashDone++;
          strikes += marks.where((m) => m.rideId == item.rideId && m.outcome == CashOutcome.didNotPay).length;
          entries.add(ActivityEntry(
            id: 'cash:${item.rideId}',
            kind: ActivityKind.cashTrip,
            amount: 0,
            date: item.date,
            rideId: item.rideId,
          ));
        } else {
          final fee = PricingService.serviceFee(group.price, isSubscriber: feeFree, isCashTrial: false);
          debits += group.price + fee;
          entries.add(ActivityEntry(
            id: 'trip:${item.rideId}',
            kind: ActivityKind.trip,
            amount: group.price + fee,
            fee: fee,
            date: item.date,
            rideId: item.rideId,
          ));
        }
      } else {
        if (!inCash) debits += charge.amount;
        entries.add(ActivityEntry(
          id: 'charge:${charge.id}',
          kind: charge.reason == ChargeReason.lateCancel ? ActivityKind.lateCancelCharge : ActivityKind.tripDeduction,
          amount: inCash ? 0 : charge.amount,
          notCollected: inCash,
          date: item.date,
          rideId: charge.rideId,
        ));
      }
    }
    for (final absence in await _daily.absences(from, today)) {
      if (absence.personId == ownerId && absence.kind == AbsenceKind.freeCancel) {
        entries.add(ActivityEntry(
          id: 'absence:${absence.personId}:${absence.date.toIso()}:${absence.leg.name}',
          kind: ActivityKind.freeCancelZero,
          amount: 0,
          date: absence.date,
        ));
      }
    }
    return _Derived(entries: entries, debits: debits, cashTrial: CashTrialStatus(tripsDone: cashDone, strikes: strikes));
  }

  /// A driver's first-ever wallet read seeds trip income, a rider fee and one
  /// cash mark (research R11), once, so it survives later reads and a
  /// withdrawal.
  Future<void> _ensureDriverSeeded(String ownerId) async {
    if (_prefs.containsKey(_activityKey(ownerId))) return;
    final today = _now().date;
    final seed = WalletSeed.driverActivity(today);
    await _writeActivity(ownerId, seed);
    await _prefs.setInt(_balanceKey(ownerId), seed.fold(0, (sum, e) => sum + e.amount));
    await markCash(WalletSeed.driverCashMark(ownerId, today));
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

  int _ledger(String ownerId) => _prefs.getInt(_balanceKey(ownerId)) ?? 0;

  Future<void> _post(String ownerId, {required ActivityKind kind, required int amount}) async {
    await _prefs.setInt(_balanceKey(ownerId), _ledger(ownerId) + amount);
    final entry = ActivityEntry(
      id: '${kind.name}${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      amount: amount.abs(),
      date: _now().date,
    );
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
  const _Derived({this.entries = const [], this.debits = 0, this.cashTrial = const CashTrialStatus(tripsDone: 0, strikes: 0)});

  final List<ActivityEntry> entries;
  final int debits;
  final CashTrialStatus cashTrial;
}

/// One trip or charge, ordered by date then leg (going before return), a
/// charge after the trip of the same ride.
final class _Item implements Comparable<_Item> {
  _Item(this.date, this.leg, {required this.rideId, this.charge});

  final CalendarDate date;
  final Leg leg;
  final String rideId;
  final Charge? charge;

  @override
  int compareTo(_Item other) {
    final byDate = date.compareTo(other.date);
    if (byDate != 0) return byDate;
    final byLeg = leg.index.compareTo(other.leg.index);
    if (byLeg != 0) return byLeg;
    return (charge == null ? 0 : 1).compareTo(other.charge == null ? 0 : 1);
  }
}
