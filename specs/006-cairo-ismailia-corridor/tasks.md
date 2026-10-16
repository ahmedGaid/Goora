---
description: "Task list for feature 006: Cairo ↔ Ismailia launch corridor"
---

# Tasks: Cairo ↔ Ismailia Launch Corridor

**Input**: `specs/006-cairo-ismailia-corridor/` (plan, spec, research R1–R10, data-model, contracts, quickstart, cap_sweep.ts)

**Tests**: REQUIRED — Constitution VIII. Write the test first, watch it fail, then change code.
Pricing vectors are shared by Dart and TS. Widget tests run in ar + en. Seed invariants and the
ARB parity test guard data and strings.

**Order** (risk first, matches plan P0–P7): Cap proof (done) → Spike → Rules + vectors → Areas,
`Corridor`, strings → Replace hard-coded uses → Seed data → Screens → Device walk + docs.
Each phase ≈ one session and ends on a green checkpoint that can be committed alone.

**Do not touch** (R10): pricing formulas, fee rule, cash rule, matching weights and limits,
subscription and wallet logic, the 9 PM rule, the 2-trips-per-day limit. Data, areas, defaults,
durations and the cap proof only.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency)
- **[US1–US4]**: user story from spec.md. US1 match · US2 price · US3 both directions + marketplace · US4 documents
- Paths are from the repo root (worktree `D:/Company/80-Worktrees/Goora-006`)

## Gates (run at each checkpoint)

```bash
flutter analyze
flutter test --concurrency=1
node --test "supabase/functions/_shared/*.test.ts"
node specs/006-cairo-ismailia-corridor/cap_sweep.ts
```

---

## Phase P0: Cap proof — DONE

- [x] T000 [US2] `specs/006-cairo-ismailia-corridor/cap_sweep.ts`: 300 EGP/leg, 80 combos, 6,588 across costs 100–1000, 0 over the cap. Re-run only if the cost number changes.

---

## Phase P1: Spike — flip the default, count failures (riskiest unknown)

**Goal**: choose "old tests default to old corridor" vs "default to new" with a number.

- [x] T001 Record baseline: run the gates; write the passing counts (expect 1,085 Flutter / 148 Node) at the top of `research.md` under a new "P1 spike result" heading.
- [x] T002 Throwaway spike (do not commit code): in a scratch change make the six new areas exist and make them the default in `lib/features/commute/data/corridor_seed.dart` + `providers.dart`; run `flutter test --concurrency=1`; count failing files and tests. Then `git restore` the spike.
- [x] T003 Write the result and the decision (R4: "tests default old" via one shared helper, unless the count is small) into `research.md`; commit docs only.

**Checkpoint**: failing-test count and the chosen approach are written down. Tree clean of spike code.

---

## Phase P2: Rules and vectors (US2, legal)

**Goal**: the 300 EGP numbers live in the shared fixtures that both languages run. No formula change.

- [ ] T004 [US2] Extend `test/fixtures/gen_pricing_vectors.py` with the contract rows (seats 3: 62/76/90; seats 4: 48/60/72; wallet 300) plus subscriber and cash variants for the 3-seat rows. Existing rows stay byte-identical.
- [ ] T005 [US2] Regenerate `test/fixtures/pricing_vectors.json`; diff shows only added rows.
- [ ] T006 [P] [US2] Run the existing Dart vector test (`test/unit/pricing_service_test.dart`, `pricing_cap_sweep_test.dart`) and `supabase/functions/_shared/pricing.test.ts` against the new rows; both green with no code change. If a row fails, stop and report — it means the contract is wrong, not the rule.
- [ ] T007 [P] [US2] Extend `test/unit/pricing_cap_sweep_test.dart` (reuse its helper) with a 300 EGP sweep, seats 1–4, every allowed price: rider total ≤ equal share, full car ≤ 300 (mirror of `cap_sweep.ts`; reuse the 004 sweep helper) in `test/unit/`.
- [ ] T008 [US2] Extend the 004 `corridor_seed_invariant_test.dart` with the corridor-group rules: `riders + freeSeats ≤ 3` both legs, `price ∈ [62, 90]`, `arrival` always set (R6). Expect it to fail until P5 seeds exist (mark clearly; do not skip).

**Checkpoint**: vector tests green in Dart + TS; `cap_sweep.ts` exits 0.

---

## Phase P3: Areas, `Corridor`, places, stops, strings (US1, foundation)

**Goal**: the new data exists and compiles; nothing yet reads it.

