---
description: "Task list for feature 004: Wallet and Subscription"
---

# Tasks: Wallet and Subscription

**Input**: `specs/004-wallet-subscription/` (plan, spec, research, data-model, contracts, quickstart)

**Tests**: REQUIRED — constitution VIII: `WalletRules`/`CalendarDate.addMonths` unit tests at exact
boundaries with the brief's exact numbers (129/1290/40/20/200/400/800 EGP), widget tests ar + en
for every new screen/sheet, goldens RTL + LTR for new core widgets.

**Order**: Setup → Foundational → US1 (P1, MVP) → US2 (P1) → US3 (P2) → Polish. Each checkpoint
ends with green `flutter analyze` + `flutter test` and can be committed on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1/US2/US3 from spec.md
- "R#" = section of research.md; "FR-###" = spec requirement

---

## Phase 1: Setup

- [X] T001 [P] Add all 004 ARB keys (Plan screen title/subline/cards/CTA/footer, rider + driver
  Wallet copy, "How paying works" rules, top-up/withdraw/change-plan sheet copy, activity-row
  labels) to `lib/core/l10n/app_ar.arb` and `lib/core/l10n/app_en.arb` — drafted copy from
  spec.md, founder review before ship (same pattern as 003); run `flutter gen-l10n`

---

## Phase 2: Foundational (blocks every story)

**Time core**

- [X] T002 [P] `lib/core/time/calendar_date.dart`: add `addMonths(int months)` — keeps
  day-of-month, clamps to the target month's last day when it has fewer days (R1)
- [X] T003 [P] `test/unit/calendar_add_months_test.dart`: 31 Jan + 1 → 28/29 Feb (leap + non-leap);
  31 Mar + 1 → 30 Apr; Dec → Jan year rollover; a mid-month date unaffected

**Domain model**

- [X] T004 [P] `lib/features/wallet/domain/plan.dart`: `PlanType`, `PlanStatus`, `Plan` (fields +
  `type == company ⇒ price == 0 && untilDate == null` invariant) per data-model
- [X] T005 [P] `lib/features/wallet/domain/wallet.dart`: `Wallet` (ownerId, role, balance, activity)
- [X] T006 [P] `lib/features/wallet/domain/activity_entry.dart`: `ActivityKind`, `ActivityEntry`
  (id, kind, amount, date, rideId?, otherPersonId?)
- [X] T007 [P] `lib/features/wallet/domain/payment_provider.dart`: `PaymentProvider` interface
  (`topUp`, `withdraw`), `PaymentResult` enum
- [X] T008 `lib/features/wallet/domain/wallet_rules.dart`: `trialEndDate` (uses `addMonths`,
  depends on T002/T004), `tripsCovered` (`max(0, balance ~/ (2 * legShare))`), `isPlanDue`
- [X] T009 [P] `test/unit/wallet_rules_test.dart`: trialEndDate = chosenAt.addMonths(1);
  tripsCovered at 0 (balance < one leg-share), exact round-trip boundary (80 EGP = 1 trip, 79 = 0),
  and the brief's numbers (40 EGP/leg ⇒ 80/round-trip); isPlanDue true only when `untilDate` is set
  and in the past
- [X] T010 `lib/features/wallet/domain/wallet_repository.dart`: `WalletRepository` interface per
  `contracts/repositories.md`

**Fake data and wiring**

- [X] T011 [P] `lib/features/wallet/data/fake_payment_provider.dart`: `FakePaymentProvider`
  implementing `PaymentProvider`, `shouldFail` hook defaulting to always-succeed (R4)
- [X] T012 `lib/features/wallet/data/wallet_seed.dart`: seeded rider Plan (trialing) + Wallet
  (top-up row, trip deduction, late-cancel charge, free-cancel zero-row) and seeded driver Wallet
  (trip income rows, one fee-received row) so US2/US3 independent tests have activity without
  replaying 003's flows live
- [X] T013 `lib/features/wallet/data/fake_wallet_repository.dart`: implements
  `WalletRepository` over `shared_preferences`; `getPlan`/`choosePlan`/`changePlan`/`getWallet`/
  `topUp`/`withdraw`; `getWallet` merges this feature's own activity (top-up, withdrawal, fee
  received) with rows read from `DailyCommuteRepository`'s `Charge`/`Ride` records for
  `tripDeduction`/`lateCancelCharge`/`freeCancelZero` (R3, not duplicated/stored)
