# Tasks: Live-Mode Parity for the Real Backend (013)

**Input**: [spec.md](spec.md) · [plan.md](plan.md) · [research.md](research.md) · [data-model.md](data-model.md) · [contracts/server-functions.md](contracts/server-functions.md)
**Rule**: tests first, confirmed failing, then the code. Existing tests and contracts are the floor:
extend, never weaken. One commit and push per phase. `[P]` = can run in parallel (different files).

## Phase 0 — speckit (US all)

- [x] T001 spec.md + checklists/requirements.md
- [x] T002 research.md (clarify answers, decisions D1–D16)
- [x] T003 plan.md, data-model.md, contracts/server-functions.md, quickstart.md
- [x] T004 tasks.md (this file) + analyze pass appended to research.md; fix criticals

## Phase 6 — small debts first (US7)

- [ ] T005 [US7] New test file `test/unit/fake_trust_ids_test.dart` (no existing test edited): two contract adds back to back with no pause give different ids (fails today on a fast clock)
- [ ] T006 [US7] `lib/features/daily/data/fake_trust_repository.dart`: contact ids from a counter, not the microsecond clock; existing fake tests pass unedited
- [ ] T007 [US7] `test/contract/trust_contract.dart`: remove the 5 ms pacing; contract green on both halves

## Phase 1 — database truth and seed (US2)

- [ ] T008 [US2] Scratch stack: copy `supabase/` to the scratchpad with `config.toml` ports +1000 and `project_id = "goora011"`; document in README (D19 of 011)
- [ ] T009 [US2] Check `docker info`; if it answers: `supabase start`, `supabase db reset`, `supabase test db`; record exact numbers in research.md "Results log". If not: D15 fallback harness in `supabase/scratch/` and label the run "scratch PG16 + shim"
- [ ] T010 [US2] For each failing pgTAP test: fix in a NEW migration `supabase/migrations/20261031000000_pgtap_fixes.sql` (never edit an applied one); re-run to green
- [ ] T011 [US2] `supabase/seed.sql` (D13): corridors, 3 groups with pickup points, "Demo Motors" with 6 enrolled employees (5 consenting), all fictional, idempotent
- [ ] T012 [US2] `supabase/tests/80_seed.test.sql`: counts, no real-looking e-mail/phone, ≥ 1 group per corridor, ≥ 5 enrolled
- [ ] T013 [US2] `supabase db reset` clean with seed; whole suite green; Results log updated; commit + push

## Phase 2 — wallet live (US3)

- [ ] T014 [US3] [P] `supabase/tests/gen_vector_tests.mjs` + `_shared/vector_sql.test.ts` guard (regenerate in memory, compare to committed `60_vectors.test.sql`); guard fails first
- [ ] T015 [US3] [P] Extend `test/contract/wallet_contract.dart` with cases W-T1…W-T9: first 5 trips fee-free · 6th pays the fee · 150 owed is due the same day · 30 at month end is due on the 1st, 29 carries over · overdue after 3 days · bundle trip uses no fee · charge and free-cancel rows · share carries first name and the rider's real method · no driver-income kind; harness gets a daily source with trips (fake) and the same facts on the emulated server (supabase). Fails first
- [ ] T016 [US3] Migration `20261031000100_wallet_state.sql`: `pay_equal_share`, `pay_cash_amount`, `direct_pay_share`, `direct_pay_fee`, `is_late`, `fee_due_date`, `wallet_state`, `wallet_assert_open`, `wallet_share_rows`; revoke from public/anon
- [ ] T017 [US3] Generate `60_vectors.test.sql` from the JSON fixtures; `supabase/tests/50_wallet_state.test.sql` (trial, due, overdue, bundle, privacy of share rows, no income kind/column, `authenticated` only)
- [ ] T018 [US3] `test/contract/support/server.dart`: emulate `wallet_state`, `wallet_share_rows`, `wallet_assert_open` using the domain rules
- [ ] T019 [US3] `SupabaseWalletRepository`: `getWallet` from `wallet_state` (cashTrial, feeDue, feeOverdue, feesThisMonth, bundleTripsLeft, derived entries) and shares from `wallet_share_rows`; contract green on both halves
- [ ] T020 [US3] Migration `20261031000150_overdue_guard.sql`: `market_book`/`market_post`/`market_accept` and `join_group` call `wallet_assert_open()` (008 FR-005 names Book, Post, accept, Join); pgTAP case; Dart maps the `feeOverdue` refusal to the existing results
- [ ] T021 [US3] Commit + push phase 2

## Phase 3 — marketplace live (US4)

