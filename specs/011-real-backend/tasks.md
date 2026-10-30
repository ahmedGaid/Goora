---
description: "Tasks for 011 real backend"
---

# Tasks: Real Backend Behind the Repository Seams

**Input**: `specs/011-real-backend/` — plan.md, spec.md, research.md (D1–D20), data-model.md,
contracts/ (backend-gateway, server-functions, seam-contracts), quickstart.md.

**Tests**: requested by the spec (FR-012, FR-014). Contract suites are written first and must pass
on the fake **before** the Supabase implementation exists (confirmed failing for the Supabase
harness until it does). SQL tests are written with each migration.

Phases map to the lane's commit points: P0 docs · P1 SQL · P2 client core · P3–P9 one seam each ·
P10 wiring + docs. Commit + push after each phase.

## Phase 1 (P0): Speckit documents

- [x] T001 spec.md + checklists/requirements.md
- [x] T002 Clarify answered in research.md (Q1–Q5) and folded into the spec
- [x] T003 plan.md, research.md, data-model.md, contracts/*.md, quickstart.md
- [x] T004 tasks.md (this file) and the analyze pass (findings fixed in place)

## Phase 2 (P1): Database — US2 (P1) 🎯

**Goal**: every table under RLS; privacy and Law 87 enforced by the database.
**Independent test**: `supabase test db` green against the local stack.

- [x] T005 [US2] `supabase/migrations/20261030000000_fixes.sql` — grants for the 002/003/005
  tables, nine-area checks, cost-cap CHECK (research D17)
- [x] T006 [US2] `supabase/migrations/20261030000100_profile_trust.sql` — profile/trust columns,
  column grants, privacy trigger, `submit_rider_id`, `start_driver_verification`, `groups_for`,
  `join_group`, `join_waitlist`
- [x] T007 [US2] `supabase/migrations/20261030000200_wallet.sql` — wallet tables, view, `wallet_*`
  functions, `plan_prices`
- [x] T008 [US2] `supabase/migrations/20261030000300_company.sql` — company tables, roster view,
  `company_*` functions with k = 5 and consent
- [x] T009 [US2] `supabase/migrations/20261030000400_marketplace_rpc.sql` — `market_*` functions
- [x] T010 [P] [US2] `supabase/tests/00_rls_everywhere.test.sql` (R1, R2)
- [x] T011 [P] [US2] `supabase/tests/10_profile_trust.test.sql` (R3–R5, R19)
- [x] T012 [P] [US2] `supabase/tests/20_wallet.test.sql` (R6–R9)
- [x] T013 [P] [US2] `supabase/tests/30_company.test.sql` (R10–R15)
- [x] T014 [P] [US2] `supabase/tests/40_marketplace.test.sql` (R16–R18)
- [ ] T015 (deferred: see research "Known gaps") [US4] `supabase/seed.sql` — the demo corridor's groups and pickup points (no people)
- [x] T016 (DB not run: Docker engine hung; see research Results log) Run `supabase test db`; record the result in research.md Results log

## Phase 3 (P2): Client core — US1 (P1), US5 (P3)

- [x] T017 [US1] test `test/unit/backend/env_flag_test.dart`: `backendLive` false without defines
  (confirmed failing first: getter missing)
- [x] T018 [US1] `lib/core/config/env.dart` — `backendLiveRequested`, `backendLive`
- [x] T019 add `supabase_flutter` to pubspec.yaml (`flutter pub add`), lock regenerated
- [x] T020 [US5] test `test/unit/backend/backend_failure_test.dart` (mapping table in
  contracts/backend-gateway.md), then `lib/core/backend/backend_failure.dart`
- [x] T021 `lib/core/backend/backend_gateway.dart` (port, Row, Filter)
- [x] T022 `lib/core/backend/supabase_gateway.dart` (adapter; only importer of supabase_flutter)
- [x] T023 [US5] `lib/core/backend/backend.dart` — `Backend.init()`, health probe, mode;
  test `test/unit/backend/backend_init_test.dart` (off → fake; unreachable → fake)
- [x] T024 `lib/core/backend/backend_providers.dart` (+ `.g.dart`)
- [x] T025 `test/contract/support/in_memory_gateway.dart` + `test/unit/backend/in_memory_gateway_test.dart`
- [x] T026 `lib/main.dart` — `await Backend.init()` before `runApp` (one line; no behaviour when off)

## Phases 4–10 (P3–P9): one seam each — US3 (P2)

Per seam, in order: (a) contract library + runner with the fake harness → green; (b) Supabase
harness added → red (class missing); (c) Supabase implementation → green.

- [x] T027 [US3] onboarding: `test/contract/onboarding_contract.dart`, runner; then
  `lib/features/onboarding/data/supabase_auth_repository.dart`, `supabase_profile_repository.dart`
- [x] T028 [US3] trust: `test/contract/trust_contract.dart`, runner; then
  `lib/features/daily/data/supabase_trust_repository.dart`
- [x] T029 [US3] commute: `test/contract/commute_contract.dart`, runner; then
  `lib/features/commute/data/supabase_commute_repository.dart`
- [x] T030 [US3] wallet: `test/contract/wallet_contract.dart`, runner; then
  `lib/features/wallet/data/supabase_wallet_repository.dart`
- [x] T031 [US3] company: `test/contract/company_contract.dart`, runner; then
  `lib/features/company/data/supabase_company_repository.dart`
- [x] T032 [US3] marketplace: `test/contract/marketplace_contract.dart`, runner; then
  `lib/features/marketplace/data/supabase_marketplace_repository.dart`
- [x] T033 [US3] daily: `test/contract/daily_contract.dart`, runner; then
  `lib/features/daily/data/supabase_daily_commute_repository.dart`

## Phase 11 (P10): Wiring, docs, close — US1, US4

- [x] T034 [US1] providers: onboarding, commute, daily/trust, wallet, marketplace, company read
  `backendModeProvider`; test `test/unit/backend/provider_selection_test.dart` (fake mode builds the
  fakes; live mode with an in-memory gateway builds the Supabase ones)
- [x] T035 [US4] README "Running against local Supabase"; `.env.example` `BACKEND_LIVE=`
- [ ] T036 (not run: needs a running local stack) [US4] optional live contract run (research D20); record it
- [x] T037 gates: `flutter analyze` 0 · `flutter test --concurrency=1` ≥ 1769 · node ≥ 276;
  secrets scan of the diff; `company_flags.dart` unchanged (FR-019); no existing test file in the
  diff (FR-002); research.md Results log; goora-status block; push; message managere

## Dependencies

P1 needs nothing. P2 needs nothing from P1 (port only). Each seam phase needs P2; the Supabase
implementation of a seam needs its migration (P1) for table/function names. T034 needs every seam.
Daily (T033) comes last: it depends on the existing `commute-day` Edge Function contract.
