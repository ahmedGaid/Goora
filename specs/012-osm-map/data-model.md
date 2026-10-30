# Data model: Pickup-point map (012)

No stored data. Value types only (all in `lib/core/map/`).

## MapConfig

| Field | Type | Source | Notes |
|---|---|---|---|
| urlTemplate | String | `MAP_TILE_URL_TEMPLATE` | empty → tiles off |
| apiKey | String | `MAP_TILE_API_KEY` | fills `{key}` in the template |
| extraAttribution | String | `MAP_TILE_ATTRIBUTION` | provider credit, optional |
| hasTiles | bool (derived) | `urlTemplate.trim().isNotEmpty` | |

## PickupPinKind

`pickup` (numbered, `primary` fill) · `arrival` (flag icon, `mapDestination` fill).

## PickupPin

| Field | Type | Notes |
|---|---|---|
| kind | PickupPinKind | |
| lat, lng | double | copied from `Stop.point` — a public meeting point |
| number | int? | 1-based driving order for pickups; null for arrival |
| title | String | e.g. "التجمع · 7:20" / "Pickup · 7:20" (existing `tlPickup`/`tlArrival`) |
| place | String | stop name (`l10n.stopName`) |

Construction: `PickupPin.pickup(Stop stop, {required int number, required String title, required String place})`,
`PickupPin.arrival(Stop stop, {required String title, required String place})`. No public constructor.

## PickupMapScene

| Field | Type | Notes |
|---|---|---|
| pins | List<PickupPin> | ≥ 1, in driving order, arrival last |
| expanded | bool | false = static card preview; true = big sheet (tiles may pan/zoom) |
