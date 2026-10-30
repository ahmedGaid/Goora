# Implementation Plan: Pickup-point map (OpenStreetMap display)

**Branch**: `feat/osm-map` | **Date**: 2026-10-30 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/012-osm-map/spec.md`

## Summary

Add one shared widget, `GooraPickupMap`, that shows a group's public stops (pickup pins numbered in
driving order + the arrival pin) with a text legend, and a `showPickupMapSheet` bigger view. The
widget asks a single `pickupMapRendererProvider` for a renderer: `OfflinePickupRenderer` (drawn
sketch, no network — the default, and always in tests) or `FlutterMapPickupRenderer` (OSM tiles
from `--dart-define=MAP_TILE_URL_TEMPLATE`, with attribution). Pins are built only from `Stop`, so
a home point cannot reach the map. Surfaces: match result (viewer's stop + arrival), rider Today
and driver Today (new meeting-point card after the trip timeline / drive hero).

## Technical Context

**Language/Version**: Dart ^3.12 / Flutter stable
**Primary Dependencies**: flutter_map 8.3.2, latlong2 0.10.1 (added in P0 commit de90041), flutter_riverpod 3
**Storage**: none (display only)
**Testing**: flutter_test — unit (config, pins, projection), widget (fallback, attribution, privacy, surfaces ar/en), goldens ar/en at 1.3× (offline mode only)
**Target Platform**: Android (API 24+) + iOS 14+
**Project Type**: mobile app, feature-first
**Performance Goals**: map card builds in one frame; no tiles fetched for the small preview beyond its viewport
**Constraints**: no network with no tile URL; no secrets in repo; tokens only; directional layout; ≥ 44 px targets; no edits to `lib/core/config/env.dart` (Lane 011), router (Lane F), android manifest (Lane L)
**Scale/Scope**: 1 widget + 1 sheet + 2 renderers + config; 3 surfaces; ~8 ARB keys

## Constitution Check

| Principle | Check | Result |
|---|---|---|
| I Commute-first | Finding the meeting point is a daily-commute task | PASS |
| II Cost-sharing | No pricing/matching touched; display only | PASS (n/a) |
| III Arabic-first, RTL | ARB ar/en, directional pin order + `PositionedDirectional`, attribution at `end` | PASS |
| IV Privacy | `PickupPin` only constructible from `Stop` (public point); no home, no rider names, no live driver position | PASS |
| V Safety | SOS/share untouched | PASS (n/a) |
| VI One design system | `mapLand`, `primary`, `mapDestination`, `white` tokens; new sizes in `AppSizes` | PASS |
| VII Accessible | card = one button with spoken legend; numbers + text, never colour alone; white-on-primary / white-on-mapDestination pairs in contrast test | PASS |
| VIII Testable | renderer interface + provider override; fake `TileProvider` in tests | PASS |
| IX Simplicity | one new dependency pair with a stated reason (profit change 4); no selection UI built | PASS |
| Tech constraints: "Maps: google_maps_flutter" | Superseded by founder's profit change §4 and brief §4 (already says flutter_map). Constitution text is stale. | **FLAG** → Complexity Tracking |

Re-check after design: unchanged (all PASS, one FLAG).

## Project Structure

### Documentation (this feature)

```text
specs/012-osm-map/
├── spec.md · plan.md · research.md · data-model.md · quickstart.md · tasks.md
├── contracts/pickup-map-renderer.md
└── checklists/requirements.md
```

### Source Code

```text
lib/core/map/
├── map_config.dart              # MapConfig.fromEnvironment(): url template, key, extra attribution
├── pickup_pin.dart              # PickupPin (from Stop only), PickupPinKind
├── pickup_map_renderer.dart     # abstract interface + PickupMapScene + pickupMapRendererProvider
├── offline_pickup_renderer.dart # drawn sketch, no network
└── flutter_map_renderer.dart    # OSM tiles + attribution (injectable TileProvider)
lib/core/widgets/goora_pickup_map.dart   # card preview + legend + showPickupMapSheet
lib/core/theme/app_sizes.dart            # + pickupMapHeight, pickupMapSheetHeight, mapPin
lib/features/commute/presentation/match_result_screen.dart   # map card under the summary
lib/features/daily/presentation/today/rider_today.dart       # MeetingPointCard (rider)
lib/features/daily/presentation/today/driver_today.dart      # MeetingPointCard (driver stops)
lib/features/design_gallery/presentation/design_gallery_screen.dart  # gallery entry
lib/core/l10n/app_ar.arb · app_en.arb (+ generated)          # new keys at the END
test/unit/map/ · test/widget/map/ · test/golden/map/
```

**Structure Decision**: map code lives in `lib/core/map/` (shared, swappable); the widget in
`lib/core/widgets/` like every `Goora*` component. `core` already imports `features/commute/domain`
(see `core/time/`), so `PickupPin` may depend on `Stop` directly — that dependency IS the privacy
guarantee.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Constitution tech line names `google_maps_flutter`; this feature uses `flutter_map` | Founder's profit change §4 (Google Maps out, OSM in) and brief §4 already updated | Editing the constitution needs founder approval + version bump (PATCH 1.0.2 → 1.0.3) — not this lane's call; flagged to the conductor |
