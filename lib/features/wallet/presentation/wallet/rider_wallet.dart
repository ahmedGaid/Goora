import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_balance_card.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../domain/plan.dart';
import '../labels.dart';
import 'activity_row.dart';
import 'change_plan_sheet.dart';
import 'top_up_sheet.dart';
import 'wallet_controller.dart';

/// US2: a rider's plan, balance, top-up, activity and per-trip breakdown.
class RiderWallet extends StatelessWidget {
  const RiderWallet({super.key, required this.view});

  final WalletView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plan = view.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (plan != null) _PlanCard(plan: plan, due: view.planDue),
        const SizedBox(height: AppSpacing.gap),
        GooraBalanceCard(
          balanceLabel: l10n.balanceLabel,
          balanceValue: l10n.egpAmount(view.wallet.balance),
          tripsCaption: l10n.coversTrips(view.tripsCovered),
          topUpLabel: l10n.topUp,
          onTopUp: () => showTopUpSheet(context),
        ),
        const SizedBox(height: AppSpacing.gap),
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
        const SizedBox(height: AppSpacing.gap),
        Text(l10n.activityTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        if (view.wallet.activity.isEmpty)
          GooraCard(child: Text(l10n.activityEmpty, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)))
        else
          GooraCard.rows(key: const Key('activity-list'), rows: [for (final e in view.wallet.activity) ActivityRow(entry: e)]),
        const SizedBox(height: AppSpacing.gap),
        GooraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.breakdownTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              _BreakdownRow(label: l10n.breakdownFuel, value: l10n.egpAmount(view.roundTripShare)),
              const SizedBox(height: AppSpacing.xs),
              _BreakdownRow(label: l10n.breakdownFees, value: null),
              const Padding(
                padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              _BreakdownRow(
                label: l10n.breakdownTotal,
                value: l10n.egpAmount(view.roundTripShare),
                strong: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.due});

  final Plan plan;
  final bool due;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GooraCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.planTypeTitle(plan.type), style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      due ? l10n.planDueTitle : l10n.planStatusLine(plan),
                      style: AppTypography.bodySmall.copyWith(
                        color: due ? AppColors.warningTitle : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('plan-change'),
                onPressed: () => showChangePlanSheet(context, current: plan.type),
                child: Text(l10n.planChange, style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
              ),
            ],
          ),
        ),
        if (due) ...[
          const SizedBox(height: AppSpacing.sm),
          GooraBanner(
            kind: GooraBannerKind.warning,
            title: l10n.planDueTitle,
            body: l10n.planDueBody,
            actionLabel: l10n.planChange,
            onAction: () => showChangePlanSheet(context, current: plan.type),
          ),
        ],
      ],
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
