import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Drawn home → work card used until a live map is available. Shows area
/// names only — never exact points. Home sits on the start side.
class GooraRouteMap extends StatelessWidget {
  const GooraRouteMap({
    super.key,
    required this.fromLabel,
    required this.toLabel,
    required this.semanticLabel,
  });

  final String fromLabel;
  final String toLabel;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final labelStyle = AppTypography.captionSemi.copyWith(color: AppColors.textBody);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          height: AppSizes.routeMapHeight,
          color: AppColors.mapLand,
          padding: const EdgeInsetsDirectional.all(AppSpacing.cardPad),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _RoutePainter(startOnRight: rtl))),
              PositionedDirectional(start: 0, bottom: 0, child: Text(fromLabel, style: labelStyle)),
              PositionedDirectional(end: 0, top: 0, child: Text(toLabel, style: labelStyle)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.startOnRight});

  final bool startOnRight;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = AppSizes.timelineDot;
    final bottom = size.height - inset * 2;
    const top = inset;
    final from = Offset(startOnRight ? size.width - inset : inset, bottom);
    final to = Offset(startOnRight ? inset : size.width - inset, top + inset);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(
        from.dx + (to.dx - from.dx) * 0.2,
        top,
        from.dx + (to.dx - from.dx) * 0.6,
        size.height,
        to.dx,
        to.dy,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.routeStroke
        ..strokeCap = StrokeCap.round,
    );
    final ring = Paint()..color = AppColors.white;
    canvas.drawCircle(from, AppSizes.timelineDot / 2 + 2, ring);
    canvas.drawCircle(from, AppSizes.timelineDot / 2, Paint()..color = AppColors.green);
    canvas.drawCircle(to, AppSizes.timelineDot / 2 + 2, ring);
    canvas.drawCircle(to, AppSizes.timelineDot / 2, Paint()..color = AppColors.mapDestination);
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.startOnRight != startOnRight;
}
