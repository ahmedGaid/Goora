# Phase 1 Data Model: Wallet and Payment Model

Pure Dart, serialised to `shared_preferences` as JSON by `FakeWalletRepository` (v1 pattern).
v2 changes are marked **(v2)**, v2.1 (fee inside the cap) **(v2.1)**.

## CommuteGroup price basis (v2.1, 002's `commute/domain/group.dart`)

| Field | Type | Notes |
|---|---|---|
| `price` | `int` | unchanged — the contribution, EGP per rider per leg, fixed for the month |
| `tripCost` | `int` | **(v2.1)** EGP per leg; seed 160 |
| `riderSeats` | `int` | **(v2.1)** the rider seats `price` was set for, 1–4; seed 3 |

Invariants (seed test, research R16): for both legs, riders on the leg + `freeSeats(leg)` ≤
`riderSeats`; `PricingService.range(tripCost, riderSeats).contains(price)`. No JSON form — groups
are seed-only, so no migration (R15).

## PaymentMethod (v2)

```dart
enum PaymentMethod { cash, wallet }
```

A rider's choice on the payment-method screen, stored once (`wallet.method`). Choosing `wallet`
gives up the cash trial (spec clarification).

## PlanType / PlanStatus / Plan

```dart
enum PlanType { monthly, yearly, company }
enum PlanStatus { active, due }        // (v2) `trialing` removed — no free month
```

| Field | Type | Notes |
|---|---|---|
| `personId` | `String` | riders only |
| `type` | `PlanType` | monthly 129, yearly 1,290, company 0 |
| `status` | `PlanStatus` | `due` = paid period over → pay per trip again |
| `price` | `int` | whole EGP; 0 for company |
| `untilDate` | `CalendarDate?` | **(v2)** paid-until; `null` for company |

A plan is **fee-free** when `type == company`, or when it is active and `today ≤ untilDate`.

## CashMark (v2)

| Field | Type | Notes |
|---|---|---|
| `rideId` | `String` | 003's ride id |
| `riderId` | `String` | the cash rider |
| `driverId` | `String` | who recorded it |
| `outcome` | `CashOutcome { received, didNotPay }` | one mark per (ride, rider); first wins |
| `amount` | `int` | the contribution (40) |
| `date` | `CalendarDate` | the ride's date |

## ActivityEntry

```dart
enum ActivityKind {
  topUp, tripDeduction, lateCancelCharge, freeCancelZero, tripIncome, feeReceived, withdrawal,
  trip, cashTrip, subscription, cashReceived,      // (v2)
}
```

| Field | Type | Notes |
|---|---|---|
| `amount` | `int` | what moved in the wallet (trip: contribution + fee; cashTrip: 0) |
| `fee` | `int` | **(v2)** the service-fee part of `amount` (trip only; else 0) |
| `notCollected` | `bool` | **(v2)** a charge skipped during the cash trial (amount 0) |
| … | | v1 fields unchanged (`id`, `kind`, `date`, `rideId`, `otherPersonId`) |

`tripDeduction` is no longer produced (v2 uses `trip`); kept so stored v1 data still parses.

## Wallet

v1 fields plus **(v2)**:

| Field | Type | Notes |
|---|---|---|
| `method` | `PaymentMethod?` | riders |
| `cashTrial` | `CashTrialStatus?` | `{tripsDone, strikes, tripsLeft, available, showTopUpBanner, endedBy}` — null for wallet riders |
| `feesThisMonth` | `int` | sum of `fee` on this calendar month's trips |
| `cashReceived` | `int` | drivers: sum of `received` marks; not part of `balance` |

## Rules (pure, `lib/features/wallet/domain/`)

- `PricingService` (002's commute PricingService) — **(v2.1)** signatures in
  [contracts/pricing.md](contracts/pricing.md):
  `equalShare(tripCost, riderSeats)` = `tripCost ~/ riderSeats` (throws if `riderSeats < 1`);
  `serviceFee(c, {tripCost, riderSeats, isSubscriber, isCashTrial})` = `0` if subscriber or cash,
  else `max(0, min((c × 10 + 50) ~/ 100, equalShare − c))` — round first (R6), then trim;
  `riderTotal(…)` = `c + serviceFee(…)`. The contribution is never reduced. `feeRatePercent = 10`
  stays as the *ceiling*.
- `CashTrialPolicy`: `tripLimit = 10`, `strikeLimit = 2`, `bannerAfter = 7`.
  `available(tripsDone, strikes)` = `tripsDone < 10 && strikes < 2`;
  `tripsLeft(tripsDone)` = `max(0, 10 − tripsDone)`;
  `showTopUpBanner(tripsDone, strikes)` = `available(…) && tripsDone ≥ 7`.
- `FeeSavingsCalculator`: `subscriptionPrice = 129`;
  `feesInMonth(entries, monthKey)` = Σ `fee` of that month's trips;
  `shouldUpsell(fees, {isFeeFree})` = `!isFeeFree && fees > 129`.
- `WalletRules.tripsCovered(balance, legTotal)` = `max(0, balance ~/ (2 × legTotal))`
  (v2: `legTotal` is what one leg costs this rider, 44 or 40). `isPlanDue` unchanged.
  `trialEndDate` removed.

## WalletView (presentation, v2.1)

- `fee` passes the group's `tripCost`/`riderSeats` (new view fields `groupTripCost`,
  `riderSeats`), so `legTotal`, `tripsCovered`, `needsTopUp` and the breakdown use the trimmed fee
  with no other change.
- Driver: the old `tripCost` getter (`legShare × capacitySeats × 2`) becomes `dayTripCost` =
  `groupTripCost × 2`; `driverGap = dayTripCost − receivedFromRiders` (R16 — on a full 3-seat car
  this is the driver's own share, 80).
- `ActivityEntry.fee` already stores the fee charged; `FeeSavingsCalculator` already sums it — no
  change.

## PaymentProvider

v1 interface unchanged (`topUp`, `withdraw`). Subscriptions move money inside the ledger only
(R10), so no new provider call.
