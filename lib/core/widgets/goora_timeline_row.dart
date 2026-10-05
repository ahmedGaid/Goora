import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum GooraTimelineKind { pickup, transit, arrival }

class GooraTimelineRow extends StatelessWidget {
  const GooraTimelineRow({
    super.key,
    required this.kind,
    required this.title,
    this.subtitle,
  });

  final GooraTimelineKind kind;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final dot = switch (kind) {
      GooraTimelineKind.pickup => AppColors.green,
      GooraTimelineKind.transit => AppColors.disabled,
      GooraTimelineKind.arrival => AppColors.mapDestination,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
          child: Container(
            width: AppSizes.timelineDot,
            height: AppSizes.timelineDot,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
              if (subtitle != null)
                Text(subtitle!, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
