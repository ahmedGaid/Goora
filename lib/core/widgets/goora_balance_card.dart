import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'goora_card.dart';
import 'goora_primary_button.dart';

/// Dark balance card (constitution VI): balance, "Covers about {N} trips",
/// and a Top up action. Shared by the rider Wallet tab.
class GooraBalanceCard extends StatelessWidget {
  const GooraBalanceCard({
    super.key,
    required this.balanceLabel,
    required this.balanceValue,
    required this.tripsCaption,
    required this.topUpLabel,
    required this.onTopUp,
  });

  final String balanceLabel;
  final String balanceValue;
  final String tripsCaption;
  final String topUpLabel;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    return GooraHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(balanceLabel, style: AppTypography.bodySmall.copyWith(color: AppColors.onDarkSecondary)),
          const SizedBox(height: AppSpacing.xxs),
          Text(balanceValue, style: AppTypography.display.copyWith(color: AppColors.white)),
          const SizedBox(height: AppSpacing.xxs),
          Text(tripsCaption, style: AppTypography.bodySmall.copyWith(color: AppColors.onDarkBody)),
          const SizedBox(height: AppSpacing.gap),
          GooraPrimaryButton(
            key: const Key('top-up'),
            label: topUpLabel,
            variant: GooraPrimaryVariant.onDark,
            onPressed: onTopUp,
          ),
        ],
      ),
    );
  }
}
