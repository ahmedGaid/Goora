# Implementation Plan: Direct Driver Payment

**Branch**: `007-direct-driver-payment` | **Date**: 2026-10-18 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/007-direct-driver-payment/spec.md`

## Summary

The driver's cost share leaves the Goora wallet. Riders pay drivers directly (cash or InstaPay);
Goora's ledger carries only its own fee, subscriptions and legacy balances. The 004 driver mark
("Received cash / Didn't pay") widens to every paying rider and becomes the proof of payment, with
a 24-hour auto-receive, a correction window, a rider "دفعت" counter-claim and a two-in-30-days
review flag. An open "ماستلمتش" blocks booking. Pricing modes become `trial | perTrip | subscribed |
company` (trial = first 5 trips fee-free for every rider); `PaymentMethod` becomes `cash |
instapay`. New pure rules (`SharePolicy`, `DirectPay`) get a TypeScript twin and shared vectors;
the fee is trimmed against the *share actually paid* so cash rounding can't break the cap (R4).

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44; TypeScript on Node 24 for the twin

**Primary Dependencies**: none new

**Storage**: `shared_preferences` — `wallet.cashMarks` gains `markedAt` and keeps every mark;
new `wallet.paidClaims`, `wallet.instapay.<driverId>`

**Testing**: unit (twin vectors, cap sweep, derived wallet, booking gate), widget ar/en (driver
mark row with correction, rider debt banner + "دفعت", pay-method screen, wallet payments list),
goldens regenerated on Windows for changed screens; `node --test` for the twin

**Target Platform**: Android 7+ / iOS 14+; server twin only (no deploy)

**Project Type**: mobile-app

**Performance Goals**: derived reads stay ≤ 60-day window, < 1 s like 004

**Constraints**: Constitution II on recorded shares; no money of the driver's in any ledger;
privacy — first name only, InstaPay handle only after confirmed booking

**Scale/Scope**: 0 new screens; changes to pay-method screen, rider/driver wallet, rider/driver
Today, booking gate, marketplace seat booking, ~13 ARB keys ×2

## Constitution Check

| Principle | Status |
|---|---|
| I Commute-first | Pass — cheaper (no gateway fee on shares), fewer blocks to ride |
| II Cost-sharing | Pass — share + fee ≤ equal share proven by sweep test (R4); no bidding; driver cap untouched |
| III Arabic-first/RTL | Pass — ARB ar/en parity, directional layout, goldens ar/en |
| IV Privacy | Pass — first name only; InstaPay handle shown only post-confirmation (R7) |
| V Trust & safety | Pass — unchanged; adds a payment-trust signal |
| VI One design system | Pass — existing `Goora*` widgets and tokens only |
| VII Accessible | Pass — 44 px buttons, labels on copy icon |
| VIII Testable | Pass — pure rules + twins + vectors |

Legal gate: recorded in research R0 (pending by founder's choice). Re-check after design: no change.

## Project Structure

```text
specs/007-direct-driver-payment/  plan · research · data-model · contracts/direct_pay.md · quickstart · tasks

lib/features/wallet/domain/
  direct_pay.dart            NEW  SharePolicy, ShareStatus, DirectPay (twinned)
  share.dart                 NEW  Share view, PaidClaim
  cash_mark.dart             CHG  markedAt
  payment_method.dart        CHG  cash|instapay, PricingMode trial|perTrip|subscribed|company
  seat_price.dart            CHG  share + fee via DirectPay
  wallet.dart / wallet_repository.dart / activity_entry.dart   CHG
lib/features/wallet/data/fake_wallet_repository.dart           CHG  fee-only debits, shares, claims
lib/features/marketplace/domain/booking_gate.dart              CHG  blockedByDebt, no topUp
lib/features/marketplace/data/fake_marketplace_repository.dart CHG  fee-only seat debit
lib/features/daily/presentation/today/cash_after_trip.dart     CHG  all paying riders, correction
lib/features/daily/presentation/today/rider_today.dart         CHG  debt banner
lib/features/wallet/presentation/...                           CHG  copy, payments list, handle
lib/core/l10n/app_ar.arb · app_en.arb                          CHG
supabase/functions/_shared/direct_pay.ts + .test.ts            NEW
test/fixtures/direct_pay_vectors.json                          NEW
test/unit/direct_pay_vectors_test.dart, direct_pay_cap_sweep_test.dart  NEW
```

## Phases

1. **Rules** — `direct_pay.dart` + TS twin + vectors + cap sweep (riskiest: the cap with cash
   rounding). Thinnest slice, fully testable.
2. **Enums** — `PaymentMethod`/`PricingMode` rename; fix every caller; legacy `wallet` → `cash`.
3. **Ledger** — fee-only debits (group trips derived, seats at booking); trial for all; driver
   income rows stop.
4. **Marks & claims** — correction window, claims, open shares, dispute flag, booking guard.
5. **UI + copy** — driver mark row for all riders, rider debt banner + دفعت, pay-method screen,
   wallet copy and payments list, InstaPay handle; ARB; goldens.
6. **Gates + quickstart** (device steps need the emulator).

## Complexity Tracking

None — no constitution violations.