- [X] T014 [P] `lib/features/wallet/data/providers.dart`: Riverpod providers for
  `WalletRepository`/`PaymentProvider` (overridable, same pattern as `daily/data/providers.dart`)
- [X] T015 [P] `test/unit/fake_wallet_repository_test.dart`: `choosePlan(monthly/yearly)` sets
  `trialing` + `untilDate = today.addMonths(1)`; `choosePlan(company)` sets `active`-equivalent
  free/no-trial-date; `changePlan` doesn't affect the current period; `topUp`/`withdraw` success
  updates balance + adds a row; failure changes neither (SC-005); `getWallet` includes 003's
  seeded `Charge` rows
- [X] T016 [P] `lib/core/widgets/goora_balance_card.dart`: dark balance card (balance text,
  "Covers about {N} trips", Top up action) per constitution VI
- [X] T017 [P] `test/golden/wallet_widgets_golden_test.dart` + goldens RTL/LTR for
  `goora_balance_card`

**Checkpoint**: domain + fake repository + balance card ready; 003 suite still green.

---

## Phase 3: US1 — A rider starts their free month after joining a group (P1) 🎯 MVP

**Goal**: rider sees the Plan screen once after joining, picks a plan, starts the free month;
drivers never see it. **Independent test**: complete "Join this group" as a rider, land on Plan,
choose Monthly, confirm the free-trial starts with no charge.

- [X] T018 [US1] `lib/features/wallet/presentation/plan/plan_controller.dart`: load plan state;
  `choosePlan(monthly/yearly)` using `nowProvider` for `today`; `choosePlan(company)` only after
  the verify sheet confirms
- [X] T019 [US1] `lib/features/wallet/presentation/plan/company_verify_sheet.dart`: reuses 001's
  work-email verification pattern (`VerificationKind.workEmail`); on confirm calls
  `choosePlan(company)` (FR-003)
- [X] T020 [US1] `lib/features/wallet/presentation/plan/plan_screen.dart`: title "Start your free
  month", subline, three `GooraRadioCard`s (Monthly 129 EGP / Yearly 1,290 EGP + "2 months free"
  chip / Through my company: free), "What's included" list, fuel-to-driver note, CTA
  ("Start free month" / "Verify work email"), footer "Cancel anytime. Goora is free for drivers."
- [X] T021 [US1] `lib/features/wallet/presentation/labels.dart`: plan-type/plan-status → l10n
  (start here; extended in US2/US3)
- [X] T022 [US1] `lib/app/routes.dart`: `Routes.plan` → `PlanScreen`; `lib/app/router.dart`:
  redirect guard on the shell's `today`/`week` routes — a rider with no `Plan`, or a due/expired
  one and no Company verification, redirects to `Routes.plan` (R2); Wallet/Trust stay reachable
- [X] T023 [US1] `lib/features/placeholder/presentation/placeholder_screen.dart`: remove
  `PlaceholderKind.plan`
- [X] T024 [P] [US1] `test/widget/plan_screen_test.dart` (ar + en): AC1 — all elements present;
  AC2 — Monthly/Yearly → "Start free month" → plan active, free-until one month out, no charge;
  AC3 — Through my company → verify sheet → Company plan, no trial date; AC4 — a driver never
  sees this screen; AC5 — dismiss/back reappears until a plan is chosen

**Checkpoint P1a**: US1 shippable alone — the business-model entry point exists. `flutter analyze`
+ `flutter test` green. Commit.

---

## Phase 4: US2 — A rider manages their wallet, plan and top-ups (P1)

**Goal**: rider's Wallet tab shows plan, balance, top-up, "how paying works", and a running
activity list. **Independent test**: open Wallet as the seeded rider (top-up, trip deduction,
late-cancel charge, free cancellation already present) and confirm every row and the balance.

- [X] T025 [US2] `lib/features/wallet/presentation/wallet/wallet_controller.dart`: rider wallet
  view-model — plan status line ("Free until {date} · then 129 EGP/month" or the due state per
  FR-014), balance, `tripsCovered`, merged activity (T013), "What you pay per trip" breakdown
  (fuel & tolls share as a number, "Goora fees: in your plan" fixed label)
