# Tasks: Company Network (010)

**Input**: `specs/010-company-network/` — spec, plan, research, data-model, contracts, quickstart.
**Do not start before `006-cairo-ismailia-corridor` is merged into `main`.** Implementation branch
`010-company-network` off that `main`, own worktree. Founder answers to Q1–Q11 may change the
numbers in vectors and tests — re-check the spec's "Touches" column before P2.

Format: `[ID] [P?] [Story] Description` — `[P]` = can run in parallel (different files, no
dependency). Every phase: tests first and confirmed red, then code, then all three gates green
(`flutter analyze` 0 · `flutter test --concurrency=1` · `node --test "supabase/functions/_shared/*.test.ts"`),
then commit.

## Phase 0: Setup (P0)

- [ ] T001 Amend `GOORA_SPEC_KIT_BRIEF.md` (§2 roadmap row, §5 D, "Feature 006: Company network" → 010, price per Q1) and the constitution's roadmap line, with a Sync Impact Report + PATCH bump — **only with the founder's OK** (FR-030). Keep 006's merged text (company network "later, unnumbered, price TBD") as the base.
- [ ] T002 [P] Feature flags `companyInvoicesLive`, `hrStatementExport` (off) next to the existing flag/config home (find it first; constitution: open legal items behind flags) — research R0

## Phase 1: Coverage spike — riskiest first (P1, Opus)

- [ ] T003 Grep `PlanType.company` / `PricingMode.company` under `test/`; list every test that assumes "company covers forever" in research.md under R2 ("P1 spike result")
- [ ] T004 [P] Unit tests `test/unit/plan_company_coverage_test.dart`: company plan with coverage `[enrolled, ∞)` behaves as today; with `[enrolled, left)` `coversTrip` false at/after `left`; `coversDate` true on a day the window overlaps; no coverage attached = today's behaviour (red first)
- [ ] T005 `lib/features/wallet/domain/plan.dart`: optional non-persisted `coverage` (`List<Window>`); `coversTrip`/`coversDate` use it for company (research R2); assert unchanged
- [ ] T006 `fake_marketplace_repository.dart` booking: `plan.coversDate(now.date)` → `plan.coversTrip(now)`; `PricingMode.of` gains `now` and uses `coversTrip(now)` (callers: wallet providers, wallet_controller, marketplace). Tests in `test/unit/plan_company_coverage_test.dart`: a one-off booked one minute after leaving carries the fee; the pricing mode reads perTrip one minute after leaving, same day
- [ ] T007 Checkpoint P1: full suite green with every existing company test untouched (or each change listed under R2)

## Phase 2: Rules + twin (P2, Opus)

- [ ] T008 [P] `test/fixtures/gen_company_vectors.py` + `test/fixtures/company_vectors.json` with every case in `contracts/company-rules.md` § Required vector cases
- [ ] T009 [P] Dart vector test `test/unit/company_vectors_test.dart`; TS test `supabase/functions/_shared/company.test.ts` (both red)
- [ ] T010 `lib/features/company/domain/company_rules.dart` (`CompanyRules`, `Window`) — contract
- [ ] T011 `supabase/functions/_shared/company.ts` twin
- [ ] T012 Re-run the generator: no fixture diff; both suites green

## Phase 3: Model, fake store, seed, seams (P3, Sonnet)

