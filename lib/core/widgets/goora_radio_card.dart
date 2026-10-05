import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'goora_pill.dart';

/// Radio card: icon tile at the start, text in the middle, radio at the end.
/// Selection shows as border + filled radio ring, never color alone.
class GooraRadioCard extends StatelessWidget {
  const GooraRadioCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.chipLabel,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? chipLabel;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? AppColors.green : AppColors.border,
            width: AppSizes.radioCardBorder,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.listCardPad),
            child: Row(
              children: [
                if (icon != null) ...[
                  _IconTile(icon: icon!),
                  const SizedBox(width: AppSpacing.cardPad),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title, style: AppTypography.cardTitle.copyWith(color: AppColors.textPrimary)),
                          if (chipLabel != null) GooraChip(label: chipLabel!),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(subtitle!, style: AppTypography.cardSub.copyWith(color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                GooraRadioMark(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GooraRadioMark extends StatelessWidget {
  const GooraRadioMark({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.radio,
      height: AppSizes.radio,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.green : AppColors.disabled,
          width: selected ? AppSizes.radioRing : AppSizes.radioRingOff,
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.iconTileLarge,
      height: AppSizes.iconTileLarge,
      decoration: BoxDecoration(
        color: AppColors.mintSurface,
        borderRadius: BorderRadius.circular(AppRadii.tile),
      ),
      child: Icon(icon, size: AppSizes.radioIcon, color: AppColors.greenText),
    );
  }
}
