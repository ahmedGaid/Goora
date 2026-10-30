import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import 'pickup_map_renderer.dart';
import 'pickup_pin_badge.dart';

/// The no-tiles default: pins evenly spaced in driving order along a soft
/// path on the brand map colour. A sketch, not geography — real positions
/// would pile 200 m stops onto one spot on a 100 km leg (012 research R4).
/// No network, no gestures.
final class OfflinePickupRenderer implements PickupMapRenderer {
  const OfflinePickupRenderer();

  @override
  bool get usesNetwork => false;

  @override
  Widget render(BuildContext context, PickupMapScene scene) => _Sketch(scene: scene);
}

class _Sketch extends StatelessWidget {
  const _Sketch({required this.scene});

  final PickupMapScene scene;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ColoredBox(
      key: const Key('pickup-map-sketch'),
      color: AppColors.mapLand,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          final spots = _spots(size, scene.pins.length);
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _PathPainter(spots: spots, rtl: rtl))),
              for (final (i, at) in spots.indexed)
                PositionedDirectional(
                  key: Key('map-pin-$i'),
                  start: at.dx - AppSizes.mapPin / 2,
                  top: at.dy - AppSizes.mapPin / 2,
                  child: PickupPinBadge(pin: scene.pins[i]),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Points on a quadratic curve from the start-bottom to the end-top, in
  /// start-relative x (so the Stack mirrors them in RTL). One pin → centre.
  static List<Offset> _spots(Size size, int count) {
    if (count == 1) return [Offset(size.width / 2, size.height / 2)];
    final (p0, p1, p2) = _curve(size);
    return [
      for (var i = 0; i < count; i++)
        () {
          final t = i / (count - 1);
          final u = 1 - t;
          return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
        }(),
    ];
  }
}

/// Start, control and end points of the sketch path (start-relative x).
(Offset, Offset, Offset) _curve(Size size) {
  const inset = AppSizes.mapPin;
  return (
    Offset(inset, size.height - inset),
    Offset(size.width / 2, size.height - inset),
    Offset(size.width - inset, inset),
  );
}

class _PathPainter extends CustomPainter {
  const _PathPainter({required this.spots, required this.rtl});

  final List<Offset> spots;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (spots.length < 2) return;
    Offset physical(Offset o) => rtl ? Offset(size.width - o.dx, o.dy) : o;
    final (s0, s1, s2) = _curve(size);
    final (p0, p1, p2) = (physical(s0), physical(s1), physical(s2));
    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.disabled
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.routeStroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.rtl != rtl || old.spots != spots;
}
