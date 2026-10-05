import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'goora_icons.dart';

enum GooraPrimaryVariant { light, onDark, outlineOnDark }

/// Full-width 54 px button. `onDark` = mint fill with forest text;
/// `outlineOnDark` = transparent with an on-dark border (welcome "Log in").
class GooraPrimaryButton extends StatelessWidget {
  const GooraPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingArrow = false,
    this.variant = GooraPrimaryVariant.light,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool trailingArrow;
  final GooraPrimaryVariant variant;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      GooraPrimaryVariant.light => (AppColors.primary, AppColors.white, BorderSide.none),
      GooraPrimaryVariant.onDark => (AppColors.mint, AppColors.forest, BorderSide.none),
      GooraPrimaryVariant.outlineOnDark => (
          Colors.transparent,
          AppColors.white,
          const BorderSide(color: AppColors.onDarkBorder),
        ),
    };
    return SizedBox(
      width: double.infinity,
      height: AppSizes.primaryButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.white,
          textStyle: AppTypography.button.withLocaleFont(context),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.heroPad),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
            side: side,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            if (trailingArrow) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(GooraIcons.forward, size: AppSizes.iconSmall),
            ],
          ],
        ),
      ),
    );
  }
}
