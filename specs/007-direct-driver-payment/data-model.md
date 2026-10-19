# Data Model: Direct Driver Payment (007)

All money in whole EGP. Times on the demo clock (`WallTime`).

## CashMark (widened, 004 entity)

A driver's answer for one rider's share on one ride.

| Field | Type | Notes |
|---|---|---|
| rideId | String | 003 ride id, or a 005 one-off ride id |
| riderId | String | |
| driverId | String | |
| outcome | `received` \| `didNotPay` | |
| amount | int | the share (cash amount or exact contribution) |
| date | CalendarDate | the ride's date |
| markedAt | WallTime? | **new**; null on legacy rows (treated as the ride date at 00:00) |

Rules: one *current* mark per (rideId, riderId); a new mark replaces it only if
`SharePolicy.canMark` allows (research R2). Every replacement is kept in `history` (fakes: the
list keeps all marks, the latest by `markedAt` wins).

## PaidClaim (new)

A rider's "دفعت" on a share the driver marked `didNotPay`.

| Field | Type | Notes |
|---|---|---|
| rideId, riderId | String | |
| claimedAt | WallTime | must be after the latest `didNotPay` mark to count |

## ShareStatus (new enum, twinned)

`pending · received · autoReceived · notReceived · disputed`. Transitions in research R2.
`isOpenDebt` = `notReceived | disputed`.

## Share (derived view, not stored)

| Field | Type |
|---|---|
| rideId, riderId, driverId | String |
| driverFirstName | String (privacy: first name only, FR-018) |
| amount | int |
| method | PaymentMethod (`cash` \| `instapay`) |
| tripEnd | WallTime |
| status | ShareStatus |

## PaymentMethod (changed)

`cash | instapay` — how the rider pays the driver. Legacy stored `wallet` → `cash`.

## PricingMode (changed)

`trial | perTrip | subscribed | company`. `isFeeFree` = not `perTrip`.

## DriverPayProfile (new)

| Field | Type | Notes |
|---|---|---|
| driverId | String | |
| instapayHandle | String? | ≤ 40 chars, trimmed; empty → null |

## DisputeFlag (derived)

`count` = `didNotPay` marks (current, not later reversed) with ride date in the last 30 days;
`flagged` = count ≥ 2.

## Wallet (changed)

- Rider `balance` = ledger − fees (never the share). Negative = fee owed to Goora.
- New `openShares: List<Share>` on the rider (open debts) for the debt banner.
- Driver: `cashReceived` → `receivedThisMonth` (sum of `received | autoReceived` shares this month);
  new `shares: List<Share>` for the payments list.

## ActivityKind (changed)

- `trip` amount = fee only; `toDriver` no longer derived from it. A new `shareToDriver` field on the
  entry (int, default 0) carries the share for display only, never added to the balance.
- `seatBooked` amount = fee only. `tripIncome` no longer written for new rows.