- [ ] T013 [P] Unit tests `test/unit/company_model_test.dart`: JSON round-trip for Company, Enrollment, Invoice, LogEntry; domain rules (public domain refused, one company per domain, lower-case)
- [ ] T014 [P] `lib/features/company/domain/`: `company.dart`, `enrollment.dart`, `invoice.dart`, `company_log.dart`, read models (`RosterRow`, `DashboardMonth`, `StatementLine`), `company_repository.dart` (interface + sealed results) — data-model + contract
- [ ] T015 Unit tests `test/unit/fake_company_repository_test.dart`: register/approve, offerFor states, enroll/leave writes windows, coverageFor, lazy invoices idempotent across a 3-month demo-clock jump, a log entry with the right actor for each company-side change (FR-031), clearAll (red)
- [ ] T016 `lib/features/company/data/fake_company_repository.dart` + `company_seed.dart` (Valeo active, Orange Business pending, 24 seeded employees with month facts — research R10) + `providers.dart`
- [ ] T017 Trust seam: `TrustProfile.workEmail` + fake value (`<first>@valeo.com`) in `daily/domain/trust.dart`, `daily/data/fake_trust_repository.dart`; tests updated
- [ ] T018 Wallet seam tests in `test/unit/fake_wallet_repository_test.dart`: company plan read carries windows; `startCompanyPlan` pauses Monthly with 10 days left and sets `noTrial`; `endCompanyPlan` restores Monthly with 10 days from the leave date; bundle and owed balance unchanged (red)
- [ ] T019 `fake_wallet_repository.dart`: `companyCoverage` function seam, `startCompanyPlan`/`endCompanyPlan`, `company.paused.<id>` (research R8); wallet + company providers wired without a provider cycle (functions, 005 lesson)
- [ ] T020 [P] `daily/domain/notice.dart`: `companyPlanStarted/Ended/Paused/Resumed` + copy keys
- [ ] T021 Settings → Reset clears `company.*`; test

## Phase 4: US1 + US2 — register and enroll (P4, MVP, Sonnet + goora-brand)

- [ ] T022 [P] [US1] Widget tests `test/widget/company_register_test.dart` (ar+en): public domain refused, taken domain refused, pending state, approve demo → active home with minimum and price (red)
- [ ] T023 [P] [US2] Widget tests `test/widget/company_enroll_test.dart` (ar+en): not-on-Goora + Tell HR (also for a pending company — US1 AC5); consent lists sees/never-sees; decline enrolls nothing; agree → plan card "Company · Valeo"; paused personal plan shown (red)
- [ ] T024 [US1] Routes `/company`, `/company/register` in `lib/app/router.dart`; Settings row "Company account"; Settings → Demo: Approve company, Make me Valeo's HR contact
- [ ] T025 [US1] `company_home_screen.dart` (register / pending / HR home / my enrollment states — every state designed) + `register_company_screen.dart`
- [ ] T026 [US2] Rework `wallet/presentation/plan/company_verify_sheet.dart` → `offerFor` states; new `company/presentation/consent_sheet.dart`; enroll via `CompanyRepository.enroll`
- [ ] T027 [US2] Rider Wallet company card: company name, paused-days line, Leave (confirm) in `rider_wallet.dart`
- [ ] T028 [US2] Fee check: unit test that a covered employee's group trip and one-off seat both carry fee 0 and the driver share unchanged; a covered employee gets the subscriber reclaim right on a full car (005 US6, FR-008) and loses it the minute they leave; 007/008 guard order unchanged (FR-007, FR-008, SC-003)
- [ ] T029 ARB keys for P4 (ar first, Egyptian colloquial, lexicon) + `flutter gen-l10n`; list keys in research R11
- [ ] T030 Checkpoint P4: gates green; walk quickstart 1–4 on the emulator

## Phase 5: US3 — invoices and suspension (P5)

- [ ] T031 [P] [US3] Widget tests `test/widget/company_invoices_test.dart` (ar+en): list per closed month, 20 × 99 = 1,980 at 12 enrolled, 34 × 99 at 34, invoice screen shows reference + bank details + due date, paid state after demo (red)
- [ ] T032 [P] [US3] Unit tests: suspension from due + 8 days 00:00; employee trip on the 24th carries the fee and books fine (FR-015, SC-006); paid → covered from that moment; fees during suspension stay (red)
- [ ] T033 [US3] `invoices_screen.dart`, `invoice_screen.dart`; Settings → Demo: Mark invoice paid (bank ref)
- [ ] T034 [US3] Suspend/resume notices to enrolled employees (neutral copy, no amounts)
- [ ] T035 Checkpoint P5: gates green; quickstart 5

## Phase 6: US4 — roster, leaving, log (P6)

