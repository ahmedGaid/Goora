# Research: Cairo ↔ Ismailia Launch Corridor

**Feature**: 006 · **Date**: 2026-10-16 · Every fact is tagged **verified** (checked this session, source named), **proven** (run this session), **recalled** (from memory, not checked) or **guess**.

## P1 spike result (2026-10-16) — proven, run this session

- **Baseline** (main logic, branch `006` @ 75488cb): `flutter analyze` 0 issues · `flutter test --concurrency=1` **1,085 pass** · `node --test` **148 pass**.
- **Spike** (throwaway, restored, nothing committed): added the 6 new `Area` values; new corridor made the default in `CorridorSeed.homePlaces/workPlaces`, offer/post-trip controller defaults and leg rule, and the area pills in `find_riders_screen` + `route_form`. `flutter analyze` 0 issues (exhaustive switches got a `_` arm).
- **Result**: **13 failing tests in 6 files** out of 1,085: `find_riders_test` 4 · `commute_screens_test` 2 · `marketplace_navigation_test` 2 · `offer_trip_test` 2 · `post_trip_test` 2 · `commute_flow_test` 1. The other ~28 files that mention the old corridor kept passing because the seeded groups, offers and requests stayed on the old areas.
- **Limit**: lower bound. The spike did not replace seed groups/market data or the 40-minute durations (R6); those are added beside the old data, not over it, so the old-data tests should stay green.
- **Decision (R4 confirmed, simplified)**: the new corridor is the **app default**. The 6 failing files pin the old corridor with a one-line `activeCorridor` override in their setup (no shared-helper rewrite of 34 files). New corridor gets its own ar + en tests. Re-count after P3; if it grows past ~10 files, switch to one shared helper.

## R1 — Route facts (risk: durations and stop times)

