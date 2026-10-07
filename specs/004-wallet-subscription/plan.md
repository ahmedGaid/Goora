# Implementation Plan: Wallet and Payment Model

**Branch**: `004-wallet-subscription` | **Date**: 2026-10-08 (v1) · 2026-10-08 (v2 amendment) |
**Spec**: [spec.md](spec.md)

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
them, charges carry no fee; no real payment integration

**Scale/Scope**: 1 new screen (payment method), 1 repurposed screen (subscription), changes to
rider/driver Wallet, PickupCheckIn, match result and rider Today price lines; 3 new domain rules;
1 TS twin

## Constitution Check

| Principle | Gate | Pre | Post |
|---|---|---|---|
| I Commute-first | Payment serves the daily group; cash trial lowers the first-week barrier | ✅ | ✅ |
| II Cost-sharing | Contributions to drivers unchanged and still capped; the 10% fee goes to Goora, never to the driver; no fee on late-cancel/no-show; drivers never pay. The cap is read as applying to contributions (spec "Constitution II reading"), pending the legal opinion in brief §8 — not an amendment | ✅ (flagged) | ✅ (flagged) |
| III Arabic-first | All new copy in ARB both locales; brief §7 strings used verbatim; drafted rest listed in research R5/R6 | ✅ | ✅ |
| IV Privacy | Cash buttons appear only after pick-up, when the driver already sees the rider's name (003 FR-016) | ✅ | ✅ |
| V Trust & safety | Cash-trial charges skip money but still feed reliability (003 rules untouched) | ✅ | ✅ |
| VI Design system | Reuses GooraRadioCard, GooraCard, GooraBanner, GooraGhostButton, GooraStatusChip, GooraBalanceCard; no new tokens | ✅ | ✅ |
| VII Accessible | Every money state is text, never colour alone; ≥ 44 px targets | ✅ | ✅ |
| VIII Testable | Three pure rules with exact-number unit tests; Dart/TS twin on shared vectors | ✅ | ✅ |
| IX Simplicity | No new packages; derive, don't duplicate (R7); no booking engine (spec clarification) | ✅ | ✅ |

## Project Structure

```text
specs/004-wallet-subscription/  spec · plan · research (R1–R4 v1, R5 copy, R6–R13 v2)
                                data-model · contracts/repositories.md · quickstart · tasks
lib/app/router.dart             guard: payment arrangement → Routes.payMethod
lib/app/routes.dart             + payMethod; plan stays (subscription screen)
lib/features/wallet/
  domain/  pricing_service.dart · cash_trial_policy.dart · fee_savings_calculator.dart   (new)
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

## Complexity Tracking

*No violations. Constitution II is flagged for the legal opinion, not violated: contributions and
their cap are unchanged.*
