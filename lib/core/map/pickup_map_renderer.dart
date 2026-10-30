import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flutter_map_renderer.dart';
import 'map_config.dart';
import 'offline_pickup_renderer.dart';
import 'pickup_pin.dart';

/// What a renderer draws: [pins] in driving order, arrival last.
final class PickupMapScene {
  const PickupMapScene({required this.pins, this.expanded = false}) : assert(pins.length > 0);

  final List<PickupPin> pins;

  /// false = the static card preview (the card owns the tap);
  /// true = the bigger sheet, where a tiles map may pan and zoom.
  final bool expanded;
}

/// The one seam between the screens and a map provider (012 FR-012). See
/// `specs/012-osm-map/contracts/pickup-map-renderer.md` for the rules every
/// implementation keeps.
abstract interface class PickupMapRenderer {
  /// True when this renderer fetches tiles (and so shows the attribution).
  bool get usesNetwork;

  /// Draws exactly [scene]'s pins, filling the given box. No legend (the
  /// widget draws it), no free-point picking.
  Widget render(BuildContext context, PickupMapScene scene);
}

final mapConfigProvider = Provider<MapConfig>((ref) => MapConfig.fromEnvironment());

/// Tiles when a URL template is configured, else the offline sketch — the
/// default, and always in tests.
final pickupMapRendererProvider = Provider<PickupMapRenderer>((ref) {
  final config = ref.watch(mapConfigProvider);
  return config.hasTiles ? FlutterMapPickupRenderer(config: config) : const OfflinePickupRenderer();
});