- **Decision**: Seed trips take **105 minutes door-to-door arrival** for Cairo ↔ Ismailia legs (departure → arrival), and 15–25 minutes less for legs that start in a road town.
- **Evidence**:
  - Road distance Cairo → Ismailia is about 123 km. **Verified** from a distance reference ([rome2rio](https://www.rome2rio.com/s/Cairo/Ismailia)); a transfer operator quotes about 130 km.
  - Drive time is 1h30 to 2h depending on traffic. **Verified** from the same two sources. 105 min is the middle of that band.
  - The desert road is being widened toward a freeway; the source is undated. **Verified, undated.**
  - Tolls: **no figure found.** A third-party guide says the Cairo–Ismailia–Port Said road is tolled with an electronic system in a first phase (**unverified**, non-official). No per-gate EGP amount was found for Obour or 10th of Ramadan.
- **Alternatives considered**: use the old 40-minute default (wrong for 123 km); use 90 or 120 minutes (the ends of the band, so more extreme).
- **Open**: real toll amount and fuel price. These feed the 300 EGP placeholder (R2). A founder or local check is needed before any public price claim.

## R2 — Trip cost and the Constitution II cap proof (risk: legal)

- **Decision**: Corridor trip cost is **300 EGP per leg**, `riderSeats = 3`, kept as a demo value in the existing trip-cost config (`demoCorridorCost`-style, per corridor). Real per-km rates stay off (`ratesEnabled = false`, brief §8).
- **Proven** (`cap_sweep.ts` in this folder, runs the real `pricing.ts` twin):
  - 300 EGP, 3 seats: suggested **76**, range **62–90**, equal share **100**. Top price 90 + fee 9 = 99 ≤ 100. A full car of 3 pays at most 297 ≤ 300.
  - 300 EGP, 4 seats: range 48–72, top price + fee = 75 = equal share, full car = exactly 300 (cap holds with zero room).
  - 300 EGP, 1 and 2 seats: pass.
  - **80** price/seat combinations at 300 EGP and **6,588** combinations over costs 100–1000 (step 20): **0 over the cap.**
  - Cash for the suggested 76 → **75** (multiple of 5, inside 62–90).
- **Why the placeholder is safe to build on**: the cap is a property of the rule, not of 300. If the founder changes the number, the same sweep re-proves it in seconds.
- **Plausibility, guess**: 300 EGP ÷ 123 km ≈ 2.4 EGP/km before sharing. Not checked against fuel + toll + running cost. Mark as demo in code and docs.
- **Alternatives considered**: keep 160 (wrong for the distance; a 160 EGP price for 123 km would look unrealistic on camera); derive from km × rate (rates are an open legal/commercial item).

## R3 — Matching thresholds on a long route (risk: matching fails or looks wrong)

Hard limits today (`MatchingLimits`): pickup ≤ 1000 m from home, destination ≤ 1500 m, driver detour ≤ 10 min (read from the group), departure difference ≤ 20 min.

- **Decision**: **Keep all four limits unchanged.** They are measured at the two ends and in minutes, so they do not depend on route length.
  - Pickup and destination use one approximate point per area. A rider whose work place is the Ismailia area centre is within 1500 m of a group whose destination point is the same centre. Same pattern as Smart Village today.
  - Detour: seeded groups keep 3–6 min (a pickup on the road costs minutes, not tens of minutes). The 10-min limit still blocks a driver who would add a long loop.
  - Departure ±20 min: unchanged. Early departures (06:30) are why the demo times differ from the old corridor.
- **Known limitation**: Ismailia and the Cairo districts are wider than 1500 m. One centre point per area is a demo simplification, like the old corridor's single Smart Village point. Real maps, `Place` precision and per-corridor `MatchingLimits` are a later feature (backend). Recorded, not built.
- **Alternatives considered**: raise destination radius to ~5 km (weakens the "shared workplace" idea and changes 44 matching vector rows); per-corridor limits now (extra config, no demo need).

## R4 — Areas, Corridor concept, and hiding the old corridor (risk: SC-005 and regression)

Facts from the code (**verified by grep**):
- `Area` is an enum with 3 values used in exhaustive `switch`es (labels, `market_seed` stop/detour maps) and in iteration (`Area.values` in `find_riders_screen`, `route_form`, `trip_request`). Defaults hard-code `Area.sheikhZayed` / `Area.smartVillage` in post-trip and offer-trip controllers.
- 34 test files and 288 mentions reference the old corridor.
- `CorridorSeed.homePlaces / workPlaces` feed onboarding through `CommuteRepository`.

- **Decision**: Add a small `Corridor` value (id, areas, home places, work places, trip cost config, default from/to) and an `activeCorridor` provider. Add the 6 new `Area` values. Every place that iterated `Area.values` iterates `corridor.areas` instead. The new corridor is the app default; the old corridor stays selectable and is the default in the **existing** tests (set once in the shared test helpers) so they keep guarding the old behaviour. New tests cover the new corridor in ar + en.
- **Why not delete the old corridor**: 34 test files and the rule "no regression on 1,085 + 148 tests".
- **Why not just add areas to the same list**: filters and forms would show Sheikh Zayed next to Ismailia, which breaks SC-005.
- **Spike first (task 1)**: flip the default and count failing tests before choosing between "tests default old" and "tests default new". If the count is small the plan simplifies.

## R5 — Leg direction in the marketplace forms (risk: wrong leg)

Today `offer_trip_controller` and `post_trip_screen` decide the leg with `from == Area.smartVillage ? ret : going`. With two directions that rule is wrong.

- **Decision**: leg = **going** when `from` equals the person's own home area (or, with no profile, the corridor's default origin), otherwise **return**. Groups keep `origin → destination` as going; an Ismailia → Cairo group simply has `origin = ismailia`. Needs a test for both directions.
- **Alternative**: infer from time of day (morning = going). Rejected: breaks the demo clock and evening one-offs.

## R6 — Hard-coded 40-minute trip duration (risk: absurd ETAs)

`fake_marketplace_repository.dart` uses `_tripMinutes = 40` for 9 offers and requests; `Group.defaultTripMinutes = 40` applies when a group has no `arrival`.
- **Decision**: marketplace durations come from the corridor (105 / 90 min by area pair); every seeded group sets `arrival` explicitly. Add a test that no seeded corridor group relies on the default.

## R7 — Stops, places and approximate centres (risk: geography wrong)

- **Decision**: one `Place` per area and 1–2 named `Stop`s per area. Coordinates are **recalled**, rounded to two decimals, and used only for the distance maths in matching:

| Area | Role | Approx. centre (recalled) |
|---|---|---|
| New Cairo | home / work | 30.03, 31.47 |
| Nasr City | home / work | 30.06, 31.34 |
| Heliopolis | home / work | 30.09, 31.32 |
| Obour | home, on the road | 30.23, 31.48 |
| 10th of Ramadan | home, on the road | 30.29, 31.75 |
| Ismailia city | home / work | 30.60, 32.27 |

- **Check**: a one-time map check of these six points is task 2 of the plan. Until then they are marked `// recalled` in the seed.
- Stop names are generic meeting-point names (one per area), drafted in Arabic and English for founder review, like earlier features' copy keys. No real landmark names are claimed.
- Privacy (Constitution IV): only area names and stops are shown; points are never displayed.

## R8 — Seed shape (both directions) and the marketplace data

- **Decision**: at least **3 groups per direction**; free seats between 0 and 2; one women-only-friendly group; one full group (waitlist demo); all with 3 rider seats at 300 EGP, price 76 (inside 62–90). Going times 06:30–07:30, return 16:30–17:30 on working days (Sun–Thu, existing default days).
- Marketplace seed: mirror the 12 morning + 4 evening requests and the driver/rider pools with the new areas, detour maps keyed by the corridor's areas. Same row count so the existing counts and banners keep working.
- Waitlist copy uses the corridor's names ("You're #N on the New Cairo → Ismailia list").

## R9 — Localization

- New keys: 6 area names, the stop names, corridor-aware no-match text if the existing key interpolates the route (check). All ar (Egyptian) and en. Drafted copy goes to founder review; tone follows `goora-brand`. No hard-coded strings.

## R10 — What this feature must NOT touch

Pricing formulas, fee rule, cash rule, matching weights, subscription and wallet logic, the 9 PM rule, the 2-trips-per-day limit. Only data, areas, defaults, durations and the cap proof.

## Open items for the founder (none block `/speckit-tasks`)

1. Real trip cost: fuel price, tolls, running cost for 123 km (replaces the 300 EGP placeholder).
2. Whether road towns (Obour, 10th of Ramadan) are real pick-up areas at launch or demo-only.
3. Review of the drafted Arabic copy for the six areas and their stops.
4. Legal: per-trip service fee (brief §8) still open; unchanged by this feature.
