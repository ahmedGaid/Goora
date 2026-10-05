import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

/// Onboarding progress: current step wide green, done steps green,
/// future steps grey (founder decision 2026-10-05).
class GooraProgressDots extends StatelessWidget {
  const GooraProgressDots({
    super.key,
    required this.count,
    required this.current,
    required this.semanticLabel,
  });

  final int count;
  final int current;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.progressGap),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == current ? AppSizes.progressActive : AppSizes.progressDot,
              height: AppSizes.progressHeight,
              decoration: BoxDecoration(
                color: i <= current ? AppColors.green : AppColors.borderStrong,
                borderRadius: BorderRadius.circular(AppRadii.progressBar),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
