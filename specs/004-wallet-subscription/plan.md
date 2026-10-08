# Implementation Plan: Wallet and Payment Model

**Branch**: `004-wallet-subscription` | **Date**: 2026-10-08 (v1) · 2026-10-08 (v2 amendment) ·
2026-10-08 (v2.1: fee inside the cap) | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/004-wallet-subscription/spec.md`

## Summary

v1 (built, T001–T045) gave riders a mandatory plan screen with a free month, a rider/driver
Wallet tab, top-up/withdraw/change-plan sheets, and an activity list read from 003's records.

v2 changes only the payment model. Three pure-Dart rules carry it: `PricingService` (contribution
+ 10% fee, half-up, 0 for subscribers/company/cash), `CashTrialPolicy` (10 trips, 2 strikes,
banner after 7) and `FeeSavingsCalculator` (month's fees vs 129). The rider's arrangement becomes
a `PaymentMethod` (cash | wallet) plus an optional `Plan` (monthly | yearly | company, no trial).
The router guard asks for a payment arrangement instead of a plan, and sends new riders to a new
payment-method screen; the v1 plan screen becomes the subscription screen behind the "Subscribe
and pay no fees" link. Per-trip charging is derived from 003's settled ride outcomes (the same
read-don't-duplicate seam v1 used for charges), so the rider's balance becomes the ledger minus
derived debits. Driver Today gains "Received cash" / "Didn't pay" after a trip ends; the driver
Wallet gains a separate, non-withdrawable "Cash received" card. The fee rule gets a TypeScript
twin and shared vectors.

v2.1 (built on v2, T001–T079) moves the service fee inside Constitution II's cap: the fee is
10% rounded half-up, trimmed to the room left under the rider's equal share (⌊trip cost ÷ rider
seats⌋ − contribution), never below 0; the contribution is never touched. The rule needs two
inputs no group stores today, so `CommuteGroup` gains a price basis — `tripCost` and `riderSeats`
(research R15). Planning found that the seed already breaks 002's price range (`sz-0725` and
`sz-0720` are 4-rider cars priced at the 3-seat 40 EGP), so the seed becomes 3-seat cars with an
invariant test (R16); the demo stays 40 → 44. Both pricing twins change signature and share five
new vectors; a sweep test proves FR-016 (R17 — 129,309 allowed prices, 0 over the cap). Copy:
"up to 10%", a no-fee price line, and the breakdown without "(10%)" (R13 addendum). The driver
wallet's trip cost reads the stored trip cost.

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44; TypeScript on Node 24 for the twin rule

**Primary Dependencies**: none new

**Storage**: `shared_preferences` — v1 keys plus `wallet.method` (rider's payment method) and
`wallet.cashMarks` (drivers' cash records)

**Testing**: `flutter_test` unit (the three rules with the brief's numbers, the derived wallet),
widget (payment-method screen, subscription screen, rider wallet states, driver cash buttons,
driver cash card, price lines on match result/Today) × ar/en; goldens regenerated for changed
screens; `node --test` for the pricing twin

**Target Platform**: Android 7+ / iOS 14+; server twin only (no deploy)

**Project Type**: mobile-app

**Performance Goals**: Wallet derives from ≤ 60 days of local records; < 1 s like v1

**Constraints**: Constitution II — drivers receive exactly the contribution, the fee never reaches
them, charges carry no fee; (v2.1) each rider's contribution + fee ≤ ⌊trip cost ÷ rider seats⌋, so
riders' total, fees included, never exceeds the trip cost; no real payment integration

**Scale/Scope**: 1 new screen (payment method), 1 repurposed screen (subscription), changes to
rider/driver Wallet, PickupCheckIn, match result and rider Today price lines; 3 new domain rules;
1 TS twin

## Constitution Check

| Principle | Gate | Pre | Post |
|---|---|---|---|
| I Commute-first | Payment serves the daily group; cash trial lowers the first-week barrier | ✅ | ✅ |
| II Cost-sharing | Contributions to drivers unchanged and still capped; the fee goes to Goora, never to the driver; no fee on late-cancel/no-show; drivers never pay. **v2.1**: the cap is met as written — fee trimmed so every rider stays within an equal share (sweep test R17); seed brought back inside the ±20% range (R16). The constitution is not amended. Open for legal (brief §8): is a per-trip fee allowed at all | ✅ (v2: flagged) | ✅ (v2.1: cap met; fee legality open) |
| III Arabic-first | All new copy in ARB both locales; brief §7 strings used verbatim; drafted rest listed in research R5/R6 | ✅ | ✅ |
| IV Privacy | Cash buttons appear only after pick-up, when the driver already sees the rider's name (003 FR-016) | ✅ | ✅ |
| V Trust & safety | Cash-trial charges skip money but still feed reliability (003 rules untouched) | ✅ | ✅ |
| VI Design system | Reuses GooraRadioCard, GooraCard, GooraBanner, GooraGhostButton, GooraStatusChip, GooraBalanceCard; no new tokens | ✅ | ✅ |
| VII Accessible | Every money state is text, never colour alone; ≥ 44 px targets | ✅ | ✅ |
| VIII Testable | Three pure rules with exact-number unit tests; Dart/TS twin on shared vectors; (v2.1) cap sweep in both twins, seed invariant test | ✅ | ✅ |
| IX Simplicity | No new packages; derive, don't duplicate (R7); no booking engine (spec clarification) | ✅ | ✅ |

## Project Structure

```text
specs/004-wallet-subscription/  spec · plan · research (R1–R4 v1, R5 copy, R6–R14 v2, R15–R17 v2.1)
                                data-model · contracts/repositories.md · contracts/pricing.md (v2.1)
                                quickstart · tasks