- [ ] T009 Add 6 values to `Area` in `lib/features/commute/domain/place.dart`: `newCairo, nasrCity, heliopolis, obour, tenthOfRamadan, ismailia`. Fix the exhaustive `switch`es the compiler flags (labels, `market_seed` maps) with temporary neutral branches only if needed.
- [ ] T010 Test first: `test/unit/` — saved demo data with the old three area names still loads (`Area.values.byName`), and a new name round-trips.
- [ ] T011 [P] [US1] Create `lib/features/commute/domain/corridor.dart`: `Corridor` value (`id, areas, homePlaces, workPlaces, defaultFrom, defaultTo, tripCost (cost, seats), tripMinutes(from,to)`), two instances `cairoIsmailia` and `sheikhZayedSmartVillage` (old data moved over unchanged: cost 160, seats 3, 40 min).
- [ ] T012 [US1] Corridor unit tests in `test/unit/`: a corridor's `areas` never include another's; `tripMinutes` is symmetric and ≈105 / 90 min by pair (R6); defaults are inside `areas`.
- [ ] T013 [P] [US1] Create `lib/features/commute/data/cairo_ismailia_seed.dart`: one `Place` per area (ids `home-nc`, `home-nasr`, `home-heli`, `home-obour`, `home-10r`, `home-ism`, work as needed), 1–2 `Stop`s per area, points from R7 each marked `// recalled`. Groups come in P5.
- [ ] T014 [P] [US1] Add 12 ARB keys to `lib/l10n/app_ar.arb` (Egyptian) and `app_en.arb`: `areaNewCairo, areaNasrCity, areaHeliopolis, areaObour, areaTenthOfRamadan, areaIsmailia, stopNewCairoMeet, stopNasrCityMeet, stopHeliopolisMeet, stopObourMeet, stopTenthOfRamadanMeet, stopIsmailiaMeet`. Copy per `goora-brand`; drafted, marked for founder review. Run codegen for l10n.
- [ ] T015 [US1] Add 6 `StopName` values in `lib/features/commute/domain/group.dart` (`newCairoMeet … ismailiaMeet`). Remove the old-corridor leak at the default arrival (`arrivalName ?? StopName.smartVillageGate2`, ~line 259): the default must come from the group's own stop, never a fixed old name. Wire labels in `lib/features/commute/presentation/labels.dart` **and** `lib/features/daily/presentation/labels.dart` (both switch on `StopName`). Test: every `Area` value and every seeded stop has a non-empty ar and en label (a missing name fails, spec edge case).
- [ ] T016 [US1] Active-corridor provider in `lib/features/commute/data/providers.dart`: default `cairoIsmailia`; persisted corridor id (demo setting, SharedPreferences); cleared by "Reset demo data". Test the default, the switch, and the reset.
- [ ] T017 Add the shared test helper in `test/helpers/daily_fakes.dart` (and `pump_app.dart` if needed): override `activeCorridor` to the old corridor by default for existing tests, per the T003 decision. New-corridor tests opt in explicitly.

**Checkpoint**: analyze 0 issues; ARB parity green; full suite still green (nothing reads the new corridor yet).

---

## Phase P4: Replace hard-coded uses (US1, US3)

**Goal**: filters, forms, defaults, leg rule and durations all read the active corridor.

- [ ] T018 [US3] Test first, both directions: leg rule R5 — `leg(from, profile)` is going when `from` equals the person's home area (or the corridor default origin with no profile), else return. Put the rule in `corridor.dart` or a small helper; cover profile and no-profile, going and return.
- [ ] T019 [US3] Replace the `== Area.smartVillage` check in `lib/features/marketplace/presentation/offer_trip/…controller` and `post_trip/post_trip_screen.dart` with the leg rule. Old-corridor tests stay green.
- [ ] T020 [P] [US1] `fake_commute_repository.dart`: `homePlaces / workPlaces` come from the active corridor (replaces `CorridorSeed.homePlaces / workPlaces`).
- [ ] T021 [P] [US3] Replace `Area.values` with `corridor.areas` in `find_riders/find_riders_screen.dart`, `route_form.dart`, and the trip-request model/form. Test: with the new corridor active the filter lists exactly the six areas.
- [ ] T022 [P] [US3] Defaults in `post_trip_controller.dart` (lines ~51–52 fall back to `Area.sheikhZayed` / `Area.smartVillage`) and `offer_trip_controller.dart` read `corridor.defaultFrom / defaultTo` (replaces `Area.sheikhZayed` / `Area.smartVillage`).
- [ ] T023 [US3] `fake_marketplace_repository.dart`: replace `_tripMinutes = 40` with `corridor.tripMinutes(from, to)` for all 9 offers and requests (R6). Test: durations on the new corridor are 90–105, old corridor still 40.
- [ ] T024 [P] [US2] Trip cost comes from the corridor, not the fixed `demoCorridorCost = 160` default in `PricingConfig` (`lib/features/commute/domain/pricing_service.dart`, used at ~line 40). Pass the active corridor's cost into the config where it is built; do not change any formula. Test: new corridor 300, old 160; existing `pricing_service_test.dart` unchanged and green.
- [ ] T025 [US1] No-match and waitlist copy takes the user's route area names (FR-011). Check whether the existing key already interpolates the route; add or adjust only if not. Test ar + en: "You're #N on the Heliopolis → Ismailia list".

**Checkpoint**: full suite green with the old corridor as test default; new unit tests green with the new corridor.

---

## Phase P5: Seed groups and marketplace data (US1, US3)

**Goal**: ≥ 3 groups per direction and the marketplace re-keyed. Sonnet fits.

