import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/calendar_date.dart';
import '../../../../core/time/now_provider.dart';
import '../../../commute/domain/group.dart';
import '../../../commute/domain/pricing_service.dart';
import '../../../daily/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/fee_savings_calculator.dart';
import '../../domain/payment_method.dart';
import '../../domain/payment_provider.dart';
import '../../domain/plan.dart';
import '../../domain/wallet.dart';
import '../../domain/wallet_repository.dart';
import '../../domain/wallet_rules.dart';

part 'wallet_controller.g.dart';

/// Everything the Wallet tab shows, rider or driver.
final class WalletView {
  const WalletView({
    required this.role,
    required this.wallet,
    required this.today,
    this.plan,
    this.mode = PricingMode.wallet,
    this.legShare = 0,
    this.capacitySeats = 0,
    this.filledSeats = 0,
  });

  final MemberRole role;
  final Wallet wallet;
  final CalendarDate today;

  /// Rider only; null for drivers and for pay-per-trip riders.
  final Plan? plan;

  /// Rider only: which price they pay right now.
  final PricingMode mode;

  /// `CommuteGroup.price` — the contribution, EGP per rider per trip (leg).
  final int legShare;

  /// Driver only: seats in the car for one leg (filled riders + free seats).
  final int capacitySeats;

  /// Driver only: riders actually in the car for one leg.
  final int filledSeats;

  /// The service fee on one trip for this rider now (0 unless paying per trip
  /// from the wallet).
  int get fee => PricingService.serviceFee(
        legShare,
        isSubscriber: mode == PricingMode.subscribed || mode == PricingMode.company,
        isCashTrial: mode == PricingMode.cash,
      );

  /// What one trip costs this rider: 44, or 40 fee-free.
  int get legTotal => legShare + fee;

  int get tripsCovered => legTotal == 0 ? 0 : WalletRules.tripsCovered(wallet.balance, legTotal);

  /// The subscription that is paying for trips today, if any.
  bool get subscribed => mode == PricingMode.subscribed || mode == PricingMode.company;

  /// A monthly/yearly plan whose paid period is over.
  bool get lapsed => plan != null && plan!.type != PlanType.company && !plan!.coversDate(today);

  bool get showSavings => FeeSavingsCalculator.shouldUpsell(wallet.feesThisMonth, isFeeFree: mode.isFeeFree);

  /// "After 10 cash trips, booking requires a wallet balance (or a company
  /// plan)" — shown, not enforced, in this feature (spec clarification).
  bool get needsTopUp =>
      (mode == PricingMode.wallet || mode == PricingMode.subscribed) && legTotal > 0 && wallet.balance < legTotal;

  /// Driver only: what a full round-trip day would cost at capacity.
  int get tripCost => legShare * capacitySeats * 2;

  /// Driver only: what the driver received from riders for a round-trip day.
  int get receivedFromRiders => legShare * filledSeats * 2;

  /// Driver only: the gap the driver covers themselves — e.g. an empty seat.
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
    final plan = isRider ? await repo.getPlan(meId) : null;
    return WalletView(
      role: wallet.role,
      wallet: wallet,
      today: today,
      plan: plan,
      mode: PricingMode.of(
        method: wallet.method,
        plan: plan,
        today: today,
        cashAvailable: wallet.cashTrial?.available ?? false,
      ),
      legShare: group?.price ?? 0,
      capacitySeats: (group?.riders.length ?? 0) + (group?.freeSeatsGoing ?? 0),
      filledSeats: group?.riders.length ?? 0,
    );
  }

  Future<PaymentResult> topUp({required String method, required int amount}) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final result = await ref.read(walletRepositoryProvider).topUp(meId, method: method, amount: amount);
    if (result == PaymentResult.success) await _refresh();
    return result;
  }

  /// Resets the driver's recoverable balance; a failure leaves balance/
  /// activity untouched. Cash received is never part of it.
  Future<PaymentResult> withdraw({required int amount}) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final result = await ref.read(walletRepositoryProvider).withdraw(meId, amount: amount);
    if (result == PaymentResult.success) await _refresh();
    return result;
  }

  /// Takes effect at the next billing date, no pro-rating.
  Future<void> changePlan(PlanType type) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    await ref.read(walletRepositoryProvider).changePlan(meId, type);
    await _refresh();
  }

  Future<SubscribeResult> subscribe(PlanType type) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final today = ref.read(nowProvider)().date;
    final result = await ref.read(walletRepositoryProvider).subscribe(meId, type, today: today);
    if (result == SubscribeResult.subscribed) await _refresh();
    return result;
  }

  Future<void> _refresh() async {
    ref.invalidate(riderPricingProvider);
    ref.invalidateSelf();
    await future;
  }
}
