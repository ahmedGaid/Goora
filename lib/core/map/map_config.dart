/// Map tile settings, read at build time only (`--dart-define`), so no key is
/// ever stored in the repo. With no URL template the app draws the offline
/// sketch and makes no map network calls (012 FR-009/FR-010).
///
/// Kept apart from `core/config/env.dart` on purpose (012 research R2).
final class MapConfig {
  const MapConfig({required this.urlTemplate, this.apiKey = '', this.extraAttribution = ''});

  factory MapConfig.fromEnvironment() => const MapConfig(
        urlTemplate: String.fromEnvironment('MAP_TILE_URL_TEMPLATE'),
        apiKey: String.fromEnvironment('MAP_TILE_API_KEY'),
        extraAttribution: String.fromEnvironment('MAP_TILE_ATTRIBUTION'),
      );

  /// A `{z}/{x}/{y}` raster template; may hold a `{key}` placeholder.
  final String urlTemplate;
  final String apiKey;

  /// The tile provider's own credit, shown next to the OSM one.
  final String extraAttribution;

  /// Fit-to-points never zooms closer than street level.
  static const maxFitZoom = 16.0;

  bool get hasTiles => urlTemplate.trim().isNotEmpty;

  /// Fills `{key}` in [urlTemplate].
  Map<String, String> get tileOptions => apiKey.isEmpty ? const {} : {'key': apiKey};

  String? get attributionExtra {
    final t = extraAttribution.trim();
    return t.isEmpty ? null : t;
  }
}
