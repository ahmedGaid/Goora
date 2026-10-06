import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A filled bar with its value always written as text (never colour alone).
class GooraProgressBar extends StatelessWidget {
  const GooraProgressBar({super.key, required this.value, required this.valueLabel, required this.label});

  /// 0…1.
  final double value;

  /// Visible and spoken value, e.g. "96%".
  final String valueLabel;
  final String label;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      label: label,
      value: valueLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary))),
              Text(valueLabel, style: AppTypography.stat.copyWith(color: AppColors.greenText)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.progressBar),
            child: SizedBox(
              height: AppSizes.progressBarHeight,
              child: Stack(
                children: [
                  const Positioned.fill(child: ColoredBox(color: AppColors.border)),
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: v,
                    heightFactor: 1,
                    child: const ColoredBox(color: AppColors.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
