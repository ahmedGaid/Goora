import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Small label + value tile ("Return time", "You pay per trip").
class GooraStatTile extends StatelessWidget {
  const GooraStatTile({super.key, required this.label, required this.value, this.caption});

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.cardPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xxs),
              Text(value, style: AppTypography.stat.copyWith(color: AppColors.textPrimary)),
              if (caption != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(caption!, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
