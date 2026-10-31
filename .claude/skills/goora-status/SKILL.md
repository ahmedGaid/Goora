---
name: goora-status
description: Live status anchor for Goora — the daily-commute coordination Flutter app for Egypt at C:\AhmedGaid\Goora — current position, exact NEXT ACTION, and any blocker. Recall at the start of ANY session that continues, resumes, plans, or checks the Goora build (goora-resume recalls this first). Lean anchor; architecture → goora-stack, brand → goora-brand.
---

# goora-status — Goora live state

**Project** Flutter app, Arabic-first (Egyptian colloquial) / RTL, matches people for a shared
daily commute and runs it as a trusted recurring group. Cost-sharing only, never a taxi (Law
87/2018 constraint — drivers never profit).
**Path** `C:\AhmedGaid\Goora` · **Repo** `https://github.com/ahmedGaid/Goora.git` (connected
2026-10-06) · **App ID** `app.goora.goora`

## Position — 2026-10-31 (Lane H, 013 live-mode parity), branch `013-live-parity` pushed (worktree Goora-live, from main 4d9f212), NOT merged to main
Done: `specs/013-live-parity/` full set + analyze (D1–D16, results log). Live mode now matches the fakes: wallet fee state (5 fee-free trips, owed, due at 150 / month-end ≥ 30, overdue after 3 days, trip rows, shares with first name + real method) decided in the DB by `wallet_state()` + server overdue guard on book/post/accept/join; marketplace (driver first name via `market_offer_cards`, group legs in `driverDay`, `requestsForMe`, `reclaim`, `doneOneOffs`, and `accept` no longer blind under RLS); daily (`commute-day` `ride` + `noCover`: unstored ride stored on first read, real token, own stop); company (coverage minus suspensions, dashboard money/CO₂/parking/route gaps under k ≥ 5, `company_reset_mine`, service-role-only `staff_*`; `demo*` stay "demo only on the fakes"); `supabase/seed.sql` (14 demo groups + "Demo Motors" with 6 employees); F1 fixed. 4 new migrations `supabase/migrations/20261031000*`; SQL twins of pricing/direct-pay/fee-balance/cut-off run the shared JSON vectors (`60_vectors.test.sql` generated, stale-guard in `node --test`). Gates: analyze 0 · flutter 1984 · node 281 · no golden changed · `backendLive` still OFF by default, flags untouched.
**DB: real `supabase db reset` + `supabase test db` NOT run** — Docker hung all lane (conductor told). Run instead on a throwaway PG16 with a shim + real pgTAP (`supabase/scratch/run_scratch.sh`): 256/256 ok. Re-filed: accept-that-joins-an-existing-trip (`market_accept_join`), a live contract runner, Edge glue untested (no Deno).
**NEXT ACTION**: conductor merges `013-live-parity`; founder restarts Docker Desktop, then `supabase db reset` + `supabase test db` on the shifted-port stack and walk the app with `BACKEND_LIVE=true` (README). **Blocker**: Docker Desktop (founder restart); hosted Supabase / keys / deploy = founder; OTP + payments = 012.

