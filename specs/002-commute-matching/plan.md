# Implementation Plan: Commute Profile and Smart Matching

**Branch**: `feature/002-commute-matching` | **Date**: 2026-10-05 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-commute-matching/spec.md`

## Summary

Replace the commute-setup placeholder with the real setup screen (places, times, days, driver
offer with pricing stepper), add pure-Dart `PricingService` and `MatchingService` implementing
brief §6.2–6.3 with the founder's clarifications, and add the match-result and no-match screens.
Data comes from a fake `CommuteRepository` seeded with launch-corridor groups. The same matching
rules are written once more in TypeScript for the Supabase Edge Function and both implementations
run one shared set of test vectors. Supabase SQL (PostGIS + RLS) is written, not deployed.

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44; TypeScript (Deno-compatible, tested on Node 24)

**Primary Dependencies**: no new Flutter packages. Server side: none installed (Edge Function uses
Deno std + supabase-js at deploy time).

**Storage**: shared_preferences (fake commute profile, membership, waitlist); Supabase Postgres +
PostGIS schema prepared in `supabase/migrations/`.

**Testing**: flutter_test (unit: pricing, matching, geo, vectors; widget: 3 screens × ar/en; flow);
`node --test` for the TypeScript matching module against the same vectors.

**Target Platform**: Android 7+ / iOS 14+ (app); Supabase Edge Functions (server, later)

**Project Type**: mobile-app + server functions

**Performance Goals**: matching over the corridor pool in < 50 ms on device

**Constraints**: home points never leave the person's own records; Western digits; no keys in repo

**Scale/Scope**: 3 new screens, 2 domain services, ~6 seeded groups, 1 SQL migration, 1 function

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Pre | Post |
|---|---|---|---|
| I Commute-first | Setup + matching are the core commute loop | ✅ | ✅ |
| II Cost-sharing | Suggested = cost ÷ (riders+1); ±20 % in 2 EGP steps; cap riders × price ≤ cost; no bidding | ✅ | ✅ |
| III Arabic-first | All copy in ARB; directional widgets; ar/en widget tests | ✅ | ✅ |
| IV Privacy | Only area names shown; home point private (RLS: owner only); riders anonymous to drivers | ✅ | ✅ |
| V Trust & safety | Matching only among verified profiles (fake data marks all verified) | ✅ | ✅ |
| VI Design system | Reuses core widgets; new map card + time stepper live in `lib/core/widgets` | ✅ | ✅ |
| VII Accessible | ≥ 44 px, labelled steppers/pills; selection not by color alone | ✅ | ✅ |
| VIII Testable | Pure-Dart services + unit tests with brief numbers; shared vectors with server | ✅ | ✅ |
| IX Simplicity | No new packages; time chosen with a stepper, not a new picker package | ✅ | ✅ |
| Secrets / open items | Keys only via `.env`; trip-cost rates behind `ratesEnabled` flag (§8) | ✅ | ✅ |

## Project Structure

### Documentation (this feature)

```text
specs/002-commute-matching/
├── plan.md · research.md · data-model.md · quickstart.md
├── contracts/ (match-function.md, repositories.md)
└── tasks.md
```

### Source Code

```text
lib/core/widgets/
├── goora_time_stepper.dart        # − 7:30 AM + in 5-min steps
└── goora_route_map.dart           # drawn home → work card (no maps key yet)
lib/features/commute/
├── domain/   geo.dart · clock.dart · place.dart · commute_profile.dart · group.dart
│             pricing_service.dart · matching_service.dart · commute_repository.dart
├── data/     fake_commute_repository.dart · corridor_seed.dart · providers.dart
└── presentation/ commute_setup_screen.dart · match_result_screen.dart · no_match_screen.dart
                  commute_controller.dart · labels.dart (area/day/reason → l10n)
lib/features/placeholder/presentation/placeholder_screen.dart   # generalised (title + back)
supabase/
├── config.toml                    # `supabase init` (no Docker started)
├── migrations/20261005000000_commute.sql
└── functions/_shared/matching.ts · matching.test.ts · functions/match/index.ts
test/fixtures/matching_vectors.json  # shared by Dart and Node tests
test/unit/ pricing_service_test.dart · matching_service_test.dart · matching_vectors_test.dart
test/widget/ commute_screens_test.dart · commute_flow_test.dart
```

**Structure Decision**: new `commute` feature folder; server code under `supabase/` as Supabase
expects. The rule logic exists twice by design (device + server) and is pinned by shared vectors.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Matching logic in Dart and TypeScript | Brief: server-side Edge Function, pure logic mirrored in Dart for tests | One copy only on the server can't run offline/fake; one copy only in Dart can't run in the Edge Function. Shared vectors keep them identical. |
