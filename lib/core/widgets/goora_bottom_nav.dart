import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class GooraNavItem {
  const GooraNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// 4-tab bottom bar: white, 1 px top border, active greenText, inactive textMuted.
class GooraBottomNav extends StatelessWidget {
  const GooraBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.semanticLabel,
  });

  final List<GooraNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: BorderDirectional(top: BorderSide(color: AppColors.border)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.bottomNavBottom,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _NavButton(item: items[i], active: i == currentIndex, onTap: () => onTap(i))),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.onTap});

  final GooraNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.greenText : AppColors.textMuted;
    return Semantics(
      selected: active,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: AppSizes.navIcon, color: color),
              const SizedBox(height: AppSpacing.xxs),
              Text(item.label, style: AppTypography.microBold.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
