# Phase 1 Data Model: Wallet and Subscription

Pure Dart, no persistence framework — `FakeWalletRepository` serialises these to/from
`shared_preferences` as JSON, same pattern as 003's `Charge.toJson`/`fromJson`.

## PlanType

```dart
enum PlanType { monthly, yearly, company }
```

- `monthly`: 129 EGP/month. `yearly`: 1,290 EGP/year ("2 months free" chip — 1,290 = 10× monthly).
- `company`: 0 EGP, requires work-email verification (reuses 001's `VerificationKind.workEmail`).

## PlanStatus

```dart
enum PlanStatus { trialing, active, due }
```

- `trialing`: inside the one-month free trial (monthly/yearly only).
- `active`: trial ended, a payment arrangement exists (top-up balance covers it, or Company).
- `due`: trial or paid period ended with no arrangement (FR-014) — not a removal, a prompt state.

## Plan

| Field | Type | Notes |
|---|---|---|
| `personId` | `String` | the rider; drivers have no `Plan` |
| `type` | `PlanType` | |
| `status` | `PlanStatus` | |
| `price` | `int` | whole EGP; 0 for Company |
| `untilDate` | `CalendarDate?` | free-until (trialing) or paid-until (active); `null` once `due` |

Invariant: `type == company` ⇒ `price == 0 && untilDate == null` (Company never trials or bills
the rider — FR-003).

## Wallet

| Field | Type | Notes |
|---|---|---|
| `ownerId` | `String` | rider or driver member id |
| `role` | `MemberRole` | from `commute/domain/group.dart` — picks rider vs. driver presentation |
| `balance` | `int` | whole EGP; rider: prepaid; driver: recoverable-this-week awaiting Thursday payout |
| `activity` | `List<ActivityEntry>` | newest first |

## ActivityEntry

```dart
enum ActivityKind { topUp, tripDeduction, lateCancelCharge, freeCancelZero, tripIncome, feeReceived, withdrawal }
```

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | |
| `kind` | `ActivityKind` | |
| `amount` | `int` | EGP, may be `0` (`freeCancelZero`) |
| `date` | `CalendarDate` | |
| `rideId` | `String?` | set for trip-linked kinds; `null` for `topUp`/`withdrawal` |
| `otherPersonId` | `String?` | set for `feeReceived` (which rider's charge reached the driver) |

`lateCancelCharge`/`tripDeduction`/`freeCancelZero` are read from 003's `Charge` + `Ride`/
`Absence` records at render time (research R3), not written by this feature's repository;
`topUp`, `withdrawal` and `feeReceived` (the driver's side of a rider's `Charge`) are the only
kinds this feature's repository actually creates.

## WalletRules (pure functions, no state)

- `trialEndDate(CalendarDate chosenAt) → CalendarDate` = `chosenAt.addMonths(1)` (research R1).
- `tripsCovered(int balance, int legShare) → int` = `max(0, balance ~/ (2 * legShare))` — a
  "trip" is a round-trip day (going + return), so the divisor is `2 × legShare` (clarification:
  40 EGP/leg ⇒ 80 EGP per round-trip day).
- `isPlanDue(Plan plan, CalendarDate today) → bool` = `plan.status != PlanStatus.company-equivalent
  check` — concretely: `plan.untilDate != null && today.isAfter(plan.untilDate!)`.

## PaymentProvider (interface)

```dart
abstract interface class PaymentProvider {
  Future<PaymentResult> topUp({required String method, required int amount});
  Future<PaymentResult> withdraw({required int amount});
}

enum PaymentResult { success, failure }
```

`FakePaymentProvider` is the only implementation; its `shouldFail` hook is research R4's debug
override, defaulting to always-succeed.

## WalletRepository (interface)

See `contracts/repositories.md` for the full method list and who calls what.
