# Tasks: Pay Later and Trip Bundle (008)

## Phase 1: Twinned rules

- [x] T001 [P] Vectors `test/fixtures/fee_balance_vectors.json` (due: none owed, under 150 mid-month, crosses 150, month-end 28 carries, month-end 30 due on the 1st, cleared then a new run; overdue: day 2 no, day 3 yes; bundle: fee 0 / left 0 / both > 0)
- [x] T002 [P] Dart test `test/unit/fee_balance_vectors_test.dart`; TS test `supabase/functions/_shared/fee_balance.test.ts`
- [x] T003 `lib/features/wallet/domain/fee_balance.dart` FeeBalancePolicy + TripBundle (R2, R3)
- [x] T004 `supabase/functions/_shared/fee_balance.ts` twin

## Phase 2: US1 + US4 — ledger walk

- [x] T005 [US1] ActivityKind settlement/bundle/bundleTrip; Wallet owed/feeDue/feeOverdue/bundleTripsLeft
- [x] T006 [US4] Walk consumes bundle trips when fee > 0 (FR-008); trips left derived
- [x] T007 [US1] End-of-day balance series from all rows → FeeBalancePolicy.dueDate / isOverdue
- [x] T008 Unit tests in `test/unit/fake_wallet_repository_test.dart` (owed, bundle, due, overdue)

## Phase 3: US2 — settle + buy

- [x] T009 [US2] `settle(riderId, method)`, `buyBundle(riderId, method)` via provider.debit; failure writes nothing
- [x] T010 [US2] Unit tests: one transaction, failure unchanged, bundle has no balance delta

## Phase 4: US3 — overdue gate

- [x] T011 [US3] BookingGate feeOverdue; BookFeeOverdue / PostFeeOverdue; demo accept withdraws; join guard
- [x] T012 [US3] Unit tests on gate + marketplace

## Phase 5: UI

- [x] T013 ARB keys (contract) ar/en, gen-l10n; `feeSavings` copy per brief §8
- [x] T014 Fee card (owed, due line, Pay), settle sheet (methods incl. Fawry code), bundle card + buy in rider wallet
- [x] T015 Overdue banner on rider Today; empty seats / post notices for overdue (notices built; no widget test for the overdue notice — covered by gate unit tests)
- [x] T016 Widget tests ar/en; goldens regenerated

## Phase 6: Polish

- [x] T017 Brief §6.7 pay-later paragraph · gates · tasks ticked
- [ ] T018 Quickstart device walkthrough (needs emulator) — NOT RUN 2026-10-19
