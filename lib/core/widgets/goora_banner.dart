import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum GooraBannerKind { warning, info }

class GooraBanner extends StatelessWidget {
  const GooraBanner({
    super.key,
    required this.kind,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final GooraBannerKind kind;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color titleColor, Color bodyColor) = switch (kind) {
      GooraBannerKind.warning => (
          AppColors.warningBg,
          AppColors.warningBorder,
          AppColors.warningTitle,
          AppColors.warningBody,
        ),
      GooraBannerKind.info => (
          AppColors.infoBg,
          AppColors.infoBorder,
          AppColors.infoTitle,
          AppColors.infoBody,
        ),
    };
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.banner),
          border: Border.all(color: border),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.bannerH,
            vertical: AppSpacing.bannerV,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyStrong.copyWith(color: titleColor)),
              const SizedBox(height: AppSpacing.xxs),
              Text(body, style: AppTypography.bodySmall.copyWith(color: bodyColor)),
              if (actionLabel != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: titleColor,
                      textStyle: AppTypography.bodyStrong,
                      minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
                      padding: EdgeInsetsDirectional.zero,
                    ),
                    child: Text(actionLabel!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