- [X] T026 [US2] `lib/features/wallet/presentation/wallet/rider_wallet.dart`: plan card ("Change"
  link) including the due-plan prompt state (FR-014); `goora_balance_card` with Top up (InstaPay /
  Vodafone Cash / Card pills, 200/400/800 EGP); "How paying works" rules list; activity list
  (zero-amount row for a free cancellation, never omitted); per-trip breakdown
- [X] T027 [US2] `lib/features/wallet/presentation/wallet/top_up_sheet.dart`: method + amount →
  `WalletRepository.topUp`; failure shows an inline, blame-free error with retry, balance/activity
  unchanged (FR-006)
- [X] T028 [US2] `lib/features/wallet/presentation/wallet/change_plan_sheet.dart`: switch
  Monthly/Yearly/Company via `changePlan`; current period's card is unaffected until the next
  billing date (FR-004, no pro-rating)
- [X] T029 [US2] `lib/features/wallet/presentation/wallet/wallet_tab.dart`: role-switch entry
  point (rider branch wired now, driver branch stubbed until US3); delete the superseded
  `lib/features/daily/presentation/wallet/wallet_tab.dart` placeholder
- [X] T030 [US2] `lib/features/wallet/presentation/labels.dart`: extend with rider activity-kind
  labels (top-up, trip deduction, late-cancel charge, free-cancel zero)
- [X] T031 [P] [US2] `test/widget/rider_wallet_test.dart` (ar + en): AC1 plan card text incl. due
  state; AC2 balance card + "Covers about N trips" + pills + amounts; AC3 top-up success → balance
  +amount, new row at top; AC4 late-cancel half-charge row vs. zero-amount free-cancel row,
  distinct; AC5 breakdown ends "Goora fees: in your plan", never a number; top-up failure leaves
  balance/activity unchanged with inline retry (SC-005)
- [X] T032 [P] [US2] `test/widget/top_up_sheet_test.dart` (ar + en): method/amount selection,
  success and forced-failure paths
- [X] T033 [P] [US2] `test/widget/change_plan_sheet_test.dart` (ar + en): switching plan leaves
  the current plan card unchanged until the next billing date

**Checkpoint P1b**: US1 + US2 complete — rider side fully functional. `flutter analyze` +
`flutter test` green. Commit.

---

## Phase 5: US3 — A driver sees what they're paid and withdraws it (P2)

**Goal**: driver's Wallet tab shows recovered balance, payout day, withdrawal, and activity.
**Independent test**: open Wallet as the seeded driver (trip income + one rider fee already
present) and confirm the weekly balance, payout line and activity rows.