## Position — 2026-10-30 (Lane 011 real backend), branch `011-real-backend` pushed (worktree Goora-011, main b618c1f merged in), NOT merged to main
Done: speckit set `specs/011-real-backend/` (D1–D25, known gaps, results log) · 5 migrations `supabase/migrations/20261030000*` (RLS on every table, column grants, company k = 5 + consent, no driver-income ledger kind) + 5 pgTAP files `supabase/tests/` · `lib/core/backend/` (gateway port, SupabaseGateway, failure mapping, `Backend.initFromEnv` with health probe → fake fallback) · `Supabase*Repository` for auth/profile, trust, commute, daily, wallet, company, marketplace, each passing the same contract as its fake (`test/contract/`, 92 cases) · providers switch on `backendModeProvider` · `Env.backendLive` = `BACKEND_LIVE` && Supabase env, default OFF, app unchanged without env · README "Running against local Supabase". Flags companyInvoicesLive / hrStatementExport untouched. **SQL tests: DB not run** (Docker engine hung; not restarted, another project's stack runs on it). Gates: analyze 0 · flutter 1944 · node 276.
**NEXT ACTION**: conductor merges `011-real-backend`; then run the pgTAP suite on the shifted-port local stack (research D19, Results log) and fix whatever SQL fails; then close the live-mode gaps (research "Known gaps": wallet trial/fee due, driver cards, requestsForMe, seed.sql).
**Blocker**: hosted Supabase / real keys / deploy = founder; OTP + payments = 012.

## Position — 2026-10-29 (010 integration + hardening run), main @ `f16b9dc` = origin/main (010 P0–P9 + statement golden in) · branch `010-integration` = main + this run, local only, NOT pushed, NOT merged (worktree Goora-010-int)
Done: the two side branches (wallet plural + demo corridor, removed-employee tests) merged; T050–T053 verified by commit and test; the four spec edge cases that had no test now have one (price change mid-contract, email moved, 009 ID check on enrol, driver-only) plus zero-enrolled month, HR who rides, same-company filter. One real bug: a work email moved to another company's domain left the employee enrolled in the first (fixed in `FakeCompanyRepository._leaveIfMoved`, a sixth leave path in `company_leave_paths_test.dart`; no `CompanyRules` change, no TS twin change). Every company screen now checked at 1.3× / 44 px / labels, ar + en (one fix: invoice reference box). Copy audit: 2 statement money lines now name the driver; rest listed for the founder in research "R11 addendum" (حصة vs نصيب, every gendered line). U2 (non-HR sees no statement) and A1 (no fee column) tested; the statement header still says "Goora's fee 0" (flagged). `/speckit-analyze`: 0 critical, 0 high, 4 medium, 8 low, doc-only fixes applied, T055–T057 added. Arabic sweep test guards digits, ج.م, سائق/مقعد, رحلة. Gates: analyze 0 · flutter 1741 · node 276.
**NEXT ACTION**: founder OK → merge `010-integration` and push; then founder answers to the R11 addendum; the T054 emulator walk is Lane W's — see `Docs/NEXT_GOAL.md`.
**Blocker**: push/merge need founder OK; T001 needs founder OK; Q1–Q11 stay open (spec defaults stand in).

## Position — 2026-10-20 #3 (010 P4 built), main @ `b198795` = origin/main + branch `010-company-network` @ `060fe87` = origin (worktree Goora-010, pushed with founder OK, NOT merged)
P4 T020–T029: Settings → Company account (`/company`, `/company/register`) with every state (register by name + work email + code, pending, HR home with status/domain/minimum/price/contract) · Plan → Through my company shows `offerFor` states (verify first / not on Goora + Tell your HR / join / enrolled since) · consent sheet (sees / never sees, decline = nothing) · `CompanyEnrollment` in `company/presentation/company_controller.dart` calls company enroll/leave + wallet start/endCompanyPlan + notices · Wallet company card "Company · Valeo", paused days, Leave · 5 notice kinds (incl. `personalPlanBack`) · Demo: approve my company, make me Valeo's HR · 55 ARB keys (R11 table in research "P4 notes"); Arabic name = جورة. Bug fixed: Plan screen read a stale plan after joining and never went to Today. Gates: analyze 0 · flutter 1541 · node 276.
**NEXT ACTION**: T030 emulator walk (quickstart 1, 3, 4) or P5 invoices + suspension (T031–T035) — see `Docs/NEXT_GOAL.md`. Merge 010 only with founder OK.
**Blocker**: none (spec defaults stand in for Q1–Q11).

## Position — 2026-10-20 (two parallel rounds merged), main @ `71235d4` = origin/main
Merged: 006 Cairo↔Ismailia corridor P0–P7 (done; walk gaps in research.md T039) · walk fixes S-1..S-6 + nits for 007/008/009 · 010 company network core (T002, P1, P2, P3 seams; T020 half). Gates on main: analyze 0 · flutter 1502 · node 276. Kept open: branch `010-company-network` (worktree Goora-010). Unmerged docs: `docs/walk-007-009`, `spec/company-network`.
**NEXT ACTION**: 010 P4 (register + enroll UI, T022–T030) on 010-company-network; beside it, fix the wallet "covers N trips" caption (round-trip days shown as trips; plural مشوار). Full list → `Docs/NEXT_GOAL.md`.
**Blocker**: none for P4 (spec defaults stand in for founder Q1–Q11).

## Position — 2026-10-19 (defaults confirmed, change 7 brief), main @ `e9079b5` = origin/main + branch `docs/change-7-company-plan-brief` (worktree Goora-change7, docs only, not merged, not pushed)
Founder: all implementer defaults in 007/008/009 stand as built (24 h / 7-day, trial 5 for all, 150 / 30 / 3-day, bundle not covering seat fees, older accounts verified). Change 7 brief written: `Docs/briefs/change-7-company-plan.md`. Finding: company plan does NOT belong in the 006 corridor spec; 006 branch renumbered company network to 007, which main's 007-direct-driver-payment now uses → renumber at 006 merge; brief §5 will conflict (keep both, main wins on trial = 5).
**NEXT ACTION**: founder OK → merge the docs branch; hand the brief to the 006 session. Company-network spec waits until 006 merges.

## Position — 2026-10-06, main @ `2c769dd`
Three features built via speckit, all merged to `main`: 001-foundation-onboarding,
002-commute-matching, 003-daily-commute (one straight line, trivial fast-forward). Remote added
same day (repo had no git identity and no remote — founder supplied the URL;
`git config user.name/email` set **locally per worktree**, never `--global`, each time a fresh
worktree hits "Author identity unknown"). Gate as of `main`: `flutter analyze` 0 issues,
`flutter test` 411 pass, `node --test` (Supabase edge function vectors) 61 pass.

**Device testing set up 2026-10-06:** Android SDK at `C:\Android\Sdk` (adb at
`platform-tools\adb.exe`, not on PATH). Device = Samsung SM_G998U (`R5CNC0NK6ZT`) over USB —
needed Developer options **and** the separate USB-debugging toggle **and** the on-phone "Allow"
prompt before `adb devices` saw it. Install flow: `flutter build apk --debug` then
`adb install -r build/app/outputs/flutter-apk/app-debug.apk` (`flutter install` alone looks for a
release APK and fails) + `adb shell monkey -p app.goora.goora -c android.intent.category.LAUNCHER 1`
to launch. This whole sequence now lives in `goora-stack`'s "Device testing" section.

**Fixes landed this session, each its own branch+worktree, merged to main:**
- `cc9b168` — `weekDriveLine`'s English said "rider(s)" where every other spot
  (`heroDriver`/`tlPassengers`) says "passenger(s)" for the same concept; Arabic was already
  consistent. Standardized on "passenger".
- `e0c4795` — "See other options" on the match result screen only ever *displayed* alternatives
  (spec 002 AC2 as shipped); founder wanted them switchable. Tapping one now swaps it into the
  main slot (card/stats/fee/reasons/join target) and the replaced group reappears in the list.
  Spec amended to match (`specs/002-commute-matching/spec.md` AC2 + FR-013).
- `9ba7819` → superseded by `2c769dd` — "Reset demo data" (Settings) gave zero visible feedback
  unlike every other demo button. First pass added a snackbar; founder then reported the
  **underlying data itself** wasn't resetting (the commute profile/membership/user session were
  never in scope — only daily-commute + trust were). Final fix (`2c769dd`) clears all of it
  (`FakeCommuteRepository.allKeys` added, profile repo cleared, session signed out) and navigates
  to Welcome — a real start-over. Dropped the snackbar; the screen change is the confirmation.