lib/features/commute/domain/group.dart          (v2.1) + tripCost, riderSeats
lib/features/commute/domain/pricing_service.dart (v2.1) equalShare; serviceFee/riderTotal take the basis
lib/features/commute/data/corridor_seed.dart     (v2.1) basis 160/3; sz-0725, sz-0720 free seats −1
lib/app/router.dart             guard: payment arrangement → Routes.payMethod
lib/app/routes.dart             + payMethod; plan stays (subscription screen)
lib/features/wallet/
  domain/  cash_trial_policy.dart · fee_savings_calculator.dart                        (new)
           (PricingService.serviceFee/riderTotal extend 002's commute/domain/pricing_service.dart)
           payment_method.dart · cash_mark.dart                                         (new)
           plan.dart (no trialing) · activity_entry.dart (+ kinds, + fee) · wallet.dart (+ cash
           trial, fees this month, cash received) · wallet_repository.dart (+ methods)
           wallet_rules.dart (trialEndDate removed; tripsCovered takes the leg total)
  data/    fake_wallet_repository.dart (derived debits, method, subscribe, cash marks)
           wallet_seed.dart (+ cash rider, driver cash rows)
  presentation/
    pay_method/  pay_method_screen.dart                                                   (new)
    plan/        plan_screen.dart → subscription screen copy + subscribe from wallet
    wallet/      rider_wallet.dart · driver_wallet.dart · wallet_controller.dart · activity_row
    price_line.dart  (one place that turns contribution + arrangement into the price string)
lib/features/commute/presentation/match_result_screen.dart   price line; join → payMethod
lib/features/daily/presentation/today/rider_today.dart       price line
lib/features/daily/presentation/today/pickup_check_in.dart   cash buttons after the trip ends
supabase/functions/_shared/pricing.ts + pricing.test.ts       twin
test/fixtures/pricing_vectors.json                            shared vectors
```

**Structure Decision**: stay inside the v1 `wallet` feature. Daily's PickupCheckIn and the
commute match screen read wallet providers at the presentation layer only; domain layers stay
independent.

## Phasing (maps to tasks.md Phase 7+)

- **P4 — rules**: PricingService, CashTrialPolicy, FeeSavingsCalculator + vectors + TS twin.
- **P5 — model + repo**: PaymentMethod, CashMark, Plan without trial, derived wallet, subscribe.
- **P6 — rider flow (US1, US3)**: payment-method screen, guard, subscription screen, price lines.
- **P7 — rider wallet (US2, US4)**: plan card states, cash counter/banners, fee rows, savings.
- **P8 — driver (US5)**: cash buttons in PickupCheckIn, cash-received card.
- **P9 — polish**: goldens, copy list, gates, quickstart.

v2.1 (tasks.md, after T079), one session if it fits:

- **P10 — rule + twin** (riskiest first): `equalShare`, new `serviceFee`/`riderTotal` signatures in
  Dart and TS; vectors gain the basis + five cap rows; cap sweep in both twins (R17).
- **P11 — basis + seed**: `CommuteGroup.tripCost`/`riderSeats`; seed 160/3 and free seats; seed
  invariant test; fix 002/003 tests that counted `sz-0725`'s old free seats (R16).
- **P12 — callers + copy**: the five call sites ([contracts/pricing.md](contracts/pricing.md));
  `WalletView` basis + driver `dayTripCost`; `priceNoFee`, `planPerTripNoFeeLine`, replaced
  `howPayRule1`/`breakdownFee` (ar + en); widget tests for a trimmed fee (160/4 at 38 → "38 + 2")
  and a zero fee; goldens touched by the copy; the stale "Constitution II reading" comment.
- **Gate**: analyze 0, `flutter test --concurrency=1`, `node --test`; then quickstart Scenario 5.

## Complexity Tracking

*No violations. v2.1 meets Constitution II's cap as written (R17) and restores the seed to the
±20% range it already required (R16); no amendment. Two required fields on `CommuteGroup` are the
smallest way to give both twins the inputs (R15 alternatives).*