- [ ] T026 [US1] Test first (fails until seed exists): seeds contain ≥ 3 groups per direction; one women-only-friendly; one full (waitlist demo); free seats 0–2; times going 06:30–07:30, return 16:30–17:30; Sun–Thu; `arrival` set on every group (none uses `Group.defaultTripMinutes`).
- [ ] T027 [US1] Seed the groups in `cairo_ismailia_seed.dart`: 3 Cairo→Ismailia, 3 Ismailia→Cairo minimum, `tripCost = 300`, `riderSeats = 3`, `price = 76`. T008 invariants go green.
- [ ] T028 [P] [US3] `market_seed.dart`: mirror the 12 morning + 4 evening requests and the driver/rider pools with the new areas; `detourFrom` keyed by `corridor.areas`; same row counts so existing counts and banners keep working. Keep old rows for the old corridor.
- [ ] T029 [US3] Marketplace seed tests: row counts unchanged per corridor; no request or offer on the new corridor references an old-corridor area.
- [ ] T030 [US1] Match test per direction through `matching_service` with the new seed: New Cairo→Ismailia and Ismailia→Nasr City each return ≥ 1 group; Heliopolis home with a no-group time returns no match. Matching limits unchanged.

**Checkpoint**: seed invariants and match tests green; suite green.

---

## Phase P6: Screens in ar + en (US1, US3)

**Goal**: every touched screen shows only corridor data, ar RTL and en LTR, at 1.3× text.

- [ ] T031 [P] [US1] Widget tests ar + en: onboarding home/work pickers list the six areas only; match result shows driver, pickup meeting point, 06:30, arrival ≈ 08:15, price 76, pay line 76 + 8 (wallet) and 75 cash.
- [ ] T032 [P] [US1] Widget tests ar + en: no-match screen names the user's route and offers the post-a-request button.
- [ ] T033 [P] [US3] Widget tests ar + en: Today, Week, Wallet show only corridor names, stops, times and prices (SC-005).
- [ ] T034 [P] [US3] Widget tests ar + en: Empty seats, Post your trip, Offer a trip, Find riders use corridor areas and defaults; the Ismailia→Cairo offer sits on the return side, ≈ 105 min.
- [ ] T035 [US3] Text-scale 1.3× and bidi checks on the new strings (names, times, numbers isolated as elsewhere); fix only layout/clipping found.
- [ ] T036 [US3] Goldens RTL + LTR for the match result and one marketplace card on the new corridor, only where existing screens already have goldens.
- [ ] T037 [US3] FR-008 + SC-005 guard: also assert no raw coordinates appear on screen (Constitution IV). SC-005 guard test: with the new corridor active, scan rendered text of the walk screens (ar + en) for "Sheikh Zayed", "Smart Village", and the Arabic names; expect none.
- [ ] T038 Run the `goora-brand` checklist (copy, RTL, 44 px targets, ≥ 4.5:1 contrast). Fix findings.

**Checkpoint**: gates green. Brand checklist clean.

---

## Phase P7: Device walk and docs (US4, close)

- [ ] T039 Boot the emulator with `D:\Company\99-Ops\start-emulator.ps1` (never the personal phone). Walk `quickstart.md` §0–§7. Record results in `research.md` (what passed, anything off). Check SC-001 (< 2 min welcome → match).
- [ ] T040 [P] [US1] Map check of the six recalled centres (R7). Fix the points, drop the `// recalled` marks, re-run T030. Founder may do this check; if not done, leave the marks and list it as open.
- [ ] T041 [P] [US4] Verify SC-006: search brief, constitution and roadmap for the old corridor as "the launch corridor"; none unmarked. Brief and constitution 1.0.1 were amended on this branch already — confirm the roadmap row and company-network number.
- [ ] T042 Update `goora-status` (position, NEXT ACTION, blocker). Write `Docs/NEXT_GOAL.md` from live git (`git log --oneline -12 main`, `git branch --merged main`, `git status`).
- [ ] T043 Final gates (4 commands above). Commit. Push **only with the founder's OK**. Merge only with the founder's OK.

---

## Dependencies and order

- P1 first. Its result can change T017 and the amount of work in P4.
- P2 is independent of P3+ (data in fixtures) and can run in parallel with P3 if sessions are split; T008 stays red until P5.
- P3 → P4 → P5 → P6 in order (each reads the previous).
- Inside a phase, [P] tasks touch different files and can run together.
- P7 last. Irreversible steps (push, merge) are last and need the founder.

## Model fit

| Phase | Fit | Why |
|---|---|---|
| P1, P4 | Opus | Judgment: spike decision, leg rule, touches many files |
| P2, P5 | Sonnet | Clear spec, data and vectors |
| P3 | Sonnet | Mechanical with a clear contract |
| P6 | Sonnet | Widget tests from a script |
| P7 | Opus or Sonnet | Walk + docs; Sonnet is enough |

## Open items (do not block tasks)

Trip cost 300 EGP unverified · map check R7 · founder review of ar/en names · whether Obour / 10th of Ramadan are real pickup areas at launch · legal per-trip fee (brief §8) · F1/F14/F15 and trip = leg vs day (outside 006).