**Checked, not a bug:** the progress-bar fill/track contrast (~2.6:1) is a documented, deliberate
exception in `test/unit/contrast_test.dart` — `GooraProgressBar` always shows its value as text
too (`valueLabel`), so the color-alone rule doesn't apply. Left unchanged.

**T069 (quickstart.md manual device walkthrough) — in progress, founder actively testing on
device.** Debug APK built/installed/relaunched three times this session (once per fix above).
Scenarios not yet all confirmed; founder found the two bugs above while on scenario 1 (rider US1 /
match result + Settings), hasn't reported past that point yet.

## NEXT ACTION
Resume at scenario 1 (rider US1) with the latest APK (`2c769dd`, already installed+launched on
`R5CNC0NK6ZT`) — confirm "See other options" switching and the full Settings reset both read
right, then continue scenarios 2–6 (cancel US2, driver US3, backup+week US4/US5, trust US6,
safety/SOS US7) per `specs/003-daily-commute/quickstart.md`. If all pass → mark T069 done in
`specs/003-daily-commute/tasks.md`. If something's broken → triage as its own branch+worktree.

Separately open, not blocking: copy review of the R14 drafted-copy table + addenda for 001/002
(003's addenda already swept 2026-10-06).

⚠️ **Stale worktree, not cleaned up:** `C:\AhmedGaid\Goora-003` still checks out
`feature/003-daily-commute`, already merged into main — harmless but unused; remove with
`git worktree remove` next time someone's in there, after confirming no uncommitted work.

## BLOCKED — don't re-ask
None currently.

## Rules for this project
- Spec-driven via speckit (`.specify/`, `.specify/memory/constitution.md`, `specs/NNN-*/`). No
  hand-rolled feature code outside that flow.
- Pricing/legal constraint is non-negotiable: riders' total payments must never exceed the full
  trip cost (Constitution II) — flag any change that touches `matching_service.dart` or the
  Supabase `_shared/matching.ts` twin against this.
- Update this file at the end of every completed task (position, NEXT ACTION, blocker) — same
  pattern as `atyab-status`/`dukkan-status`.

## Lane B walk-fix block — 2026-10-20 (007–009 walk fixes), branch `fix/walk-007-009` (worktree Goora-walkfix, off main 453e5bd, NOT pushed, NOT merged)
S-1 driver Withdraw + sheet + keys (`recoveredTitle`, `payoutNote`, `withdraw*`) removed · S-2 fee-free rows say "40 ج للسواق · من غير رسوم خدمة" (`priceNoFee`) · S-3 bundle with trips left → no cash-ended / savings banners, plan card says `planBundleLine`, breakdown shows no fee (fee-owed debt banner kept: real debt) · S-4 plan top-up banner pinned above the CTA · S-5 Trust header says verified only when the ID row does (`memberRating`) · S-6 REPRODUCED on a one-leg driving day (cover takes the return): `drive` moved to the next drive day so the receipt card vanished; fixed with `TodayView.today` · nits N-1,2,3,4,8,9 done. Goldens regenerated (4 wallet PNGs, looked at). Open nits: N-5, N-6, N-7, N-10, N-11, N-12. Gates: analyze 0 · flutter green after golden update · node 226.
**NEXT ACTION**: founder OK → merge (order C, B, A; ARB/status/NEXT_GOAL conflicts: keep both sides). Push needs OK.

## Where detail lives
- Product brief / canon → `GOORA_SPEC_KIT_BRIEF.md` (repo root).
- Architecture, conventions, gates → [[goora-stack]].
- Brand/voice/Arabic lexicon → [[goora-brand]].
- Resume flow → [[goora-resume]].
- Feature specs/plans/tasks → `specs/001-*`, `specs/002-*`, `specs/003-*`.

## Lane C block — 006 P7 (2026-10-20), branch `006-cairo-ismailia-corridor`, not pushed
P7 done: meeting points are named spots with a real 400–600 m walk (no "0 متر", no double التجمع) · six centres map-checked on OpenStreetMap, `// recalled` marks gone · brief roadmap row: company network = 010 · device walk on the emulator (research.md "T039", screenshots in specs/006-…/walk/) found and fixed two 1.3× bugs (match stat "5/أسبوع" clipped; "Departure" broke mid-word). Open: Empty seats empty for member rider; no corridor switch in Settings → Demo; stop landmark names need founder review.
**NEXT ACTION**: founder OK → push 006, merge Lane C first, then B, then A. Details: Docs/NEXT_GOAL.md "LANE C".
