import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class GooraGhostButton extends StatelessWidget {
  const GooraGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.ghostButtonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: danger ? AppColors.dangerText : AppColors.primary,
          disabledForegroundColor: AppColors.textMuted,
          textStyle: AppTypography.buttonSecondary.withLocaleFont(context),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.cardPad),
          side: BorderSide(color: danger ? AppColors.dangerBorder : AppColors.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSizes.iconSmall),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
