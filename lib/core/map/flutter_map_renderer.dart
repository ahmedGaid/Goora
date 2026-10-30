import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'map_config.dart';
import 'pickup_map_renderer.dart';
import 'pickup_pin_badge.dart';

/// OpenStreetMap raster tiles from the configured host, with the pins on top
/// and the licence credit always visible (012 FR-011). Provider-neutral: any
/// `{z}/{x}/{y}` template works (Q4 is the founder's call).
final class FlutterMapPickupRenderer implements PickupMapRenderer {
  const FlutterMapPickupRenderer({required this.config, this.tileProvider});

  final MapConfig config;

  /// Null = flutter_map's network provider; tests pass an in-memory one.
  final TileProvider? tileProvider;

  static const _packageName = 'app.goora.goora';

  @override
  bool get usesNetwork => true;

  @override
  Widget render(BuildContext context, PickupMapScene scene) {
    final points = [for (final p in scene.pins) LatLng(p.lat, p.lng)];
    return FlutterMap(
      options: MapOptions(
        initialCenter: points.first,
        initialCameraFit: CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(AppSpacing.xl),
          maxZoom: MapConfig.maxFitZoom,
        ),
        // Failed or slow tiles show the brand map colour, never grey.
        backgroundColor: AppColors.mapLand,
        interactionOptions: InteractionOptions(
          flags: scene.expanded ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: config.urlTemplate,
          additionalOptions: config.tileOptions,
          userAgentPackageName: _packageName,
          tileProvider: tileProvider,
        ),
        MarkerLayer(
          markers: [
            for (final (i, p) in scene.pins.indexed)
              Marker(
                point: points[i],
                width: AppSizes.mapPin,
                height: AppSizes.mapPin,
                child: PickupPinBadge(key: Key('map-pin-$i'), pin: p),
              ),
          ],
        ),
        _Attribution(extra: config.attributionExtra),
      ],
    );
  }
}

/// "© OpenStreetMap contributors · provider credit" at the bottom end.
class _Attribution extends StatelessWidget {
  const _Attribution({required this.extra});

  final String? extra;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xs),
        child: DecoratedBox(
          key: const Key('map-attribution'),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            child: Text(
              extra == null ? l10n.mapAttribution : '${l10n.mapAttribution} · $extra',
              style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
