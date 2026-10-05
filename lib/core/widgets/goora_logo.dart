import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Arc ring (~70% of the circle, round caps) with a center dot, next to the
/// "Goora" wordmark. The wordmark is a brand name, not translatable copy.
class GooraLogo extends StatelessWidget {
  const GooraLogo({super.key, this.wordmarkColor = AppColors.white, this.showWordmark = true});

  static const brandName = 'Goora';

  final Color wordmarkColor;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: brandName,
      excludeSemantics: true,
      child: Directionality(
        // The mark + wordmark is a fixed lockup in both languages.
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomPaint(
              size: Size.square(AppSizes.logoMark),
              painter: GooraLogoPainter(),
            ),
            if (showWordmark) ...[
              const SizedBox(width: AppSpacing.md),
              Text(brandName, style: AppTypography.wordmark.copyWith(color: wordmarkColor)),
            ],
          ],
        ),
      ),
    );
  }
}

class GooraLogoPainter extends CustomPainter {
  const GooraLogoPainter();

  static const _sweepFraction = 0.7;
  // Prototype ring: radius 20 inside a 52 box.
  static const _radiusRatio = 20 / 52;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * _radiusRatio;
    final ring = Paint()
      ..color = AppColors.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.logoStroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi * _sweepFraction,
      false,
      ring,
    );
    canvas.drawCircle(center, AppSizes.logoDot, Paint()..color = AppColors.mint);
  }

  @override
  bool shouldRepaint(GooraLogoPainter oldDelegate) => false;
}
