import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'goora_icons.dart';

/// Globe pill naming the *other* language, in that language's font.
/// Visual height 36; tap area 44.
class LanguagePill extends StatelessWidget {
  const LanguagePill({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.labelFontFamily,
    required this.onTap,
    this.onDark = false,
  });

  final String label;
  final String semanticLabel;
  final String labelFontFamily;
  final VoidCallback onTap;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? AppColors.white : AppColors.primary;
    final radius = BorderRadius.circular(AppRadii.chip);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox(
          height: AppSizes.minTouch,
          child: Center(
            widthFactor: 1,
            child: Container(
              height: AppSizes.langPillHeight,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: onDark ? AppColors.onDarkPillFill : AppColors.surface,
                borderRadius: radius,
                border: Border.all(color: onDark ? AppColors.onDarkPillBorder : AppColors.borderStrong),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(GooraIcons.globe, size: AppSizes.iconTiny, color: fg),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: AppTypography.langPill.copyWith(color: fg, fontFamily: labelFontFamily),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
