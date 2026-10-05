import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Demo or secondary actions only (brief §3.4).
class GooraDashedButton extends StatelessWidget {
  const GooraDashedButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.dashed);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: CustomPaint(
        foregroundPainter: const _DashedBorderPainter(),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: SizedBox(
              width: double.infinity,
              height: AppSizes.dashedButtonHeight,
              child: Center(
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.cardPad),
                  child: Text(
                    label,
                    style: AppTypography.dashed.copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.disabled
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.hairline;
    const half = AppSizes.hairline / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(half, half, size.width - AppSizes.hairline, size.height - AppSizes.hairline),
      const Radius.circular(AppRadii.dashed),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}
