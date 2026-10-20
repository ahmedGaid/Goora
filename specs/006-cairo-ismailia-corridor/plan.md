# Implementation Plan: Cairo ↔ Ismailia Launch Corridor

**Branch**: `006-cairo-ismailia-corridor` | **Date**: 2026-10-16 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-cairo-ismailia-corridor/spec.md`

## Summary

Make Cairo ↔ Ismailia the app's default launch corridor as **data and defaults**, not new rules. Add six areas, a small `Corridor` value (areas, places, trip cost, defaults, durations), seeded groups and marketplace demand in both directions, localized names, and the Constitution II cap proof on 300 EGP per leg. The old Sheikh Zayed → Smart Village corridor stays as a second corridor so the existing 1,085 Flutter and 148 Node tests keep guarding it. The cap proof is already run and clean (80 combinations at 300 EGP, 6,588 across costs 100–1000, 0 over). Biggest risks, in order: (1) the legal cap (done), (2) hiding the old corridor everywhere without breaking 34 test files, (3) wrong leg direction and 40-minute durations in the marketplace.

## Technical Context

**Language/Version**: Dart 3 / Flutter (latest stable); TypeScript for Supabase edge-function twins (run with `node --test`)

**Primary Dependencies**: flutter_riverpod, go_router, flutter_localizations + intl (ARB). **No new packages** (Constitution IX).

**Storage**: Fake repositories + SharedPreferences-backed demo data. One new demo setting: the active corridor id (cleared by Reset demo data).

**Testing**: `flutter analyze`, `flutter test --concurrency=1`, `node --test "supabase/functions/_shared/*.test.ts"`, `node specs/006-cairo-ismailia-corridor/cap_sweep.ts`. Shared vector fixtures run by both Dart and TS.

**Target Platform**: Android (min API 24) and iOS 14+; walked on the emulator `Goora_Test`.

**Project Type**: Mobile app (feature-first `lib/features/<feature>/{data,domain,presentation}`)

**Performance Goals**: Not performance-bound. Matching over a handful of seeded groups.

**Constraints**: ar (RTL) and en (LTR) on every touched screen; no hard-coded strings/colours; 44 px targets; ≥ 4.5:1 contrast; Goora stays on fake repositories and the fake payment provider.

**Scale/Scope**: 6 new areas, ~6–8 seeded groups, ~16 marketplace requests, about 12 new localized strings, 34 existing test files whose setup may need one shared helper change.

## Constitution Check

*Version 1.0.1. Gate before research (passed) and again after design (below).*

| Principle | Result |
|---|---|
| I Commute-First | Pass. Fixed-day commute is the product; occasional travel only through 005 one-offs (spec assumption). |
| II Cost-sharing, never a taxi (NON-NEGOTIABLE) | **Pass, proven.** No formula changes. `cap_sweep.ts` shows 0 breaches at 300 EGP (seats 1–4) and across 6,588 combinations. Range stays ±20 %, 2 EGP steps; no bidding; 2-trips-per-day unchanged. |
| III Arabic-first, RTL-correct | Pass. Six area keys + six stop keys in both ARBs; widget tests ar + en. |
| IV Privacy | Pass. Area and stop names only; points never displayed. |
| V Trust and safety | Pass. No change to OTP, ID, SOS, trip sharing. |
| VI One design system | Pass. No new styling. |
| VII Accessible | Pass. No new controls; existing 1.3× text tests cover new data. |
| VIII Testable architecture | Pass. Domain rules stay pure Dart + TS twins; new vector rows; seed-invariant and corridor tests. |
| IX Simplicity | **Watch.** One new abstraction (`Corridor`). Justified below. |

### Post-design re-check
Design adds only data, a read-only `Corridor` value and an active-corridor setting. No rule, formula or limit changes. Gate passes.

## Complexity Tracking

| Addition | Why needed | Simpler alternative rejected because |
|---|---|---|
| `Corridor` value + active-corridor setting | The old and new areas must not appear together in filters and forms (SC-005), and defaults and durations must follow the active corridor | Adding six values to `Area` alone makes every `Area.values` list show both corridors; deleting the old corridor breaks 34 test files and the no-regression gate |

## Phases and order (risk first)

| # | Phase | Goal | Done when |
|---|---|---|---|
| P0 | Cap proof + number check | Legal boundary on 300 EGP | **Done:** `cap_sweep.ts` exits 0 |
| P1 | Spike: flip default, count failures | Choose "tests default old" vs "tests default new" (research R4) | Failing-test count written in research.md |
| P2 | Rules and vectors | New pricing vector rows (Dart + TS), seed-invariant extension | `flutter test` unit + `node --test` green |
| P3 | Areas, `Corridor`, places, stops | Six areas, corridor value, places, stop names, ARB keys | analyze 0; ARB parity green |
| P4 | Replace hard-coded uses | Filters, forms, defaults, leg rule (R5), durations (R6) read the corridor | Old-corridor tests still green |
| P5 | Seed groups both directions + marketplace data | ≥ 3 groups per direction; requests and pools re-keyed | Seed invariants green |
| P6 | Screens in ar + en | Match result, Today, Week, Wallet, Empty seats, Post, Offer on the new corridor | Widget tests ar + en green |
| P7 | Device walk and docs | Quickstart on the emulator; status + hand-off | Walk results in research.md |

## Project Structure

### Documentation (this feature)

```text
specs/006-cairo-ismailia-corridor/
├── spec.md
├── plan.md              # This file
├── research.md          # Route facts, cap proof, risks, decisions
├── data-model.md        # Areas, Corridor, groups, leg rule
├── cap_sweep.ts         # Constitution II proof against the real pricing twin
├── quickstart.md        # Validation scenarios
├── contracts/
│   ├── pricing-corridor.md   # Numbers, fixture rows, required tests
│   └── corridor-config.md    # Corridor access, leg rule, ARB keys
├── checklists/requirements.md
└── tasks.md             # Next step (/speckit-tasks) — not created here
```

### Source Code (repository root)

```text
lib/
├── features/commute/
│   ├── domain/place.dart                 # Area enum + 6 values
│   ├── domain/corridor.dart              # NEW: Corridor value, two instances
│   ├── data/corridor_seed.dart           # keeps the old corridor; new seed file beside it
│   ├── data/cairo_ismailia_seed.dart     # NEW: places, stops, groups
│   ├── data/fake_commute_repository.dart # homePlaces/workPlaces from the active corridor
│   └── presentation/labels.dart          # area + stop labels
├── features/marketplace/
│   ├── data/market_seed.dart             # rows re-keyed per corridor
│   ├── data/fake_marketplace_repository.dart  # durations from the corridor
│   └── presentation/{find_riders,post_trip,offer_trip,route_form}…  # corridor areas, defaults, leg rule
├── features/wallet/data/                 # trip cost from the corridor
└── l10n/app_ar.arb, app_en.arb           # 12 new keys

supabase/functions/_shared/               # pricing.ts unchanged; vectors only
test/
├── fixtures/{pricing_vectors.json,gen_pricing_vectors.py}  # new rows
├── helpers/daily_fakes.dart              # active-corridor override for old-corridor tests
└── unit|widget|golden/                   # new corridor tests, ar + en
```

**Structure Decision**: Keep the existing feature-first layout. One new domain file (`corridor.dart`) and one new seed file; everything else is edits to existing files.

## Risks

1. **Old-corridor test churn** (34 files). Mitigation: P1 spike first; one shared helper decides the default for old tests.
2. **Leg rule regression** in the marketplace (R5). Mitigation: test both directions before touching screens.
3. **Recalled geography** (R7). Mitigation: one map check before seed numbers are final; marked `// recalled` until then.
4. **Placeholder price on camera.** Mitigation: demo-marked in code and docs; founder replaces before any public price claim.

## Out of scope

Real maps, tolls and fuel rates, per-corridor matching limits, backend deployment, company network (later, unnumbered), any pricing rule change.
