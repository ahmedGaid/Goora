# Data Model: Cairo ↔ Ismailia Launch Corridor

**Feature**: 006 · **Date**: 2026-10-16 · Shape only; no implementation code.

## Area (extended)

Existing: `sheikhZayed`, `october`, `smartVillage`.
Added: `newCairo`, `nasrCity`, `heliopolis`, `obour`, `tenthOfRamadan`, `ismailia`.
- Persisted by name (`Area.values.byName`); adding values is backward compatible with saved demo data.
- Shown by localized name only; never as coordinates.

## Corridor (new value, domain layer)

| Field | Meaning |
|---|---|
| `id` | `cairoIsmailia` or `sheikhZayedSmartVillage` |
| `areas` | The areas this corridor shows in filters and forms (ordered) |
| `homePlaces` / `workPlaces` | Places offered during commute setup |
| `defaultFrom` / `defaultTo` | Defaults for Post your trip and Offer a trip |
| `tripCost` | Demo cost per leg and rider seats: `(300, 3)` for Cairo ↔ Ismailia, `(160, 3)` for the old one |
| `tripMinutes(from, to)` | Door-to-door duration used by marketplace offers and requests |

Rules:
- Exactly one corridor is **active**; the new corridor is the app default.
- A corridor's `areas` never include another corridor's areas.
- `tripCost` is a demo value; real rates stay behind `ratesEnabled` (brief §8).

## Place and Stop (existing, new data)

- `Place(id, area, point)`: one per new area, ids `home-nc`, `home-nasr`, `home-heli`, `home-obour`, `home-10r`, `home-ism`, `work-*` as needed. Points are recalled centres (research R7).
- `Stop(id, name, point, time)`: 1–2 per area. `StopName` gains one generic meeting-point name per area (localized).

## CommuteGroup (existing, new instances)

Same fields as today. For this corridor:
- `origin → destination` is the **going** direction. Cairo → Ismailia and Ismailia → Cairo are separate groups.
- `tripCost = 300`, `riderSeats = 3`, `price = 76`, `arrival` always set (never the 40-minute default).
- Invariant kept from 004: `riders + freeSeats ≤ riderSeats` per leg; `price ∈ range(300, 3) = 62–90`.

## Marketplace seed (existing structures, new data)

`TripRequest`, `OfferedTrip`, rider/driver pools: same counts as today, re-keyed to the corridor's areas. `detourFrom` maps are keyed by `corridor.areas`.

## Leg rule (behaviour)

`leg = going` when `from` equals the person's home area (or the corridor default origin with no profile), otherwise `return`.

## State and persistence

No new persisted fields except the active corridor id (a demo setting, cleared by "Reset demo data"). Everything else is static seed data.
