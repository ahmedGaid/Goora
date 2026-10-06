import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/now_provider.dart';
import '../../commute/domain/group.dart';
import '../../daily/domain/absence.dart';
import '../../daily/domain/charge.dart';
import '../../daily/domain/daily_commute_repository.dart';
import '../../daily/domain/ride.dart';
import '../domain/activity_entry.dart';
import '../domain/payment_provider.dart';
import '../domain/plan.dart';
import '../domain/wallet.dart';
import '../domain/wallet_repository.dart';
import '../domain/wallet_rules.dart';
import 'wallet_seed.dart';

/// Wallet/plan on fake data over shared_preferences (contracts/repositories.md).
/// Balances and this feature's own activity (top-up, withdrawal, fee
/// received) are this feature's source of truth (FR-013); 003's `Charge`/
/// `Absence` records stay 003's source of truth for *why* a charge happened
/// and are read here, not duplicated (research R3).
final class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository(
    this._prefs, {
    required this._daily,
    required this._role,
    required this._now,
    required this._provider,
  });

  static const planKey = 'wallet.plan';
  static String _activityKey(String ownerId) => 'wallet.activity.$ownerId';
  static String _balanceKey(String ownerId) => 'wallet.balance.$ownerId';

  final SharedPreferences _prefs;
  final DailyCommuteRepository _daily;
  final MemberRole Function() _role;
  final Now _now;
  final PaymentProvider _provider;

  @override
  Future<Plan?> getPlan(String personId) async {
    final raw = _prefs.getString(planKey);
    if (raw == null) return null;
    final plan = Plan.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    return plan.personId == personId ? plan : null;
  }

  @override
  Future<Plan> choosePlan(String personId, PlanType type, {required CalendarDate today}) =>
      _savePlan(_newPlan(personId, type, today));

  @override
  Future<Plan> changePlan(String personId, PlanType newType) async {
    final current = await getPlan(personId);
    final price = _priceFor(newType);
    final plan = Plan(
      personId: personId,
      type: newType,
      status: current?.status ?? PlanStatus.active,
      price: price,
      untilDate: newType == PlanType.company ? null : current?.untilDate,
    );
    return _savePlan(plan);
  }

  Plan _newPlan(String personId, PlanType type, CalendarDate today) => switch (type) {
        PlanType.company => Plan(personId: personId, type: type, status: PlanStatus.active, price: 0),
        PlanType.monthly || PlanType.yearly => Plan(
            personId: personId,
            type: type,
            status: PlanStatus.trialing,
            price: _priceFor(type),
            untilDate: WalletRules.trialEndDate(today),
          ),
      };

  int _priceFor(PlanType type) => switch (type) {
        PlanType.monthly => 129,
        PlanType.yearly => 1290,
        PlanType.company => 0,
      };

  Future<Plan> _savePlan(Plan plan) async {
    await _prefs.setString(planKey, jsonEncode(plan.toJson()));
    return plan;
  }

  @override
  Future<Wallet> getWallet(String ownerId) async {
    await _ensureDriverSeeded(ownerId);
    final own = _readActivity(ownerId);
    final merged = [...own, ...await _dailyActivity(ownerId)]..sort((a, b) => b.date.compareTo(a.date));
    return Wallet(
      ownerId: ownerId,
      role: _role(),
      balance: _prefs.getInt(_balanceKey(ownerId)) ?? 0,
      activity: merged,
    );
  }

  /// US3/quickstart Scenario 3: a driver's first-ever wallet read seeds
  /// trip income + a rider fee (research R3 spirit — demo data without
  /// replaying 003's flows live), once, so it persists across reads and
  /// survives a withdrawal leaving the rows in place.
  Future<void> _ensureDriverSeeded(String ownerId) async {
    if (_role() != MemberRole.driver) return;
    if (_prefs.containsKey(_activityKey(ownerId))) return;
    final seed = WalletSeed.driverActivity(_now().date);
    await _writeActivity(ownerId, seed);
    await _prefs.setInt(_balanceKey(ownerId), seed.fold(0, (sum, e) => sum + e.amount));
  }

  Future<List<ActivityEntry>> _dailyActivity(String ownerId) async {
    if (ownerId != _daily.meId) return const [];
    final today = _now().date;
    final entries = <ActivityEntry>[
      for (final charge in await _daily.chargesOwed())
        ActivityEntry(
          id: 'charge:${charge.id}',
          kind: charge.reason == ChargeReason.lateCancel ? ActivityKind.lateCancelCharge : ActivityKind.tripDeduction,
          amount: charge.amount,
          date: Ride.parseId(charge.rideId)?.$1 ?? today,
          rideId: charge.rideId,
        ),
      for (final absence in await _daily.absences(today.addDays(-60), today))
        if (absence.personId == _daily.meId && absence.kind == AbsenceKind.freeCancel)
          ActivityEntry(
            id: 'absence:${absence.personId}:${absence.date.toIso()}:${absence.leg.name}',
            kind: ActivityKind.freeCancelZero,
            amount: 0,
            date: absence.date,
          ),
    ];
    return entries;
  }

  @override
  Future<PaymentResult> topUp(String ownerId, {required String method, required int amount}) async {
    final result = await _provider.topUp(method: method, amount: amount);
    return _settle(ownerId, amount: amount, kind: ActivityKind.topUp, result: result);
  }

  @override
  Future<PaymentResult> withdraw(String ownerId, {required int amount}) async {
    final result = await _provider.withdraw(amount: amount);
    return _settle(ownerId, amount: -amount, kind: ActivityKind.withdrawal, result: result);
  }

  Future<PaymentResult> _settle(
    String ownerId, {
    required int amount,
    required ActivityKind kind,
    required PaymentResult result,
  }) async {
    if (result == PaymentResult.failure) return result;
    final balance = (_prefs.getInt(_balanceKey(ownerId)) ?? 0) + amount;
    await _prefs.setInt(_balanceKey(ownerId), balance);
    final entry = ActivityEntry(
      id: '${kind.name}${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      amount: amount.abs(),
      date: _now().date,
    );
    await _writeActivity(ownerId, [entry, ..._readActivity(ownerId)]);
    return result;
  }

  List<ActivityEntry> _readActivity(String ownerId) {
    final raw = _prefs.getString(_activityKey(ownerId));
    if (raw == null) return const [];
    return [for (final e in jsonDecode(raw) as List) ActivityEntry.fromJson((e as Map).cast<String, Object?>())];
  }

  Future<void> _writeActivity(String ownerId, List<ActivityEntry> items) =>
      _prefs.setString(_activityKey(ownerId), jsonEncode([for (final i in items) i.toJson()]));
}
