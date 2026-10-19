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
import '../../domain/seat_price.dart';
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
    this.mode = PricingMode.perTrip,
    this.method = PaymentMethod.cash,
    this.legShare = 0,
    this.capacitySeats = 0,
    this.filledSeats = 0,
    this.groupTripCost = 0,
    this.riderSeats = 0,
    this.hasGroup = true,
  });

  /// The corridor's standard trip (160 EGP a leg, 3 rider seats → 40 + a 4
  /// EGP fee): the price basis for someone with no group yet, so a once
  /// rider's wallet quotes real numbers instead of zeros (005 T104 F3).
  static const standardTripCost = 160;
  static const standardRiderSeats = 3;
  static final standardLegShare = PricingService.suggested(standardTripCost, standardRiderSeats);

  final MemberRole role;
  final Wallet wallet;
  final CalendarDate today;

  /// Rider only; null for drivers and for pay-per-trip riders.
  final Plan? plan;

  /// Rider only: which price they pay right now.
  final PricingMode mode;

  /// Rider only: how they pay the driver (cash / InstaPay).
  final PaymentMethod method;

  /// `CommuteGroup.price` — the contribution, EGP per rider per trip (leg).
  final int legShare;

  /// Driver only: seats in the car for one leg (filled riders + free seats).
  final int capacitySeats;

  /// Driver only: riders actually in the car for one leg.
  final int filledSeats;

  /// `CommuteGroup.tripCost` — the full trip cost for one leg.
  final int groupTripCost;

  /// `CommuteGroup.riderSeats`.
  final int riderSeats;

  /// False for a person with no group (Just one trip): the prices above are
  /// then the standard corridor basis, and the per-group parts of the
  /// driver's wallet do not apply.
  final bool hasGroup;

  /// One trip for this rider now: the share to the driver and Goora's fee.
  ///
  /// Needs at least one rider seat; the controller always supplies one (the
  /// standard corridor basis when there is no group).
  SeatPrice? get _price => riderSeats < 1
      ? null
      : SeatPrice.of(legShare, tripCost: groupTripCost, riderSeats: riderSeats, mode: mode, method: method);

  /// What the rider hands the driver directly for one trip (007 FR-001).
  int get share => _price?.share ?? legShare;

  /// Goora's service fee on one trip for this rider now (0 unless paying per
  /// trip).
  int get fee => _price?.fee ?? 0;

  /// What one trip costs this rider in all: 44, or 40 fee-free.
  int get legTotal => share + fee;

  /// How many round-trip days of Goora's fees the balance covers (007 R5:
  /// the balance never pays the driver's share).
  int get tripsCovered => fee == 0 ? 0 : WalletRules.tripsCovered(wallet.balance, fee);

  /// The subscription that is paying for trips today, if any.
  bool get subscribed => mode == PricingMode.subscribed || mode == PricingMode.company;

  /// A monthly/yearly plan whose paid period is over.
  bool get lapsed => plan != null && plan!.type != PlanType.company && !plan!.coversDate(today);

  bool get showSavings => FeeSavingsCalculator.shouldUpsell(wallet.feesThisMonth, isFeeFree: mode.isFeeFree);

  /// Goora's fees went past the balance (007 FR-009): owed, shown, never a
  /// block here (the settle and overdue rules are 008's).
  bool get owesGoora => wallet.balance < 0;

  /// Driver only: what a full round-trip day would cost at capacity.
  int get dayTripCost => groupTripCost * 2;

  /// Driver only: what the driver received from riders for a round-trip day.
  int get receivedFromRiders => legShare * filledSeats * 2;

  /// Driver only: the gap the driver covers themselves — e.g. an empty seat.
  int get driverGap => dayTripCost - receivedFromRiders;
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
        plan: plan,
        today: today,
        trialAvailable: wallet.cashTrial?.available ?? false,
      ),
      method: wallet.method ?? PaymentMethod.cash,
      legShare: group?.price ?? WalletView.standardLegShare,
      capacitySeats: (group?.riders.length ?? 0) + (group?.freeSeatsGoing ?? 0),
      filledSeats: group?.riders.length ?? 0,
      groupTripCost: group?.tripCost ?? WalletView.standardTripCost,
      riderSeats: group?.riderSeats ?? WalletView.standardRiderSeats,
      hasGroup: group != null,
    );
  }

  Future<PaymentResult> topUp({required String method, required int amount}) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final result = await ref.read(walletRepositoryProvider).topUp(meId, method: method, amount: amount);
    if (result == PaymentResult.success) await _refresh();
    return result;
  }

  /// Takes money out of the balance; a failure leaves balance/activity
  /// untouched. Shares paid to a driver are never part of it.
  Future<PaymentResult> withdraw({required int amount}) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final result = await ref.read(walletRepositoryProvider).withdraw(meId, amount: amount);
    if (result == PaymentResult.success) await _refresh();
    return result;
  }

  /// 008 FR-003: everything owed to Goora, one transaction.
  Future<PaymentResult> settle({required String method}) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final result = await ref.read(walletRepositoryProvider).settle(meId, method: method);
    if (result == PaymentResult.success) await _refresh();
    return result;
  }

  /// 008 FR-007: 20 trips for 75, never touching the balance.
  Future<PaymentResult> buyBundle({required String method}) async {
    final meId = ref.read(dailyCommuteRepositoryProvider).meId;
    final result = await ref.read(walletRepositoryProvider).buyBundle(meId, method: method);
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