- [ ] T022 [US4] [P] Extend `test/contract/marketplace_contract.dart`: M-T1 offer carries driver first name and nothing private · M-T2 `driverDay` lists group legs and offers in time order · M-T3 `requestsForMe` lists others' posted requests only · M-T4 `reclaim` refunds / refuses subscriber / refuses late · M-T5 `doneOneOffs` lists a finished seat. Fails first
- [ ] T023 [US4] Migration `20261031000200_marketplace_live.sql`: `market_offer_cards`, `market_requests_for`, `market_done_one_offs`, `market_reclaim`
- [ ] T024 [US4] `supabase/tests/60_marketplace_live.test.sql`: first-name-only columns, other drivers cannot read others' requests via the function beyond posted, reclaim rules, refund row, no phone/home columns in any returned row
- [ ] T025 [US4] `test/contract/support/server.dart`: emulate the four functions
- [ ] T026 [US4] `SupabaseMarketplaceRepository`: names from `market_offer_cards`, group legs in `driverDay`, `requestsForMe`, `reclaim`, `doneOneOffs`; remove the "Known gaps" comment; contract green
- [ ] T027 [US4] Commit + push phase 3

## Phase 4 — daily live (US5)

- [ ] T028 [US5] [P] Extend `test/contract/daily_contract.dart`: D-T1 an unstored ride has a token that is stable on re-read · D-T2 three riders see three own stops · D-T3 `chooseNoCoverOption(dayOff)` is stored and read back, other options change nothing. Fails first
- [ ] T029 [US5] `commute-day/index.ts`: actions `ride` and `noCover` (+ `_shared` helper with a node test for the refusal rule)
- [ ] T030 [US5] `test/contract/support/server.dart`: emulate the two actions
- [ ] T031 [US5] `SupabaseDailyCommuteRepository.ride()` calls the `ride` action when no row exists, then reads the stored row; `chooseNoCoverOption` calls `noCover`; remove the "Known gaps" comment; contract green
- [ ] T032 [US5] Commit + push phase 4

## Phase 5 — company live (US6)

- [ ] T033 [US6] [P] Extend `test/contract/company_contract.dart`: C-T1 six enrolled, two suspended → coverage counts four · C-T2 fewer than five behind money/CO₂/parking → withheld · C-T3 five or more → shown · C-T4 route gap below five left out · C-T5 `clearAll` removes only own rows · C-T6 staff `demo*` are no-ops on live. Fails first
- [ ] T034 [US6] Migration `20261031000300_company_live.sql`: `corridor_legs`, `company_suspensions`, replaced `company_dashboard`, `company_reset_mine`, `staff_*` (service_role only)
- [ ] T035 [US6] `supabase/tests/70_company_live.test.sql`: k = 5 on each total, route gaps, suspensions visibility (HR + enrolled only), `staff_*` refused for `authenticated`, allowed for `service_role` and logged, reset touches own rows only
- [ ] T036 [US6] `test/contract/support/server.dart`: emulate `company_suspensions`, the new dashboard keys and `company_reset_mine`
- [ ] T037 [US6] `SupabaseCompanyRepository`: `coverageFor` subtracts suspensions via `CompanyRules.activeWindows`; `dashboard` maps the new keys; `clearAll` calls `company_reset_mine`; `demo*` documented "demo only on fakes"; contract green; `company_flags.dart` unchanged
- [ ] T038 [US6] Commit + push phase 5

## Phase last — close

- [ ] T039 README "Running against local Supabase": seed, reset, tests, ports, the D15 note
- [ ] T040 research.md: Results log with real numbers; every "Known gap" row marked closed or re-filed with a reason
- [ ] T041 Gates in the worktree: `flutter analyze` 0 · `flutter test --concurrency=1` ≥ 1944 green · `node --test` ≥ 276 green · pgTAP result recorded · `git diff main -- test/` shows no edited existing test (new files and added cases only) · `company_flags.dart` unchanged · diff scan finds no secret
- [ ] T042 Dated block at the TOP of the `goora-status` skill (own block only)
- [ ] T043 Commit + push the branch; do not merge or push main
- [ ] T044 SendMessage "the managere": "Lane H done" with gate numbers, files touched, goldens changed (expected: none)
- [ ] T045 Final report to the user with a How-to-test block and the `/goal` pointer block (Docs/NEXT_GOAL.md is the conductor's to write)

## Dependencies

P0 → P6 → P1 → {P2, P3, P4, P5} (P2 before P3: the marketplace gate reads the wallet's fee state) →
P-last. Inside a phase: contract/test tasks → SQL → emulation → Dart repository → commit.
