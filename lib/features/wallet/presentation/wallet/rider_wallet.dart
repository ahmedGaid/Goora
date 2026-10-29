import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_balance_card.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../company/domain/company_repository.dart';
import '../../../company/presentation/company_controller.dart';
import '../../domain/cash_trial_policy.dart';
import '../../domain/payment_method.dart';
import '../../domain/plan.dart';
import '../../domain/seat_price.dart';
import '../fee_owed_banner.dart';
import '../labels.dart';
import '../share_debt_banner.dart';
import 'activity_row.dart';
import 'change_plan_sheet.dart';
import 'pay_sheet.dart';
import 'top_up_sheet.dart';
import 'wallet_controller.dart';

/// A rider's debts to drivers, plan, fee-free trial, balance (Goora's money
/// only), top-up, activity and per-trip breakdown (004 v2 US2/US4, 007 US3/US4).
class RiderWallet extends StatelessWidget {
  const RiderWallet({super.key, required this.view});

  final WalletView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cash = view.wallet.cashTrial;
    final cashEnded = cash?.endedBy;
    // 008: while a bundle has trips left, Goora's fee is covered — no banner or
    // line may say a fee is due (walk S-3).
    final bundleLeft = view.subscribed ? 0 : view.wallet.bundleTripsLeft;
    final bundleCovers = bundleLeft > 0;
    final fee = bundleCovers ? 0 : view.fee;
    final gap = <Widget>[const SizedBox(height: AppSpacing.gap)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShareDebtBanners(),
        view.mode == PricingMode.company
            ? _CompanyPlanCard(view: view, bundleLeft: bundleLeft)
            : _PlanCard(view: view, bundleLeft: bundleLeft),
        if (cash != null && cash.available) ...[
          ...gap,
          _CashTrialCard(tripsLeft: cash.tripsLeft),
          if (cash.showTopUpBanner) ...[
            const SizedBox(height: AppSpacing.sm),
            GooraBanner(
              key: const Key('cash-top-up-banner'),
              kind: GooraBannerKind.info,
              title: l10n.cashTripsLeft(cash.tripsLeft),
              body: l10n.cashTopUpBanner,
              actionLabel: l10n.subscribe,
              onAction: () => context.push(Routes.plan),
            ),
          ],
        ],
        if (cashEnded != null && !view.subscribed && !bundleCovers) ...[
          ...gap,
          GooraBanner(
            key: const Key('cash-ended'),
            kind: GooraBannerKind.info,
            title: l10n.cashTripsLeft(0),
            body: cashEnded == CashTrialEnd.strikes ? l10n.cashOff : l10n.cashEnded,
            actionLabel: l10n.subscribe,
            onAction: () => context.push(Routes.plan),
          ),
        ],
        if (view.owesGoora) ...[...gap, const FeeOwedBanner()],
        if (!view.subscribed) ...[...gap, _BundleCard(tripsLeft: view.wallet.bundleTripsLeft)],
        if (view.showSavings && !bundleCovers) ...[
          ...gap,
          GooraBanner(
            key: const Key('fee-savings'),
            kind: GooraBannerKind.info,
            title: l10n.subscribeLink,
            body: l10n.feeSavings(view.wallet.feesThisMonth),
            actionLabel: l10n.subscribe,
            onAction: () => context.push(Routes.plan),
          ),
        ],
        ...gap,
        GooraBalanceCard(
          balanceLabel: l10n.balanceLabel,
          balanceValue: l10n.egpAmount(view.wallet.balance),
          tripsCaption: l10n.coversTrips(view.tripsCovered),
          topUpLabel: l10n.topUp,
          onTopUp: () => showTopUpSheet(context),
        ),
        ...gap,
        GooraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.howPayTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              for (final rule in [
                view.mode == PricingMode.company ? l10n.howPayRule1Company : l10n.howPayRule1,
                l10n.howPayRule2,
                l10n.howPayRule3,
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(GooraIcons.check, size: 18, color: AppColors.greenText),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(rule, style: AppTypography.body.copyWith(color: AppColors.textBody)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        ...gap,
        Text(l10n.activityTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        if (view.wallet.activity.isEmpty)
          GooraCard(
            child: Text(l10n.activityEmpty, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          )
        else
          GooraCard.rows(
            key: const Key('activity-list'),
            rows: [for (final e in view.wallet.activity) ActivityRow(entry: e, contribution: view.legShare)],
          ),
        ...gap,
        GooraCard(
          key: const Key('breakdown'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.breakdownTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              _BreakdownRow(label: l10n.breakdownShare, value: l10n.egpAmount(view.share)),
              const SizedBox(height: AppSpacing.xs),
              fee > 0
                  ? _BreakdownRow(label: l10n.breakdownFee, value: l10n.egpAmount(fee))
                  : _BreakdownRow(label: l10n.breakdownNoFee, value: null),
              const Padding(
                padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              _BreakdownRow(label: l10n.breakdownTotal, value: l10n.egpAmount(view.share + fee), strong: true),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pay per trip / Subscribed until … / Company, with Change (v2 US2 AC5).
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.view, required this.bundleLeft});

  final WalletView view;

  /// Bundle trips left; > 0 means the bundle covers Goora's fee right now.
  final int bundleLeft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plan = view.plan;
    final (String title, String line) = switch (view.mode) {
      PricingMode.company => (l10n.planTypeTitle(PlanType.company), l10n.planCompanyActive),
      PricingMode.subscribed => (
        l10n.planTypeTitle(plan!.type),
        l10n.planSubscribedLine(l10n.shortDate(plan.untilDate!)),
      ),
      PricingMode.trial => (
        l10n.planPayPerTrip,
        view.riderSeats < 1
            ? l10n.priceCash(view.legShare)
            : l10n.priceLine(
                SeatPrice.of(
                  view.legShare,
                  tripCost: view.groupTripCost,
                  riderSeats: view.riderSeats,
                  mode: PricingMode.trial,
                  method: view.method,
                ),
              ),
      ),
      PricingMode.perTrip => (
        l10n.planPayPerTrip,
        view.lapsed
            ? l10n.planLapsedLine
            : bundleLeft > 0
            ? l10n.planBundleLine(bundleLeft)
            : (view.fee == 0 ? l10n.planPerTripNoFeeLine : l10n.planPerTripLine(view.fee)),
      ),
    };
    return GooraCard(
      key: const Key('plan-card'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  line,
                  key: const Key('plan-line'),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('plan-change'),
            onPressed: () =>
                view.subscribed ? showChangePlanSheet(context, current: plan!.type) : context.push(Routes.plan),
            child: Text(l10n.planChange, style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
          ),
        ],
      ),
    );
  }
}

/// 010 US2: an enrolled employee's plan — "Company · Valeo", the personal
/// plan their enrollment paused, and Leave (confirmed). A company plan with no
/// enrollment behind it (before 010) keeps the plain [_PlanCard].
class _CompanyPlanCard extends ConsumerWidget {
  const _CompanyPlanCard({required this.view, required this.bundleLeft});

  final WalletView view;
  final int bundleLeft;

  Future<void> _leave(BuildContext context, WidgetRef ref, String company) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.companyLeaveTitle(company)),
        content: Text(l10n.companyLeaveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.keepIt)),
          TextButton(
            key: const Key('company-leave-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.companyLeaveConfirm),
          ),
        ],
      ),
    );
    if (ok == true) await CompanyEnrollment.leave(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(companyAccountProvider).value;
    final offer = account?.offer;
    if (offer is! Enrolled) return _PlanCard(view: view, bundleLeft: bundleLeft);
    final l10n = AppLocalizations.of(context);
    final paused = account!.paused;
    final secondary = AppTypography.bodySmall.copyWith(color: AppColors.textSecondary);
    return GooraCard(
      key: const Key('plan-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(GooraIcons.company, size: AppSizes.icon, color: AppColors.greenText),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.planCompanyOf(offer.companyName),
                  style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.planCompanyActive, key: const Key('plan-line'), style: secondary),
          if (paused != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(l10n.planCompanyPaused(paused.daysLeft), key: const Key('plan-paused'), style: secondary),
          ],
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            key: const Key('company-leave'),
            onPressed: () => _leave(context, ref, offer.companyName),
            child: Text(l10n.companyLeave, style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
          ),
        ],
      ),
    );
  }
}

/// 008 US4: the 20-trip bundle — what is left, or what it is, and Buy.
class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.tripsLeft});

  final int tripsLeft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GooraCard(
      key: const Key('bundle-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.bundleTitle, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            tripsLeft > 0 ? l10n.bundleLeft(tripsLeft) : l10n.bundleSub,
            key: const Key('bundle-line'),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          GooraGhostButton(
            key: const Key('bundle-buy'),
            label: l10n.bundleBuy,
            onPressed: () => showPaySheet(context, PayPurpose.bundle),
          ),
        ],
      ),
    );
  }
}

class _CashTrialCard extends StatelessWidget {
  const _CashTrialCard({required this.tripsLeft});

  final int tripsLeft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GooraCard(
      key: const Key('cash-trial'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.cashTripsLeft(tripsLeft), style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.payCashSub, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.value, this.strong = false});

  final String label;
  final String? value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = (strong ? AppTypography.bodyStrong : AppTypography.body).copyWith(color: AppColors.textPrimary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        if (value != null) Text(value!, style: style),
      ],
    );
  }
}
