import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart' show Leg;
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/charge.dart';
import 'package:goora/features/daily/domain/daily_commute_repository.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/domain/payment_provider.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

final today = CalendarDate(2026, 10, 8);

/// Minimal stand-in for 003's repository: only `meId`, `chargesOwed` and
/// `absences` are exercised by the wallet repository (research R3).
final class _StubDailyRepo implements DailyCommuteRepository {
  _StubDailyRepo({this.charges = const [], this.absences_ = const []});

  final List<Charge> charges;
  final List<Absence> absences_;

  @override
  String get meId => 'me';

  @override
  Future<List<Charge>> chargesOwed() async => charges;

  @override
  Future<List<Absence>> absences(CalendarDate from, CalendarDate to) async => absences_;

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName} not stubbed');
}

final class _AlwaysFail implements PaymentProvider {
  const _AlwaysFail();

  @override
  Future<PaymentResult> topUp({required String method, required int amount}) async => PaymentResult.failure;

  @override
  Future<PaymentResult> withdraw({required int amount}) async => PaymentResult.failure;
}

final class _AlwaysSucceed implements PaymentProvider {
  const _AlwaysSucceed();

  @override
  Future<PaymentResult> topUp({required String method, required int amount}) async => PaymentResult.success;

  @override
  Future<PaymentResult> withdraw({required int amount}) async => PaymentResult.success;
}

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

FakeWalletRepository _repo(
  SharedPreferences prefs, {
  DailyCommuteRepository? daily,
  PaymentProvider? provider,
  MemberRole role = MemberRole.rider,
}) =>
    FakeWalletRepository(
      prefs,
      daily: daily ?? _StubDailyRepo(),
      role: () => role,
      now: () => WallTime(today, const Clock.hm(9, 0)),
      provider: provider ?? const _AlwaysSucceed(),
    );

void main() {
  test('choosePlan(monthly) sets trialing + untilDate = today.addMonths(1)', () async {
    final repo = _repo(await _prefs());
    final plan = await repo.choosePlan('me', PlanType.monthly, today: today);
    expect(plan.status, PlanStatus.trialing);
    expect(plan.price, 129);
    expect(plan.untilDate, today.addMonths(1));
  });

  test('choosePlan(yearly) sets trialing + the yearly price', () async {
    final repo = _repo(await _prefs());
    final plan = await repo.choosePlan('me', PlanType.yearly, today: today);
    expect(plan.status, PlanStatus.trialing);
    expect(plan.price, 1290);
    expect(plan.untilDate, today.addMonths(1));
  });

  test('choosePlan(company) sets active, free, no trial date', () async {
    final repo = _repo(await _prefs());
    final plan = await repo.choosePlan('me', PlanType.company, today: today);
    expect(plan.status, PlanStatus.active);
    expect(plan.price, 0);
    expect(plan.untilDate, isNull);
  });

  test("changePlan doesn't affect the current period", () async {
    final repo = _repo(await _prefs());
    final original = await repo.choosePlan('me', PlanType.monthly, today: today);
    final changed = await repo.changePlan('me', PlanType.yearly);
    expect(changed.untilDate, original.untilDate, reason: 'FR-004: no pro-rating');
    expect(changed.price, 1290);
  });

  test('topUp success updates balance and adds a row', () async {
    final repo = _repo(await _prefs());
    final result = await repo.topUp('me', method: 'card', amount: 200);
    expect(result, PaymentResult.success);
    final wallet = await repo.getWallet('me');
    expect(wallet.balance, 200);
    expect(wallet.activity.single.kind, ActivityKind.topUp);
    expect(wallet.activity.single.amount, 200);
  });

  test('withdraw success updates balance and adds a row', () async {
    final repo = _repo(await _prefs(), role: MemberRole.driver);
    await repo.topUp('me', method: 'card', amount: 300);
    final result = await repo.withdraw('me', amount: 100);
    expect(result, PaymentResult.success);
    final wallet = await repo.getWallet('me');
    expect(wallet.balance, 200);
    expect(wallet.activity.first.kind, ActivityKind.withdrawal);
  });

  test('topUp/withdraw failure (SC-005) changes neither balance nor activity', () async {
    final repo = _repo(await _prefs(), provider: const _AlwaysFail());
    final before = await repo.getWallet('me');
    final topUpResult = await repo.topUp('me', method: 'card', amount: 200);
    final withdrawResult = await repo.withdraw('me', amount: 50);
    final after = await repo.getWallet('me');
    expect(topUpResult, PaymentResult.failure);
    expect(withdrawResult, PaymentResult.failure);
    expect(after.balance, before.balance);
    expect(after.activity, isEmpty);
  });

  test("getWallet includes 003's seeded Charge rows", () async {
    final charge = Charge(
      id: 'c1',
      personId: 'me',
      rideId: Ride.idFor('sz-0725', today, Leg.going),
      reason: ChargeReason.lateCancel,
      amount: 20,
      owedTo: 'ahmed',
    );
    final repo = _repo(await _prefs(), daily: _StubDailyRepo(charges: [charge]));
    final wallet = await repo.getWallet('me');
    expect(wallet.activity.single.kind, ActivityKind.lateCancelCharge);
    expect(wallet.activity.single.amount, 20);
    expect(wallet.activity.single.rideId, charge.rideId);
  });

  test("getWallet includes 003's seeded free-cancel (zero-amount) rows", () async {
    final absence = Absence(
      personId: 'me',
      date: today,
      leg: Leg.going,
      madeAt: WallTime(today, const Clock.hm(18, 0)),
      kind: AbsenceKind.freeCancel,
    );
    final repo = _repo(await _prefs(), daily: _StubDailyRepo(absences_: [absence]));
    final wallet = await repo.getWallet('me');
    expect(wallet.activity.single.kind, ActivityKind.freeCancelZero);
    expect(wallet.activity.single.amount, 0);
  });
}
