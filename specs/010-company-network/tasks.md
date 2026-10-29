# Tasks: Company Network (010)

**Input**: `specs/010-company-network/` — spec, plan, research, data-model, contracts, quickstart.
`006-cairo-ismailia-corridor` has merged into `main`. Implementation branch `010-company-network`
off that `main`, own worktree; merged into `main` 2026-10-29 (`30b8181`). Founder answers to Q1–Q11 may change the
numbers in vectors and tests — re-check the spec's "Touches" column before P2.

Format: `[ID] [P?] [Story] Description` — `[P]` = can run in parallel (different files, no
dependency). Every phase: tests first and confirmed red, then code, then all three gates green
(`flutter analyze` 0 · `flutter test --concurrency=1` · `node --test "supabase/functions/_shared/*.test.ts"`),
then commit.

## Phase 0: Setup (P0)

- [ ] T001 Amend `GOORA_SPEC_KIT_BRIEF.md` (§2 roadmap row, §5 D, "Feature 006: Company network" → 010, price per Q1) and the constitution's roadmap line, with a Sync Impact Report + PATCH bump — **only with the founder's OK** (FR-030). Keep 006's merged text (company network "later, unnumbered, price TBD") as the base. — **006 has merged; waits only for the founder's OK — touches `GOORA_SPEC_KIT_BRIEF.md`, `.specify/memory/constitution.md`** (Lane B 2026-10-20 did new files only)
- [x] T002 [P] Feature flags `companyInvoicesLive`, `hrStatementExport` (off) next to the existing flag/config home (find it first; constitution: open legal items behind flags) — research R0 — done 2026-10-20: home is `lib/core/config/env.dart` (existing file, waits for 006), so new `lib/features/company/company_flags.dart` + `test/unit/company_flags_test.dart` (research "Lane B notes")

## Phase 1: Coverage spike — riskiest first (P1, Opus)

- [x] T003 Grep `PlanType.company` / `PricingMode.company` under `test/`; list every test that assumes "company covers forever" in research.md under R2 ("P1 spike result") — done 2026-10-20 (Lane A): list in research R2 "P1 spike result"; every hit has no windows attached and keeps its meaning
- [x] T004 [P] Unit tests `test/unit/plan_company_coverage_test.dart`: company plan with coverage `[enrolled, ∞)` behaves as today; with `[enrolled, left)` `coversTrip` false at/after `left`; `coversDate` true on a day the window overlaps; no coverage attached = today's behaviour (red first) — done 2026-10-20 (Lane A): 8 Plan cases (+ gap, empty, non-company, JSON) red first
- [x] T005 `lib/features/wallet/domain/plan.dart`: optional non-persisted `coverage` (`List<Window>`); `coversTrip`/`coversDate` use it for company (research R2); assert unchanged — done 2026-10-20 (Lane A): `coverage` + `withCoverage`; assert unchanged
- [x] T006 `fake_marketplace_repository.dart` booking: `plan.coversDate(now.date)` → `plan.coversTrip(now)`; `PricingMode.of` gains `now` and uses `coversTrip(now)` (callers: wallet providers, wallet_controller, marketplace). Tests in `test/unit/plan_company_coverage_test.dart`: a one-off booked one minute after leaving carries the fee; the pricing mode reads perTrip one minute after leaving, same day — done 2026-10-20 (Lane A): `PricingMode.of(now:)` replaces `today:`; booking test on the real fakes (fee 4 one minute after leaving, 0 one minute before); `FakeWalletRepository(companyCoverage:)` seam added early for it
- [x] T007 Checkpoint P1: full suite green with every existing company test untouched (or each change listed under R2) — done 2026-10-20 (Lane A): 1457 → 1469 green; one existing test changed (`wallet_rules_test.dart`, 4 calls `today:` → `now:`), listed under R2

## Phase 2: Rules + twin (P2, Opus)

