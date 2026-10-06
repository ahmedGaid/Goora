# Implementation Plan: Wallet and Subscription

**Branch**: `004-wallet-subscription` | **Date**: 2026-10-08 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/004-wallet-subscription/spec.md`

## Summary

Replace the `plan` placeholder route and the `Wallet` tab placeholder with real screens. A new
`lib/features/wallet/` feature owns a pure-Dart `Plan` + `Wallet` + `ActivityEntry` model, the
`WalletRules` that compute a one-calendar-month trial end date and the "covers about N trips"
estimate, and a `PaymentProvider` interface with only a `FakePaymentProvider` implementation
(constitution: real integration is out of scope). A rider who has just joined a group (002/003)
is routed to the Plan screen and cannot reach Today/Week until a plan is chosen; a driver never
sees it. The Wallet tab renders rider or driver content from the same `WalletRepository`,
including top-up/withdraw sheets and the activity list that surfaces 003's attendance charges
(late-cancel half-charge, no-show full charge, zero-amount free cancellations) for the first
time. All data is a fake `WalletRepository` over `shared_preferences`, seeded so the independent
tests in the spec (US2 AC4, US3 AC4) have charges to show without replaying 003's flows. No
server component: this feature is app-side ledger only, no scheduled job and no new Supabase
table.

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44

**Primary Dependencies**: none new. `PaymentProvider`/`FakePaymentProvider` are plain Dart behind
an app interface, no payment SDK (constitution: "a `PaymentProvider` interface with
`FakePaymentProvider` only").

**Storage**: `shared_preferences` (plan, wallet balance, activity list, per person) — same store
as 001–003's fake repositories.

**Testing**: `flutter_test` — unit (`WalletRules` trial-date and trips-covered math at exact
boundaries, `CalendarDate.addMonths` edge cases), widget (Plan screen, rider Wallet, driver
Wallet, top-up sheet, withdraw sheet, change-plan sheet × ar/en).

**Target Platform**: Android 7+ / iOS 14+ (app only; no server work this feature)

**Project Type**: mobile-app

**Performance Goals**: Plan and Wallet screens render from local fake data in < 1 s, matching
003's Today/Week precedent; no network calls.

**Constraints**: no real payment integration; card data never stored (there is none —
`FakePaymentProvider` takes a method + amount, no card fields); no bare "Goora fee" number
anywhere in Plan/Wallet copy (SC-004); no Goora fee line, ever.

**Scale/Scope**: 2 new screens (Plan, Wallet rider/driver variants of one tab) + 3 sheets
(top-up, withdraw, change-plan), 1 feature folder, ~4 domain modules, 1 fake repository, 1 fake
payment provider, seed extended with wallet/plan fixtures.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Pre | Post |
|---|---|---|---|
| I Commute-first | Billing legibility for an existing commute relationship, not a new product | ✅ | ✅ |
| II Cost-sharing | Driver never profits: riders' trip-leg charges are unchanged from 003; subscription price is Goora's fee, never added on top of the fuel share; "Goora fees: in your plan" never shown as a number | ✅ | ✅ |
| III Arabic-first | All new copy in ARB (drafted, founder review before ship, same as 001–003); directional widgets; ar/en widget tests | ✅ | ✅ |
| IV Privacy | No new personal data exposed; driver fee rows are labelled by rider/trip only to the driver who already sees that rider in Today/Week | ✅ | ✅ |
| V Trust & safety | Not touched by this feature | ✅ | ✅ |
| VI Design system | Plan/Wallet screens reuse `GooraRadioCard`, `GooraCard`, `GooraPill`, `GooraPrimaryButton`, `GooraStatTile`; any new piece (dark balance card) goes in `lib/core/widgets` with a golden | ✅ | ✅ |
| VII Accessible | ≥ 44 px targets on radio cards/pills/CTAs; amount + method always shown as text, never colour alone | ✅ | ✅ |
| VIII Testable | `WalletRules` pure Dart with the brief's exact numbers (129/1290/40/20/200/400/800 EGP) and boundary tests; widget tests ar + en | ✅ | ✅ |
| IX Simplicity | No new packages; reuses 001's work-email verification pattern and 003's `AttendanceRules` charges instead of re-deriving them | ✅ | ✅ |
| Secrets / open items | `FakePaymentProvider` only; payment partner integration stays behind the interface until keys exist | ✅ | ✅ |

## Project Structure

### Documentation (this feature)

```text
specs/004-wallet-subscription/
├── plan.md · research.md · data-model.md · quickstart.md
├── contracts/repositories.md
└── tasks.md
```

### Source Code

```text
lib/app/
└── routes.dart                     # Routes.plan now points at a real screen, not a placeholder
lib/app/router.dart                 # Routes.plan builder → PlanScreen; redirect guard added to
                                     # the shell routes (today/week) for a rider with no active plan
lib/core/time/calendar_date.dart
└── + addMonths(int)                # one-calendar-month trial end (research R1)
lib/core/widgets/
└── goora_balance_card.dart         # dark balance card ("Covers about N trips" + Top up), shared
                                     # by rider wallet; driver's weekly card reuses GooraStatTile
lib/features/wallet/
├── domain/   plan.dart · wallet.dart · activity_entry.dart · payment_provider.dart
│             wallet_rules.dart · wallet_repository.dart
├── data/     wallet_seed.dart · fake_wallet_repository.dart · fake_payment_provider.dart
│             providers.dart
└── presentation/
    plan/     plan_screen.dart · plan_controller.dart · company_verify_sheet.dart
    wallet/   wallet_tab.dart (role switch) · rider_wallet.dart · driver_wallet.dart
              top_up_sheet.dart · withdraw_sheet.dart · change_plan_sheet.dart
              wallet_controller.dart
    labels.dart                     # activity-kind / plan-status → l10n
lib/features/daily/presentation/wallet/wallet_tab.dart   # deleted (placeholder superseded)
lib/features/placeholder/presentation/placeholder_screen.dart  # PlaceholderKind.plan removed
lib/features/commute/presentation/match_result_screen.dart     # unchanged: still routes the
                                     # rider to Routes.plan, which is now the real screen
test/unit/  calendar_add_months_test · wallet_rules_test
test/widget/ plan_screen_test · rider_wallet_test · driver_wallet_test · top_up_sheet_test
             withdraw_sheet_test · change_plan_sheet_test
test/golden/ wallet_widgets_golden_test.dart (+ goldens)
```

**Structure Decision**: a new `wallet` feature folder, sibling to `daily` and `commute`, because
Plan and Wallet are their own domain (billing), not an extension of the daily commute rules —
they only *read* 003's `Charge` records to render activity rows, they don't own them. The
existing `daily/presentation/wallet/wallet_tab.dart` placeholder and the `plan` entry in
`PlaceholderKind` are both removed in this feature, same lifecycle as 003 removing the `/today`
placeholder in 002.

## Phasing (maps to tasks.md)

- **P1 — US1**: `Plan`/`WalletRules`/`PaymentProvider` domain, `CalendarDate.addMonths`,
  `FakeWalletRepository`, Plan screen (Monthly/Yearly/Company cards, trial start, company verify
  reusing 001's work-email flow), router redirect guard, placeholder removal. Shippable alone —
  proves the business-model entry point (brief §6.7).
- **P2 — US2**: rider Wallet tab (plan card, balance card, top-up sheet, activity list sourced
  from 003's `Charge` + new top-up rows, per-trip breakdown), change-plan sheet.
- **P3 — US3**: driver Wallet tab (recovered-this-week, withdraw sheet, activity list, trip-cost
  breakdown).

## Complexity Tracking

*No violations — no new packages, no new server component.*