- [ ] T036 [P] [US4] Widget tests `test/widget/company_roster_test.dart` (ar+en): roster shows only name/email/since (+ this month's leavers), remove → "left on", log entries with actor (red)
- [ ] T037 [P] [US4] Unit tests for every leave path (self, HR remove, domain removed, contract ended, staff end): next trip fee applies, earlier trips stay free, no trial, paused plan restored, an inbox notice posted (FR-020), leaver counted in the month's peak, re-join same month counts once (SC-007) (red)
- [ ] T038 [US4] `roster_screen.dart`, domain add/remove on company home, `company_log_screen.dart`; Settings → Demo: End contract, Change HR contact
- [ ] T039 [US4] HR-contact-left edge case: company stays active with no HR contact; `/company` for others shows only their enrollment
- [ ] T040 Checkpoint P6: gates green; quickstart 6

## Phase 7: US5 — dashboard (P7)

- [ ] T041 [P] [US5] Unit tests `test/unit/company_dashboard_test.dart`: totals from month facts; money saved = Σ (leg cost − share); parking = going rider trips ÷ workdays; every figure from < 5 → null; route-gap area < 5 not listed; month list = current so far + closed months since start (red)
- [ ] T042 [P] [US5] Privacy test `test/unit/company_privacy_test.dart`: HR read models have no person id / group / pickup / time / share / role fields; dashboard output contains no seeded name or email (SC-005) (red)
- [ ] T043 [US5] `lib/features/company/domain/company_dashboard.dart` (pure aggregator, suppression inside) — research R7; record the CO₂ factor source and the SZ↔SV km in research R7 first
- [ ] T044 [US5] `dashboard_screen.dart` (month picker, figures in words, method lines, "Fewer than 5") + widget tests ar+en
- [ ] T045 Checkpoint P7: gates green; quickstart 7

## Phase 8: US6 — HR statement (P8, droppable — Q6)

- [ ] T046 [P] [US6] Unit tests: consent off by default; statement only for consent-on-at-month-end employees; rider trips only; only received/auto-received shares (Q7); withdrawn consent leaves later months, issued month unchanged (SC-008) (red)
- [ ] T047 [US6] `hrConsent`/`setHrConsent`/`statement` in the fake; "Share my trips with HR" toggle on the Wallet company card with the what-HR-sees text and the "already-issued statements stay" confirm
- [ ] T048 [US6] Widget tests `test/widget/company_statement_test.dart` (ar+en, red first): toggle text, statement lines, withdrawn-consent confirm; then `statement_screen.dart` + route; export stays behind `hrStatementExport` (off) — constitution VIII
- [ ] T049 Checkpoint P8: gates green; quickstart 8

## Phase 9: Polish (P9)

- [ ] T050 [P] Goldens for company home, consent sheet, invoice, dashboard (ar+en) — Windows only
- [ ] T051 [P] New colour pairings into `test/unit/contrast_test.dart`; a11y at 1.3× text on dashboard and invoice
- [ ] T052 [P] `no_hardcoded_values_test.dart` covers `lib/features/company` (check the root recursion)
- [ ] T053 Research R11: full list of new ARB keys (ar/en) for founder review
- [ ] T054 README section "Company network (feature 010)"; full quickstart walk ar + en on the emulator; results in research.md

## Dependencies

P0 (T001 needs founder OK, can trail) → **P1 → P2 → P3** → P4 (MVP) → P5 → P6 → P7 → P8 → P9.
P5–P7 depend on P4's routes; P7 can start after P3 if a second session takes it (different files).
P8 is droppable: nothing in P1–P7 depends on it.

## Parallel examples

- P2: T008 and T009 together, then T010 ‖ T011.
- P4: T022 ‖ T023 (test files), then screens.
- P7: T041 ‖ T042.

## /speckit-analyze — 2026-10-19

1 CRITICAL, 1 HIGH, 4 MEDIUM, 5 LOW, all fixed in the docs (none was a founder decision):
C1 statement screen widget tests ar+en (T048) · F1 peak enrolled is per day, not per minute
(contract, R3, vectors) · F4 `PricingMode.of` uses the exact moment so "Company" stops showing the
minute someone leaves (R2, contract, T006) · F2 HR consent judged at month end (FR-025, data-model)
· F3 seed 12 employees so the minimum-20 invoice shows (R10) · C2 reclaim right tested (T028) ·
B1 "trips shared" defined (R7) · C3 leave notice asserted (T037) · C4 log writes asserted (T015) ·
P1 untested perf targets dropped (plan) · F5 pending company shows "not on Goora yet" (T023).
Coverage after fixes: 32/32 FR, 8/8 SC, 54 tasks, 0 unmapped. 11 founder markers (Q1–Q11) open by design.
