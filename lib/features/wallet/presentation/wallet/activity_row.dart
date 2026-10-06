import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/activity_entry.dart';
import '../labels.dart';

/// One row of the activity list (FR-007/FR-011), shared by rider and driver
/// Wallet tabs so neither forks the other's row rendering.
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.entry});

  final ActivityEntry entry;

  static const _credit = {ActivityKind.topUp, ActivityKind.tripIncome, ActivityKind.feeReceived};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final zero = entry.amount == 0;
    final credit = _credit.contains(entry.kind);
    final color = zero ? AppColors.textSecondary : (credit ? AppColors.greenText : AppColors.textPrimary);
    final sign = zero ? '' : (credit ? '+' : '-');
    final amountText = '$sign${l10n.egpAmount(entry.amount)}';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.activityLabel(entry), style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.shortDate(entry.date), style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        Text(amountText, style: AppTypography.bodyStrong.copyWith(color: color)),
      ],
    );
  }
}
