# Phase 1 Data Model: Wallet and Payment Model

Pure Dart, serialised to `shared_preferences` as JSON by `FakeWalletRepository` (v1 pattern).
v2 changes are marked **(v2)**.

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

- `PricingService.serviceFee(c, {isSubscriber, isCashTrial})` = `0` if either, else
  `(c + 5) ~/ 10` (R6). `riderTotal(c, {isSubscriber, isCashTrial})` = `c + serviceFee(…)`.
  `feeRatePercent = 10`.
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

## PaymentProvider

v1 interface unchanged (`topUp`, `withdraw`). Subscriptions move money inside the ledger only
(R10), so no new provider call.