- [X] T034 [US3] `lib/features/wallet/presentation/wallet/wallet_controller.dart`: extend with
  driver view-model — "Recovered this week" total, merged activity (trip income + fee received),
  "Your trip cost" breakdown (trip cost / received from riders / gap the driver covers / "Goora is
  free for drivers")
- [X] T035 [US3] `lib/features/wallet/presentation/wallet/driver_wallet.dart`: "Recovered this
  week" + "Paid out every Thursday · no fees taken from you"; Withdraw to InstaPay; activity list
  (trip income, fee-received rows labelled by rider/trip); trip-cost breakdown with no deduction
  line
- [X] T036 [US3] `lib/features/wallet/presentation/wallet/withdraw_sheet.dart`: `withdraw` call;
  failure shows inline retry, balance/activity unchanged (FR-010)
- [X] T037 [US3] `lib/features/wallet/presentation/wallet/wallet_tab.dart`: wire the driver branch
  (role switch now complete for both roles)
- [X] T038 [US3] `lib/features/wallet/presentation/labels.dart`: extend with driver activity-kind
  labels (trip income, fee received, withdrawal)
- [X] T039 [P] [US3] `test/widget/driver_wallet_test.dart` (ar + en): AC1 recovered total + payout
  line; AC2 withdraw success → balance resets, new "Withdrawal" row; AC3 trip-cost breakdown shows
  the gap when riders' total is less than full cost, and "Goora is free for drivers" with no
  deduction when it isn't; AC4 a rider's late-cancel/no-show fee appears labelled by rider/trip
- [X] T040 [P] [US3] `test/widget/withdraw_sheet_test.dart` (ar + en): success and forced-failure
  paths

**Checkpoint P2**: US1–US3 complete; `flutter analyze` + `flutter test` green. Commit.

---

## Phase 6: Polish

- [x] T041 [P] Extend `test/golden/wallet_widgets_golden_test.dart` with goldens RTL/LTR for Plan
  screen, rider/driver Wallet, and the three sheets
- [x] T042 [P] Add the new dark-balance-card and due-state text/background pairs to
  `test/unit/contrast_test.dart`
- [x] T043 Confirm `test/architecture/no_hardcoded_values_test.dart` covers `lib/features/wallet`
- [x] T044 List every drafted Plan/Wallet ARB key for founder review (same pattern as 003's
  research R14) — append to `specs/004-wallet-subscription/research.md`
- [x] T045 Gates: `flutter analyze` (0 issues), `flutter test` (493 pass); README: add a 004
  section (new feature folder, no new packages). `quickstart.md` on device (`R5CNC0NK6ZT`,
  `01010665106` rider, build `1d0c393`), ar: **Scenario 1 confirmed live** — Plan screen exact to
  spec, Monthly chosen, lands on Today, Wallet plan card reads "مجاني لحد 18/11 · بعدها 129
  جنيه/الشهر" (steps 5-7 driver-redirect already covered by passing `plan_screen_test.dart`
  AC4/AC5). **Scenario 2 confirmed live** — balance/trips-caption/method+amount pills, top-up
  InstaPay 200 → balance 200 + "شحن +200" row, Change → Yearly → plan card unchanged until next
  billing date (step 5 late-cancel/free-cancel rows and steps 8-9 forced-failure rely on passing
  `rider_wallet_test.dart`/`top_up_sheet_test.dart`, since a fresh rider has no 003 ride history to
  seed those rows live). **Scenario 3 not run live** — driver mode needs 003's license+vehicle
  Trust verification before matching unlocks, out of scope for a 004 walkthrough session; relies
  on passing `driver_wallet_test.dart` AC1-AC4. **English (LTR) pass of all three not run** — do
  before merge. Found+fixed in research.md R4: the "force next payment to fail" Settings control
  this file's R4 describes was never actually wired — `providers.dart` always builds a plain
  `FakePaymentProvider()`, so `shouldFail` is test-only today. README's claim corrected to match.

---

## Dependencies & Execution Order

```text
Setup (T001) → Foundational (T002–T017)
  → US1 (T018–T024)                                            ← P1 MVP, commit
  → US2 (T025–T033)                                             ← P1, commit
  → US3 (T034–T040)                                             ← P2, commit
  → Polish (T041–T045)
```

- US2's `wallet_tab.dart` role switch (T029) is extended by US3 (T037); US2 ships with the driver
  branch stubbed so US1+US2 remain independently committable first.
- US3 reuses `wallet_controller.dart` (T025) and `wallet_seed.dart` (T012) rather than duplicating
  them — extend, don't fork.
- Both US2 and US3 depend on the Foundational phase's `WalletRepository`/`WalletRules`/
  `goora_balance_card`; neither depends on the other's screen code.

## Parallel Examples

- Foundational: T002, T004, T005, T006, T007 together; then T008 (needs T002/T004) + T011 + T016;
  then T009/T015/T017 alongside T012/T013/T014.
- US1: T018/T019/T020/T021 can proceed together once T010/T013 exist; T024 after T020/T022.
- US2: T025 alongside T027/T028; T031/T032/T033 last, after their screens/sheets exist.
- US3: T034 alongside T036; T039/T040 last.

## Implementation Strategy

1. **Session 1**: Setup + Foundational + US1 → MVP: a rider can start a free-trial plan; drivers
   skip it entirely. Commit + converge.
2. **Session 2**: US2 → rider Wallet tab fully functional (plan, balance, top-up, activity,
   breakdown). Commit + converge.
3. **Session 3**: US3 + Polish → driver Wallet tab, withdrawal, goldens, contrast, gates,
   quickstart walkthrough.
