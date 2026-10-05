---
description: "Task list for feature 002: Commute Profile and Smart Matching"
---

# Tasks: Commute Profile and Smart Matching

**Input**: `specs/002-commute-matching/` (plan, spec, research, data-model, contracts)

**Tests**: REQUIRED (constitution VIII, FR-021/022): unit tests with brief numbers, shared vectors
on Dart + Node, widget tests ar + en.

## Phase 1: Setup

- [ ] T001 `supabase init` at repo root (config only; do not start Docker) and add `supabase/.temp` / `.branches` to `.gitignore`
- [ ] T002 [P] Generalise `lib/features/placeholder/presentation/placeholder_screen.dart` to take a title + back route (+ optional progress index); keep 001 destinations working

## Phase 2: Foundational (domain, pure Dart)

- [ ] T003 [P] `lib/features/commute/domain/geo.dart` (GeoPoint, haversine) + `clock.dart` (Clock, diff, AM/PM parts)
- [ ] T004 [P] `place.dart` (Area, Place), `commute_profile.dart` (Day, DrivenTrips, DriverOffer, CommuteProfile + JSON + validation)
- [ ] T005 [P] `group.dart` (Member, CommuteGroup, Leg)
- [ ] T006 `pricing_service.dart` (TripCostConfig with `ratesEnabled`, suggested, range, cap, snap, recoveryPerDay, delta) — research R4
- [ ] T007 `matching_service.dart` (MatchingLimits, Seeker, FactorScores, Reason, GroupMatch, MatchResult; constraints R2, scoring R1, legs R3)
- [ ] T008 `commute_repository.dart` interface (contracts/match-function.md)
- [ ] T009 [P] `test/unit/pricing_service_test.dart`: 160 & 3 riders → 40, range 32–48, steps of 2, labels, cap, snap, 240/288/144 per day
- [ ] T010 [P] `test/unit/matching_service_test.dart`: each hard constraint excludes at limit+1 and passes at limit; linear points at 0/half/limit; rounding; legs split; reasons top-4; privacy rules
- [ ] T011 `test/fixtures/matching_vectors.json` (hand-computed) + `test/unit/matching_vectors_test.dart`

## Phase 3: US1 — Set up my daily commute (P1) 🎯

- [ ] T012 [P] `lib/core/widgets/goora_time_stepper.dart` and `goora_route_map.dart` (+ add to Design gallery and goldens)
- [ ] T013 `lib/features/commute/data/corridor_seed.dart` + `fake_commute_repository.dart` + `providers.dart`
- [ ] T014 ARB keys (prototype copy + research R10 drafts), `lib/features/commute/presentation/labels.dart`
- [ ] T015 `commute_controller.dart` (draft profile, validation, pricing wiring, save/restore)
- [ ] T016 `commute_setup_screen.dart` (place sheets, time steppers, day pills, driver section with stepper/range/recovery, hints, Find CTA) replacing the `/commute-setup` placeholder route
- [ ] T017 [P] `test/widget/commute_screens_test.dart` setup cases (rider/driver × ar/en, defaults, stepper labels, recovery line, disabled states)

## Phase 4: US2 — Find my commute group (P1)

- [ ] T018 `match_result_screen.dart` (chip, title, avatars, members, route, time+days, 4 stats, fee line, why card, others toggle, return-leg line, driver anonymisation, Join)
- [ ] T019 Routes `/match`, `/plan` (004 placeholder), `/today` (003 placeholder); Join saves membership
- [ ] T020 [P] Widget tests for result (ar/en, others toggle, driver view anonymous, Join routing)

## Phase 5: US3 — No match (P2)

- [ ] T021 `no_match_screen.dart` + route `/no-match`, waitlist position, "Post your trip" → `/post-trip` placeholder
- [ ] T022 [P] Widget tests no-match (ar/en)
- [ ] T023 `test/widget/commute_flow_test.dart`: frequency → setup → find → result → join; no-match path; restore after restart

## Phase 6: Server (ready, not deployed)

- [ ] T024 `supabase/migrations/20261005000000_commute.sql`: postgis, tables, geography columns, RLS on every table, owner-only home points
- [ ] T025 `supabase/functions/_shared/matching.ts` mirroring T006/T007 rules (erasable TS only)
- [ ] T026 `supabase/functions/_shared/matching.test.ts` reading `test/fixtures/matching_vectors.json` (`node --test`)
- [ ] T027 `supabase/functions/match/index.ts` thin Deno adapter per contract

## Phase 7: Polish

- [ ] T028 1.3× text scale + tap-target/label guidelines on the 3 new screens; extend no-hard-coded scan (already covers `lib/features`)
- [ ] T029 `flutter analyze`, `flutter test`, `node --test supabase/functions/_shared/`; README: server section + node test command

## Dependencies

Setup → Foundational (T003–T011) → US1 → US2 → US3 → Server (T025–T026 need T011) → Polish.
