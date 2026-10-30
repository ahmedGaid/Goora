# Tasks: Pickup-point map (012)

**Input**: `specs/012-osm-map/` (spec, plan, research, data-model, contracts)
**Tests**: required (constitution VIII + lane rule "tests first, confirmed failing").
Format: `- [ ] T### [P?] [Story] description — path`

## Phase 1 — Setup

- [x] T001 Add `flutter_map` 8.3.2 + `latlong2` 0.10.1 (deps-only commit de90041) — `pubspec.yaml`, `pubspec.lock`
- [x] T002 Add map size tokens `mapPin`, `mapPinRing`, `pickupMapSheetFraction` at the end of `AppSizes` — `lib/core/theme/app_sizes.dart`
- [x] T003 Add ARB keys at the END of both files + `flutter gen-l10n`: `mapCardTitle`, `mapSketchNote`, `mapOpen`, `mapClose`, `mapAttribution`, `mapPointsAria` — `lib/core/l10n/app_ar.arb`, `app_en.arb`

## Phase 2 — Foundation (blocks all stories)

- [x] T004 [P] Unit test `MapConfig` (empty → no tiles; template + key; `{key}` option; extra attribution) — `test/unit/map/map_config_test.dart`
- [x] T005 [P] Unit test `PickupPin` (built from `Stop`, numbers, arrival has no number) — `test/unit/map/pickup_pin_test.dart`
- [x] T006 Confirm T004–T005 fail (no implementation yet)
- [x] T007 `MapConfig` — `lib/core/map/map_config.dart`
- [x] T008 `PickupPin`, `PickupPinKind` — `lib/core/map/pickup_pin.dart`
- [x] T009 `PickupMapRenderer`, `PickupMapScene`, `pickupMapRendererProvider` — `lib/core/map/pickup_map_renderer.dart`

## Phase 3 — US3 offline default + tiles path (P1)

- [x] T010 [P] [US3] Widget tests: no tile URL → provider gives offline renderer, sketch + legend + note render, no `FlutterMap` / `NetworkImage` in tree; RTL puts pin 1 on the start side; card is one ≥ 44 px button with the spoken legend; sheet opens and closes; a provider override swaps the renderer (FR-012); no pin is tappable (FR-001) — `test/widget/map/goora_pickup_map_test.dart`
- [x] T011 [P] [US3] Widget tests: tiles renderer with fake `TileProvider` shows `FlutterMap`, all pins and the attribution chip (+ extra credit) — `test/widget/map/flutter_map_renderer_test.dart`
- [x] T012 [US3] Confirm T010–T011 fail
- [x] T013 [US3] `OfflinePickupRenderer` — `lib/core/map/offline_pickup_renderer.dart`
- [x] T014 [US3] `FlutterMapPickupRenderer` + attribution chip — `lib/core/map/flutter_map_renderer.dart`
- [x] T015 [US3] `GooraPickupMap` (card preview, legend, semantics, tap) + `showPickupMapSheet` — `lib/core/widgets/goora_pickup_map.dart`
- [x] T016 [US3] Contrast pairs: white on `primary`, white on `mapDestination` (non-text), `textSecondary` on `surface` — `test/unit/map/map_contrast_test.dart`

## Phase 4 — US1 match result (P1)

- [x] T017 [US1] Widget test ar + en: match result shows the map card with the viewer's stop + arrival, no home point; tap opens sheet — `test/widget/map/surfaces_map_test.dart`
- [x] T018 [US1] Add the map card — `lib/features/commute/presentation/match_result_screen.dart`

## Phase 5 — US2 Today (P1)

- [x] T019 [US2] Widget tests ar + en: rider Today meeting-point card (stop + arrival); driver Today card (all stops in order + arrival); tap opens sheet — `test/widget/map/surfaces_map_test.dart (written after T018/T020 — see research note)`
- [x] T020 [US2] `MeetingPointCard` + rider placement — `lib/features/daily/presentation/today/rider_today.dart`
- [x] T021 [US2] Driver placement — `lib/features/daily/presentation/today/driver_today.dart`

## Phase 6 — Polish

- [x] T022 [P] Design gallery entry — `lib/features/design_gallery/presentation/design_gallery_screen.dart`
- [x] T023 [P] Goldens ar + en at 1.3× (offline) for `GooraPickupMap` card + sheet — `test/golden/map/goora_pickup_map_golden_test.dart`
- [x] T024 Regenerate only the screen goldens these surfaces changed; list them in the status block
- [x] T025 README "Map tiles" section — `README.md`
- [x] T026 Gates: analyze 0 · `flutter test --concurrency=1` · node tests — 0 · 1809 · 276 (2026-10-30)
- [x] T027 goora-status block · push · "Lane M done" to managere

## Dependencies

T002–T003 → T007–T009 → T013–T015 → T018, T020–T021 → T022–T027. Tests precede their code.
