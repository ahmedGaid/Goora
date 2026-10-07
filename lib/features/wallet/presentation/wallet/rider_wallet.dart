import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_balance_card.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../domain/cash_trial_policy.dart';
import '../../domain/payment_method.dart';
import '../../domain/plan.dart';
import '../labels.dart';
import 'activity_row.dart';
import 'change_plan_sheet.dart';
import 'top_up_sheet.dart';
import 'wallet_controller.dart';

/// A rider's plan, cash trial, balance, top-up, activity and per-trip
/// breakdown (v2 US2/US4).
class RiderWallet extends StatelessWidget {
  const RiderWallet({super.key, required this.view});

  final WalletView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cash = view.wallet.cashTrial;
    final cashEnded = cash?.endedBy;
    final gap = <Widget>[const SizedBox(height: AppSpacing.gap)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlanCard(view: view),
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
              actionLabel: l10n.topUp,
              onAction: () => showTopUpSheet(context),
            ),
          ],
        ],
        if (cashEnded != null && !view.subscribed) ...[
          ...gap,
          GooraBanner(
            key: const Key('cash-ended'),
            kind: GooraBannerKind.warning,
            title: l10n.needsTopUp,
            body: cashEnded == CashTrialEnd.strikes ? l10n.cashOff : l10n.cashEnded,
            actionLabel: l10n.topUp,
            onAction: () => showTopUpSheet(context),
          ),
        ] else if (view.needsTopUp) ...[
          ...gap,
          GooraBanner(
            key: const Key('needs-top-up'),
            kind: GooraBannerKind.warning,
            title: l10n.needsTopUp,
            body: l10n.needsTopUpBody(view.legTotal),
            actionLabel: l10n.topUp,
            onAction: () => showTopUpSheet(context),
          ),
        ],
        if (view.showSavings) ...[
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
              for (final rule in [l10n.howPayRule1, l10n.howPayRule2, l10n.howPayRule3])
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(GooraIcons.check, size: 18, color: AppColors.greenText),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(rule, style: AppTypography.body.copyWith(color: AppColors.textBody))),
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
          GooraCard(child: Text(l10n.activityEmpty, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)))
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
              _BreakdownRow(label: l10n.breakdownShare, value: l10n.egpAmount(view.legShare)),
              const SizedBox(height: AppSpacing.xs),
              view.fee > 0
                  ? _BreakdownRow(label: l10n.breakdownFee, value: l10n.egpAmount(view.fee))
                  : _BreakdownRow(label: l10n.breakdownNoFee, value: null),
              const Padding(
                padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              _BreakdownRow(label: l10n.breakdownTotal, value: l10n.egpAmount(view.legTotal), strong: true),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pay per trip / Subscribed until … / Company, with Change (v2 US2 AC5).
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.view});

  final WalletView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plan = view.plan;
    final (String title, String line) = switch (view.mode) {
      PricingMode.company => (l10n.planTypeTitle(PlanType.company), l10n.planCompanyActive),
      PricingMode.subscribed => (l10n.planTypeTitle(plan!.type), l10n.planSubscribedLine(l10n.shortDate(plan.untilDate!))),
      PricingMode.cash => (l10n.planPayPerTrip, l10n.priceCash(view.legShare)),
      PricingMode.wallet => (l10n.planPayPerTrip, view.lapsed ? l10n.planLapsedLine : l10n.planPerTripLine(view.fee)),
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
                Text(line, key: const Key('plan-line'), style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(
            key: const Key('plan-change'),
            onPressed: () => view.subscribed
                ? showChangePlanSheet(context, current: plan!.type)
                : context.push(Routes.plan),
            child: Text(l10n.planChange, style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
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
