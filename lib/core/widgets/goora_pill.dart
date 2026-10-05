import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Selectable pill (days, seats, direction, plans, privacy). Min 44×44.
class GooraPill extends StatelessWidget {
  const GooraPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.pill);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        // greenText, not green: white on green is 3.2:1 (founder decision 2026-10-05).
        color: selected ? AppColors.greenText : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected ? BorderSide.none : const BorderSide(color: AppColors.borderStrong),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSizes.minTouch,
              minHeight: AppSizes.minTouch,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.pillH),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: selected
                      ? AppTypography.pillSelected.copyWith(color: AppColors.white)
                      : AppTypography.pillUnselected.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status chip ("92% match", "Verified member", "Best value").
class GooraChip extends StatelessWidget {
  const GooraChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mintSurface,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.chipH,
          vertical: AppSpacing.chipV,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSizes.iconTiny, color: AppColors.greenText),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(label, style: AppTypography.chip.copyWith(color: AppColors.greenText)),
          ],
        ),
      ),
    );
  }
}
