# Contract: Corridor configuration and strings

**Feature**: 006 · Interfaces this feature adds or changes. Shapes only.

## Corridor access (domain)

- `activeCorridor`: read-only value, default Cairo ↔ Ismailia. Switched only by a debug/demo setting and by test helpers; cleared by "Reset demo data".
- Consumers and what they read:

| Consumer | Reads | Replaces |
|---|---|---|
| Commute setup (home / work picker) | `homePlaces`, `workPlaces` | `CorridorSeed.homePlaces / workPlaces` |
| Find riders filter, Offer / Post route form | `areas` | `Area.values` |
| Post your trip, Offer a trip defaults | `defaultFrom`, `defaultTo` | `Area.sheikhZayed`, `Area.smartVillage` |
| Marketplace offers and requests | `tripMinutes(from, to)` | `_tripMinutes = 40` |
| Wallet and pricing | `tripCost` (cost, seats) | `demoCorridorCost` |
| No-match / waitlist copy | area names of the user's route | fixed route names |

- The old corridor is a second `Corridor` value with its current data. No behaviour of it changes.

## Leg rule

`leg(from, profile)` → going when `from` is the person's home area (or the corridor default origin with no profile), else return. Replaces the `== Area.smartVillage` check in `offer_trip_controller` and `post_trip_screen`.

## Localization (ARB, ar default + en)

New keys (names are drafts for founder review, tone per `goora-brand`):

| Group | Keys |
|---|---|
| Areas (6) | `areaNewCairo`, `areaNasrCity`, `areaHeliopolis`, `areaObour`, `areaTenthOfRamadan`, `areaIsmailia` |
| Stop names (6) | `stopNewCairoMeet`, `stopNasrCityMeet`, `stopHeliopolisMeet`, `stopObourMeet`, `stopTenthOfRamadanMeet`, `stopIsmailiaMeet` |
| Arrival points | reuse the stop keys for the Ismailia and Cairo ends |

Rules: no hard-coded strings; Arabic in Egyptian colloquial; each new key exists in both ARB files (a missing key fails the existing ARB parity test); numbers, times and place names are bidi-isolated as elsewhere.

## Documents (already amended on this branch)

Brief §2 table, §5 heading, §6.1, no-match copy, one example reason; Constitution 1.0.1 (rationale, roadmap order, Sync Impact Report).
