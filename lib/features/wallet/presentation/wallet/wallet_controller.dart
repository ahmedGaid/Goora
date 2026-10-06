import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/calendar_date.dart';
import '../../../../core/time/now_provider.dart';
import '../../../commute/domain/group.dart';
import '../../../daily/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/payment_provider.dart';
import '../../domain/plan.dart';
import '../../domain/wallet.dart';
import '../../domain/wallet_rules.dart';

part 'wallet_controller.g.dart';

/// Everything the Wallet tab shows, rider or driver.
final class WalletView {
  const WalletView({
    required this.role,
    required this.wallet,
    required this.today,
    this.plan,
    this.legShare = 0,
    this.capacitySeats = 0,
    this.filledSeats = 0,
  });

  final MemberRole role;
  final Wallet wallet;
  final CalendarDate today;

  /// Rider only; null for drivers (they have no [Plan]).
  final Plan? plan;

  /// `CommuteGroup.price` — EGP per rider per leg.
  final int legShare;

  /// Driver only: seats in the car for one leg (filled riders + free seats).
  final int capacitySeats;

  /// Driver only: riders actually in the car for one leg.
  final int filledSeats;

  int get tripsCovered => WalletRules.tripsCovered(wallet.balance, legShare);

  /// Fuel & tolls share for one round-trip day (US2's "What you pay per
  /// trip" breakdown).
  int get roundTripShare => legShare * 2;

  bool get planDue => plan != null && WalletRules.isPlanDue(plan!, today);

  /// Driver only (US3): what a full round-trip day would cost at capacity.
  int get tripCost => legShare * capacitySeats * 2;

  /// Driver only (US3): what the driver actually received from riders for a
  /// round-trip day, at the car's current occupancy.
  int get receivedFromRiders => legShare * filledSeats * 2;

  /// Driver only (US3): the gap the driver covers themselves — e.g. an
  /// empty seat (AC3); zero on a full car.
  int get driverGap => tripCost - receivedFromRiders;
}

@riverpod
class WalletController extends _$WalletController {
  @override
  Future<WalletView> build() async {
    final daily = ref.watch(dailyCommuteRepositoryProvider);
    final meId = daily.meId;
    final today = ref.watch(nowProvider)().date;
    final repo = ref.watch(walletRepositoryProvider);
    final wallet = await repo.getWallet(meId);
    final group = await daily.myGroup();
    final isRider = wallet.role == MemberRole.rider;
    return WalletView(
      role: wallet.role,
      wallet: wallet,
      today: today,
      plan: isRider ? await repo.getPlan(meId) : null,
      legShare: group?.price ?? 0,
      capacitySeats: (group?.riders.length ?? 0) + (group?.freeSeatsGoing ?? 0),
      filledSeats: group?.riders.length ?? 0,
    );
  }

  Future<PaymentResult> topUp({required String method, required int amount}) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final result = await ref.read(walletRepositoryProvider).topUp(meId, method: method, amount: amount);
    if (result == PaymentResult.success) {
      ref.invalidateSelf();
      await future;
    }
    return result;
  }

  /// FR-010: resets the driver's recoverable balance; a failure leaves
  /// balance/activity untouched.
  Future<PaymentResult> withdraw({required int amount}) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final result = await ref.read(walletRepositoryProvider).withdraw(meId, amount: amount);
    if (result == PaymentResult.success) {
      ref.invalidateSelf();
      await future;
    }
    return result;
  }

  /// FR-004: takes effect at the next billing date, no pro-rating.
  Future<void> changePlan(PlanType type) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    await ref.read(walletRepositoryProvider).changePlan(meId, type);
    ref.invalidateSelf();
    await future;
  }
}
