import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'goora_icons.dart';

enum GooraStatus { covered, waiting, pickedUp, noShow, backup, off }

/// Ride / passenger status: icon + text on a tinted chip, so meaning never
/// depends on colour alone (FR-035).
class GooraStatusChip extends StatelessWidget {
  const GooraStatusChip({super.key, required this.status, required this.label});

  final GooraStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color bg, Color fg) = switch (status) {
      GooraStatus.covered => (GooraIcons.check, AppColors.mintSurface, AppColors.greenText),
      GooraStatus.pickedUp => (GooraIcons.pickedUp, AppColors.mintSurface, AppColors.greenText),
      GooraStatus.waiting => (GooraIcons.waiting, AppColors.infoBg, AppColors.infoTitle),
      GooraStatus.backup => (GooraIcons.backup, AppColors.infoBg, AppColors.infoTitle),
      GooraStatus.noShow => (GooraIcons.noShow, AppColors.dangerBg, AppColors.dangerText),
      GooraStatus.off => (GooraIcons.dayOff, AppColors.divider, AppColors.textSecondary),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.chip)),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.statusIcon, color: fg),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(child: Text(label, style: AppTypography.microBold.copyWith(color: fg))),
          ],
        ),
      ),
    );
  }
}
