import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'goora_card.dart';
import 'goora_primary_button.dart';

/// Dark balance card (constitution VI): balance, "Covers about {N} trips",
/// and a Top up action. Shared by the rider Wallet tab.
///
/// [balanceValue] is a money string such as "320 ج" or "320 EGP"; the unit
/// after the last space is drawn smaller on the same line (see [GooraBalanceValue]).
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
          GooraBalanceValue(balanceValue),
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

/// A money value on a dark hero card: the digits at display size, the unit one
/// step smaller on the same baseline. At 38 px the Arabic ج hangs well below
/// the baseline and read as sitting lower than the digits (walk nit N-5); at
/// title size the drop is in proportion. A value with no space stays one run.
/// Shared by the rider balance card and the driver's received-directly card.
class GooraBalanceValue extends StatelessWidget {
  const GooraBalanceValue(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.display.copyWith(color: AppColors.white);
    final split = value.lastIndexOf(' ');
    if (split < 1) return Text(value, style: style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: value.substring(0, split)),
          TextSpan(text: value.substring(split), style: AppTypography.title),
        ],
      ),
    );
  }
}
