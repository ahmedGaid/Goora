import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/activity_entry.dart';
import '../labels.dart';

/// One row of the activity list, shared by rider and driver Wallet tabs so
/// neither forks the other's row rendering. A trip's fee shows on its own
/// line under the label (v2 FR-011).
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.entry, this.contribution = 0});

  final ActivityEntry entry;

  /// The group's per-trip contribution, for a cash trip's "Paid N EGP cash".
  final int contribution;

  static const _credit = {ActivityKind.topUp, ActivityKind.tripIncome, ActivityKind.feeReceived};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final zero = entry.amount == 0;
    final credit = _credit.contains(entry.kind);
    final color = zero ? AppColors.textSecondary : (credit ? AppColors.greenText : AppColors.textPrimary);
    final sign = zero ? '' : (credit ? '+' : '-');
    final amountText = '$sign${l10n.egpAmount(entry.amount)}';
    final caption = l10n.activityCaption(entry, contribution: contribution);
    final small = AppTypography.caption.copyWith(color: AppColors.textSecondary);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.activityLabel(entry), style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
              if (caption != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(caption, key: Key('caption-${entry.id}'), style: small),
              ],
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.shortDate(entry.date), style: small),
            ],
          ),
        ),
        Text(amountText, style: AppTypography.bodyStrong.copyWith(color: color)),
      ],
    );
  }
}
