# Research: Pickup-point map (012)

Autonomous lane (Lane M, 2026-10-30): no questions were asked. Every choice below names the option
taken and the one rejected.

## R1 — Map library

- **Decision**: `flutter_map` 8.3.2 + `latlong2` 0.10.1 (current stable on pub.dev on 2026-10-30; caret constraint, exact version locked in `pubspec.lock`). Added alone in commit de90041 so the conductor could land it on main before Lane 011 edits pubspec.
- **Rationale**: profit change §4 + brief §4: OSM, display only, provider-neutral. flutter_map takes any `{z}/{x}/{y}` raster template.
- **Rejected**: `google_maps_flutter` (founder: Google Maps is not used); `maplibre_gl` (vector tiles, native SDK, heavier; nothing here needs vectors).

## R2 — Configuration

- **Decision**: new `lib/core/map/map_config.dart` reads `MAP_TILE_URL_TEMPLATE`, `MAP_TILE_API_KEY` and an optional `MAP_TILE_ATTRIBUTION` with `String.fromEnvironment`. Tiles are "on" only when the template is non-empty. A `{key}` placeholder in the template is filled from the key (flutter_map `additionalOptions`).
- **Rejected**: reading `Env.mapTileUrlTemplate` from `lib/core/config/env.dart` — Lane 011 owns that file this round; duplicating two `fromEnvironment` lines is cheaper than a cross-lane edit. Follow-up after 011 merges: `MapConfig` may delegate to `Env`.
- **Rejected**: runtime `.env` loading — no secret may ship in an asset.

## R3 — Swappable provider

- **Decision**: `abstract interface class PickupMapRenderer { Widget render(BuildContext, PickupMapScene) }` + `pickupMapRendererProvider` (plain Riverpod `Provider`) choosing `FlutterMapPickupRenderer` or `OfflinePickupRenderer` from `MapConfig`. Screens only use `GooraPickupMap`. A new provider = one new renderer class + one line in the provider.
- **Rejected**: a `GooraMapView` widget hierarchy per provider (more surface, same effect); `riverpod_generator` for one provider (codegen churn for no gain).

## R4 — Offline view (the shipped default)

- **Decision**: a drawn sketch — `mapLand` canvas, a soft path, pins evenly spaced in driving order (first pin on the start side, as `GooraRouteMap`), a legend list under it, and a caption "sketch, not to scale".
- **Rejected**: projecting real lat/lng on the canvas — at corridor scale the 200 m stops collapse onto one pixel while the 100 km leg stretches the box; it would also hint at exact geography without a base map. **Rejected**: only the text list (reads as "the map is missing").

## R5 — Privacy by type

- **Decision**: `PickupPin` has a private constructor; the only factories are `PickupPin.pickup(Stop, …)` and `PickupPin.arrival(Stop, …)`. `GooraPickupMap` takes `List<PickupPin>`. A `GeoPoint` or `Place` (home) cannot be passed. Labels are stop names + times only — never rider names (Constitution IV).
- **Rejected**: taking `List<GeoPoint>` and trusting callers.

## R6 — Attribution

- **Decision**: own `_MapAttribution` chip, bottom-`end`, `surface` fill, `textSecondary` caption, text from ARB `mapAttribution` ("© مساهمو OpenStreetMap" / "© OpenStreetMap contributors") plus `MAP_TILE_ATTRIBUTION` when set. Shown on every tiles render, small and big.
- **Rejected**: flutter_map's `SimpleAttributionWidget` — hard-coded English "flutter_map | ©" text and a non-directional `Alignment.bottomRight`. OSM's attribution guideline allows a translated credit.

## R7 — Surfaces

- **Decision**: match result: card after the group summary (viewer's nearest stop + arrival). Rider Today: `MeetingPointCard` after `TripTimeline` (my stop; + arrival on the going leg). Driver Today: `MeetingPointCard` after `DriveHero` (going stops in order + arrival; return-only → the work meeting point). Tap → `showPickupMapSheet` (modal bottom sheet).
- **Rejected**: replacing `GooraRouteMap` in `TripMapCard` — it carries the 003 trip-progress marker and countdown (existing tests + goldens); FR-003 forbids a live position on the new map. **Rejected**: a new go_router route for the big map — `lib/app/router.dart` is Lane F's.

## R8 — Tests without network

- **Decision**: tests never set `MAP_TILE_URL_TEMPLATE`, so the provider returns the offline renderer. The tiles path is tested by constructing `FlutterMapPickupRenderer` with a fake `TileProvider` that returns an in-memory image. Goldens use the offline renderer only.

## R9 — Android INTERNET permission

- Release builds need `android.permission.INTERNET` in `android/app/src/main/AndroidManifest.xml` for tiles (debug builds have it). Lane L owns the manifest → flagged to the conductor; nothing changes until a tile URL is configured anyway.

## Decisions (log)

| # | Decision | Rejected alternative |
|---|---|---|
| D1 | flutter_map 8.3.2 + latlong2 0.10.1, caret + lock | google_maps_flutter; maplibre_gl |
| D2 | `MapConfig` in `lib/core/map/`, own `fromEnvironment` | editing `env.dart` (Lane 011) |
| D3 | `{key}` placeholder via `additionalOptions` | key appended as a fixed `?key=` query (provider-specific) |
| D4 | Optional `MAP_TILE_ATTRIBUTION` define | hard-coding one provider's credit |
| D5 | Renderer interface + one provider switch | per-provider widget classes |
| D6 | Offline = ordered sketch + legend + "not to scale" | real-position projection; text list only |
| D7 | `PickupPin` only from `Stop` | `List<GeoPoint>` input |
| D8 | Own translated attribution chip at bottom-end | `SimpleAttributionWidget` |
| D9 | New meeting-point card; route card untouched | replacing `GooraRouteMap` |
| D10 | Big map = modal bottom sheet | new route (router is Lane F's) |
| D11 | Small preview static; pan/zoom only on big tiles map | interactive preview (scroll conflicts in a ListView) |
| D12 | No point selection UI | building select-a-stop now (no surface needs it; IX) |
| D13 | Pins: `primary` fill + white number; arrival `mapDestination` + white flag icon | `green` fill (white on green < 4.5:1) |
| D14 | Constitution "google_maps_flutter" line left as is, flagged | editing the constitution (founder approval) |
| D15 | README "Map tiles" section; `.env.example` unchanged (already has the keys) | adding `MAP_TILE_ATTRIBUTION` to `.env.example` (not in this lane's files) |
| D16 | Zoom cap 16 when fitting; fit padding = `AppSpacing.xl` | fitting a single point (infinite zoom) |
