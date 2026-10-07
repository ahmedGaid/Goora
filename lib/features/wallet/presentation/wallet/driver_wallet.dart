import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_primary_button.dart';
import 'activity_row.dart';
import 'wallet_controller.dart';
import 'withdraw_sheet.dart';

/// US3: a driver's recovered balance, payout line, withdrawal, activity and
/// trip-cost breakdown. Shares [ActivityRow]/[GooraCard] with [RiderWallet]
/// rather than forking them.
class DriverWallet extends StatelessWidget {
  const DriverWallet({super.key, required this.view});

  final WalletView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GooraHeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.recoveredTitle, style: AppTypography.bodySmall.copyWith(color: AppColors.onDarkSecondary)),
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.egpAmount(view.wallet.balance), style: AppTypography.display.copyWith(color: AppColors.white)),
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.payoutNote, style: AppTypography.bodySmall.copyWith(color: AppColors.onDarkBody)),
              const SizedBox(height: AppSpacing.gap),
              GooraPrimaryButton(
                key: const Key('withdraw'),
                label: l10n.withdraw,
                variant: GooraPrimaryVariant.onDark,
                onPressed: view.wallet.balance > 0 ? () => showWithdrawSheet(context, amount: view.wallet.balance) : null,
              ),
            ],
          ),
        ),
        if (view.wallet.cashReceived > 0) ...[
          const SizedBox(height: AppSpacing.gap),
          // Recorded only: never part of the balance above or a withdrawal (FR-013).
          GooraCard(
            key: const Key('cash-received'),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.cashReceivedTitle, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(l10n.cashReceivedNote, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(
                  l10n.egpAmount(view.wallet.cashReceived),
                  style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
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
              Text(l10n.driverBreakdownTitle, style: AppTypography.section.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              _BreakdownRow(label: l10n.driverBreakdownCost, value: l10n.egpAmount(view.tripCost)),
              const SizedBox(height: AppSpacing.xs),
              _BreakdownRow(label: l10n.driverBreakdownReceived, value: l10n.egpAmount(view.receivedFromRiders)),
              if (view.driverGap > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                _BreakdownRow(label: l10n.driverBreakdownGap, value: l10n.egpAmount(view.driverGap)),
              ],
              const Padding(
                padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              _BreakdownRow(label: l10n.driverBreakdownFree, value: null, strong: true),
            ],
          ),
        ),
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