- [x] T008 [P] `test/fixtures/gen_company_vectors.py` + `test/fixtures/company_vectors.json` with every case in `contracts/company-rules.md` § Required vector cases
- [x] T009 [P] Dart vector test `test/unit/company_vectors_test.dart`; TS test `supabase/functions/_shared/company.test.ts` (both red)
- [x] T010 `lib/features/company/domain/company_rules.dart` (`CompanyRules`, `Window`) — contract
- [x] T011 `supabase/functions/_shared/company.ts` twin
- [x] T012 Re-run the generator: no fixture diff; both suites green — done 2026-10-20: 50 vectors, Dart 50/50, node 214 → 264, sha1 unchanged on re-run

## Phase 3: Model, fake store, seed, seams (P3, Sonnet)

- [x] T013 [P] Unit tests `test/unit/company_model_test.dart`: JSON round-trip for Company, Enrollment, Invoice, LogEntry; domain rules (public domain refused, one company per domain, lower-case) — done 2026-10-20 (16 tests; "one company per domain" is a repository rule, tested in T015)
- [x] T014 [P] `lib/features/company/domain/`: `company.dart`, `enrollment.dart`, `invoice.dart`, `company_log.dart`, read models (`RosterRow`, `DashboardMonth`, `StatementLine`), `company_repository.dart` (interface + sealed results) — data-model + contract — done 2026-10-20: plus `company_terms.dart` (founder numbers), `hr_views.dart` (read models), `employee_month_facts.dart`; deviations in research "Lane B notes"
- [x] T015 Unit tests `test/unit/fake_company_repository_test.dart`: register/approve, offerFor states, enroll/leave writes windows, coverageFor, lazy invoices idempotent across a 3-month demo-clock jump, a log entry with the right actor for each company-side change (FR-031), clearAll (red) — done 2026-10-20 (27 tests, red first)
- [x] T016 `lib/features/company/data/fake_company_repository.dart` + `company_seed.dart` (Valeo active, Orange Business pending, 24 seeded employees with month facts — research R10) + `providers.dart` — done 2026-10-20: seed = **12** employees per R10 / analyze F3 (round brief said 24 — research "Lane B notes" #1); `providers.dart` imports no wallet/marketplace code (`company_providers_test.dart`); person lookup returns nobody until T017
- [x] T017 Trust seam: `TrustProfile.workEmail` + fake value (`<first>@valeo.com`) in `daily/domain/trust.dart`, `daily/data/fake_trust_repository.dart`; tests updated — done 2026-10-20 (Lane A): `workEmailFor`, non-Latin first name → `employee@`; tests in `company_wallet_seam_test.dart`; company person lookup wired through Trust
- [x] T018 Wallet seam tests in `test/unit/fake_wallet_repository_test.dart`: company plan read carries windows; `startCompanyPlan` pauses Monthly with 10 days left and sets `noTrial`; `endCompanyPlan` restores Monthly with 10 days from the leave date; bundle and owed balance unchanged (red) — done 2026-10-20 (Lane A): 6 cases in a "company plan seam (010)" group; balance, bundle and every activity row compared before/after (red first)
- [x] T019 `fake_wallet_repository.dart`: `companyCoverage` function seam, `startCompanyPlan`/`endCompanyPlan`, `company.paused.<id>` (research R8); wallet + company providers wired without a provider cycle (functions, 005 lesson) — done 2026-10-20 (Lane A): + `pausedPlan`, `wallet.coveredBefore.<id>`, `wallet.noTrialFrom.<id>`, `CompanyRepository.hasEnrolled`; provider test `company_wallet_seam_test.dart`; who *calls* start/end is P4/P6 (research "Lane A notes" #6)
- [x] T020 [P] `daily/domain/notice.dart`: `companyPlanStarted/Ended/Paused/Resumed` + copy keys — **partly done 2026-10-20 (Lane A): the 5 ARB keys + copy test; the 4 `NoticeKind` values wait for P4 (their label switch is in `daily/presentation/labels.dart`, Lane B's this round) — research "Lane A notes" T020 split** — rest done 2026-10-20 (P4): 4 kinds + `personalPlanBack`, label arms, posted on join/leave
- [x] T021 Settings → Reset clears `company.*`; test — done 2026-10-20 (Lane A): `demo_section.dart` + `test/widget/settings_reset_company_test.dart` (red first)

## Phase 4: US1 + US2 — register and enroll (P4, MVP, Sonnet + goora-brand)

- [x] T022 [P] [US1] Widget tests `test/widget/company_register_test.dart` (ar+en): public domain refused, taken domain refused, pending state, approve demo → active home with minimum and price (red)
- [x] T023 [P] [US2] Widget tests `test/widget/company_enroll_test.dart` (ar+en): not-on-Goora + Tell HR (also for a pending company — US1 AC5); consent lists sees/never-sees; decline enrolls nothing; agree → plan card "Company · Valeo"; paused personal plan shown (red)
- [x] T024 [US1] Routes `/company`, `/company/register` in `lib/app/router.dart`; Settings row "Company account"; Settings → Demo: Approve company, Make me Valeo's HR contact
- [x] T025 [US1] `company_home_screen.dart` (register / pending / HR home / my enrollment states — every state designed) + `register_company_screen.dart`
- [x] T026 [US2] Rework `wallet/presentation/plan/company_verify_sheet.dart` → `offerFor` states; new `company/presentation/consent_sheet.dart`; enroll via `CompanyRepository.enroll`
- [x] T027 [US2] Rider Wallet company card: company name, paused-days line, Leave (confirm) in `rider_wallet.dart`
- [x] T028 [US2] Fee check: unit test that a covered employee's group trip and one-off seat both carry fee 0 and the driver share unchanged; a covered employee gets the subscriber reclaim right on a full car (005 US6, FR-008) and loses it the minute they leave; 007/008 guard order unchanged (FR-007, FR-008, SC-003)
- [x] T029 ARB keys for P4 (ar first, Egyptian colloquial, lexicon) + `flutter gen-l10n`; list keys in research R11
- [x] T030 Checkpoint P4: gates green; walked quickstart 1, 3, 4 on the emulator 2026-10-21 (specs/010-company-network/walk/README.md): 0 blockers, 3 should-fix F-1..F-3, quickstart 2 not walkable

## Phase 5: US3 — invoices and suspension (P5)

- [x] T031 [P] [US3] Widget tests `test/widget/company_invoices_test.dart` (ar+en): list per closed month, 20 × 99 = 1,980 at 12 enrolled, 34 × 99 at 34, invoice screen shows reference + bank details + due date, paid state after demo (red) — done: 5 tests x ar+en (list, 20 × 99, invoice screen, waiting→paid, overdue note)
- [x] T032 [P] [US3] Unit tests: suspension from due + 8 days 00:00; employee trip on the 24th carries the fee and books fine (FR-015, SC-006); paid → covered from that moment; fees during suspension stay (red) — done: `company_suspension_test.dart` (6) passed first run, the rules existed from P2/P3
- [x] T033 [US3] `invoices_screen.dart`, `invoice_screen.dart`; Settings → Demo: Mark invoice paid (bank ref) — done: + Demo "skip to suspension day" (needed to walk quickstart 5)
- [x] T034 [US3] Suspend/resume notices to enrolled employees (neutral copy, no amounts) — done: sync in `companyAccount` provider (runs when the Wallet company card or company area loads), `company_suspension_notice_test.dart`
- [x] T035 Checkpoint P5: gates green (analyze 0 · flutter 1567 · node 276); quickstart 5 NOT yet walked on the emulator — Demo "skip to suspension" + "mark paid" are the way in

## Phase 6: US4 — roster, leaving, log (P6)

- [x] T036 [P] [US4] Widget tests `test/widget/company_roster_test.dart` (ar+en): roster shows only name/email/since (+ this month's leavers), remove → "left on", log entries with actor (red) — done 2026-10-29 (P6)
- [x] T037 [P] [US4] Unit tests for every leave path (self, HR remove, domain removed, contract ended, staff end): next trip fee applies, earlier trips stay free, no trial, paused plan restored, an inbox notice posted (FR-020), leaver counted in the month's peak, re-join same month counts once (SC-007) (red) — done 2026-10-29 (P6): `test/unit/company_leave_paths_test.dart`, red with the sync off
- [x] T038 [US4] `roster_screen.dart`, domain add/remove on company home, `company_log_screen.dart`; Settings → Demo: End contract, Change HR contact — done 2026-10-29 (P6)
- [x] T039 [US4] HR-contact-left edge case: company stays active with no HR contact; `/company` for others shows only their enrollment — done 2026-10-29 (P6): covered in `company_roster_test.dart`
- [x] T040 Checkpoint P6: gates green; quickstart 6 — walked 2026-10-29 (`walk5/REPORT.md`); the removed employee's next trip not walked

## Phase 7: US5 — dashboard (P7)

- [x] T041 [P] [US5] Unit tests `test/unit/company_dashboard_test.dart`: totals from month facts; money saved = Σ (leg cost − share); parking = going rider trips ÷ workdays; every figure from < 5 → null; route-gap area < 5 not listed; month list = current so far + closed months since start (red) — done 2026-10-29 (P7): `company_dashboard_test.dart` (11 tests; aggregator written before the first run, so no red run)
- [x] T042 [P] [US5] Privacy test `test/unit/company_privacy_test.dart`: HR read models have no person id / group / pickup / time / share / role fields; dashboard output contains no seeded name or email (SC-005) (red) — done 2026-10-29 (P7): `company_privacy_test.dart` (3; scans `hr_views.dart` field names)
- [x] T043 [US5] `lib/features/company/domain/company_dashboard.dart` (pure aggregator, suppression inside) — research R7; record the CO₂ factor source and the SZ↔SV km in research R7 first — done 2026-10-29 (P7): factor 0.1645 (UK DESNZ 2024, via mirror), leg km 13 (estimate); R7 + "P7 notes"
- [x] T044 [US5] `dashboard_screen.dart` (month picker, figures in words, method lines, "Fewer than 5") + widget tests ar+en — done 2026-10-29 (P7): `company_dashboard_screen.dart`, route `/company/dashboard`, HR-home button "Company numbers", `test/widget/company_dashboard_test.dart` (5 x ar+en)
- [x] T045 Checkpoint P7: gates green; quickstart 7 — walked 2026-10-29, Arabic + English 1.3× (`walk5/REPORT.md`); "Fewer than 5" not walked

## Phase 8: US6 — HR statement (P8, droppable — Q6)

- [x] T046 [P] [US6] Unit tests: consent off by default; statement only for consent-on-at-month-end employees; rider trips only; only received/auto-received shares (Q7); withdrawn consent leaves later months, issued month unchanged (SC-008) (red) — done 2026-10-29: `test/unit/company_hr_statement_test.dart` (19 tests); red not observed, see research "P8 notes"
- [x] T047 [US6] `hrConsent`/`setHrConsent`/`statement` in the fake; "Share my trips with HR" toggle on the Wallet company card with the what-HR-sees text and the "already-issued statements stay" confirm — done 2026-10-29: fake + seed consents/shares, `HrConsentToggle` on the Wallet company card; ar/en keys in research "P8 notes" R11
- [x] T048 [US6] Widget tests `test/widget/company_statement_test.dart` (ar+en, red first): toggle text, statement lines, withdrawn-consent confirm; then `statement_screen.dart` + route; export stays behind `hrStatementExport` (off) — constitution VIII — done 2026-10-29: `test/widget/company_statement_test.dart` (10 tests x ar+en), `statement_screen.dart`, route `/company/statement`; no export control (flag off)
- [x] T049 Checkpoint P8: gates green; quickstart 8 — gates green 2026-10-29 (analyze 0 in my files, flutter 1669, node 276); quickstart 8 NOT WALKED (no emulator); widget tests ar+en cover it

## Phase 9: Polish (P9)

- [x] T050 [P] Goldens for company home, consent sheet, invoice, dashboard (ar+en) — Windows only — done 2026-10-29 (`c2fccaf`, 8 goldens); P8 statement screen golden (ar + en) added 2026-10-29 in `company_screens_golden_test.dart`
- [x] T051 [P] New colour pairings into `test/unit/contrast_test.dart`; a11y at 1.3× text on dashboard and invoice — done 2026-10-29 (`e934c33`; includes the P8 switch pairings)
- [x] T052 [P] `no_hardcoded_values_test.dart` covers `lib/features/company` (check the root recursion) — done 2026-10-29 (`45e8783`)
- [x] T053 Research R11: full list of new ARB keys (ar/en) for founder review — done 2026-10-29 (`129022d`, 139 keys; gendered "خرج من الخطة" flagged)
- [ ] T054 README section "Company network (feature 010)"; full quickstart walk ar + en on the emulator; results in research.md — README part done 2026-10-29 (`74a2af8`); full ar + en emulator walk NOT WALKED, results not yet in research.md
- [x] T055 [P] Edge cases from the spec that had a sentence but no test (research "P8/P9 notes", C1): price change mid-contract, work email moved (same company stays, other company leaves — **red, fixed** in `FakeCompanyRepository._leaveIfMoved`), 009 ID check not skipped on enrol, driver-only employee enrols — done 2026-10-29: `test/unit/company_edge_cases_test.dart` (8), `test/widget/company_driver_enroll_test.dart` (ar+en)
- [x] T056 [P] Every screen in `lib/features/company/presentation` at 1.3× text, ≥ 44 px targets, labelled tappables, ar + en (C2; extends T051) — done 2026-10-29: `test/widget/company_text_scale_test.dart` (26); one red fixed with `AppSizes.minTouch` (invoice reference), invoice goldens regenerated
- [x] T057 [P] [US6] A non-HR user sees no statement (U2); statement rows have no fee column (A1) — done 2026-10-29: `test/widget/company_statement_guard_test.dart` (8, ar+en); the header "Goora's fee 0" line is flagged for the founder, not removed

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

## /speckit-analyze — 2026-10-29 (integration run, after P9)

0 CRITICAL, 0 HIGH, 4 MEDIUM, 8 LOW. No constitution MUST is violated. Coverage: 32/32 FR and 8/8 SC mapped to
a task, 57 tasks (T055–T057 added), 0 unmapped; FR-030 / T001 wait for the founder's OK, SC-001 and SC-002 can
only be timed in the T054 device walk.
Fixed in the docs (doc-only): spec header said "P0–P7 built" and plan/tasks did not say 010 is in `main` ·
FR-013 "7 days after due" now says "from 00:00 on the 8th day" (matches `CompanyRules.suspendFromDay` and T032) ·
SC-007 lists the new email-moved leave path · spec Clarifications 2026-10-29 (unheld domain / no email stays
enrolled; A1 open) · plan: ARB key count (155) and the source list (hr_consent_toggle, hr_statement, hr_views,
employee_month_facts, company_terms, company_flags) · quickstart step 2 (the Demo "end contract" action exists) ·
T055–T057 record the edge-case, 1.3× and statement-guard tests.
Open for the founder, not changed: A1 (FR-025 "fees show as 0" vs FR-013, one header line still says 0) · A2
(headcount hidden under 5 while the roster lists every name) · SC-001/SC-002 untimed · the constitution's roadmap
line and `feature/00X-name` branch wording (T001; every feature since 001 uses `NNN-name`) · Arabic copy:
حصة vs نصيب, masculine-default lines, اشترك/مشترك used for both enrolling and the personal subscription (R11).
Left as LOW: a non-HR user who types `/company/statement` sees
"the first statement appears once the first month has ended" (no entry reaches it from the UI).
