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

/// Everything the Wallet tab shows, rider or driver (US2 rider fields now;
/// US3 extends this with driver-only fields — T034).
final class WalletView {
  const WalletView({required this.role, required this.wallet, required this.today, this.plan, this.legShare = 0});

  final MemberRole role;
  final Wallet wallet;
  final CalendarDate today;

  /// Rider only; null for drivers (they have no [Plan]).
  final Plan? plan;

  /// `CommuteGroup.price` — EGP per rider per leg.
  final int legShare;

  int get tripsCovered => WalletRules.tripsCovered(wallet.balance, legShare);

  /// Fuel & tolls share for one round-trip day (US2's "What you pay per
  /// trip" breakdown).
  int get roundTripShare => legShare * 2;

  bool get planDue => plan != null && WalletRules.isPlanDue(plan!, today);
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

  /// FR-004: takes effect at the next billing date, no pro-rating.
  Future<void> changePlan(PlanType type) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    await ref.read(walletRepositoryProvider).changePlan(meId, type);
    ref.invalidateSelf();
    await future;
  }
}
