/goal Goora 006 — branch `006-cairo-ismailia-corridor` (worktree D:/Company/80-Worktrees/Goora-006) now contains main `eda1844` (merge `f5447f6`, 0 commits behind main). P0–P3 done. Gates after the merge: analyze 0 · flutter 1239 + 1 intended red (`corridor_seed_invariant_test`, red until P5) · node 226. Pushed to origin (founder OK, 2026-10-19).
WHERE: verify first — `git -C D:/Company/80-Worktrees/Goora-006 log --oneline -4` · `git rev-list --count 006-cairo-ismailia-corridor..main` · `git -C D:/Company/80-Worktrees/Goora-006 status --short` · `git worktree list`.
NEXT: P4 — replace hard-coded corridor uses with `activeCorridorProvider`, apply the `oldCorridor()` override in the spike files (see tasks.md P4 and research.md P1 spike list). Keep 007–009 payment code paths untouched unless a P4 task names them.
READ FIRST: specs/006-cairo-ismailia-corridor/tasks.md (P3 notes, P4) · research.md (P1 spike, R4–R6) · goora-stack · `goora-status` top entry.
SCOPE: P4 only, one commit per task group. Brief §6.7 now uses main's payment model (direct pay, pay later, trial 5); line D = company network later, unnumbered, price TBD.
FIT: Sonnet. EST: 60–90 min incl. gates.
ALSO OPEN: trip cost 300 EGP unverified placeholder · map check of six recalled centres (T040) · founder review of ar/en area + stop names · trip minutes inside the Cairo side (30) is a guess · company price 75 vs 99 · Obour / 10th of Ramadan real pickups · lawyer answers (brief §8) · device walks for 007/008 screens · brief §5/§7 still say "first 10 trips" / 129 EGP in screen copy (same on main, pre-existing).
BLOCKED, don't re-ask: corridor = Cairo↔Ismailia · areas = New Cairo, Nasr City, Heliopolis, Obour, 10th of Ramadan, Ismailia · company plan is NOT in 006 · push only with the founder's OK · emulator via D:\Company\99-Ops\start-emulator.ps1, never the personal phone.

---
## LANE A hand-off (006 P4, 2026-10-19) — WIP, stopped at usage limit
/goal Goora LANE A — finish 006 P4 on branch 006-cairo-ismailia-corridor (worktree Goora-006). WIP commit "wip(006): P4 ..." is NOT gated.
DONE (code + tests, not yet full-suite run): T018 `Corridor.legOf` (R5, refined: when neither end is home, only leaving the work end is return) + tests in corridor_test · T019 leg in OfferForm/PostStart · T021 RouteForm `areas` + find_riders reads corridor.areas · T022 defaults from corridor · T020 FakeCommuteRepository `corridor` param · T023 fake marketplace durations via `corridor.tripMinutes` · T024 `tripCostConfig` + marketplace new trips use corridor tripCost.
NEXT: 1) fix 2 red tests in post_trip_test "[ar|en] Cairo ↔ Ismailia home → Ismailia is going…" (cancel → post-again flow; check keys/ensureVisible). 2) run full `flutter test --concurrency=1`; pin `oldCorridor()` in the other spike files (find_riders_test, commute_screens_test, marketplace_navigation_test, commute_flow_test) and any test constructing FakeMarketplaceRepository (now needs `corridor:`). 3) T025 no-match/waitlist copy. 4) tick tasks.md, note the R5 refinement in research.md, gates, goora-status.
FIT: Opus. EST: 1–1.5 h. BLOCKED: push only with founder OK; corridor_seed_invariant_test red on purpose until P5.

## Lane B — 006 P5 seed (branch `006-p5-seed`, appended 2026-10-19; the block above is Lane A's)
/goal Goora 006 P5 done on `006-p5-seed` (worktree D:/Company/80-Worktrees/Goora-006-p5, cut from 006 tip `2d3de70`). Gates: analyze 0 · flutter 1300 green · node 226. Not pushed.
WHERE: verify — `git -C D:/Company/80-Worktrees/Goora-006-p5 log --oneline -5` · `git rev-list --count 006-p5-seed..006-cairo-ismailia-corridor` (Lane A may be ahead).
NEXT: founder OK → merge `006-p5-seed` into `006-cairo-ismailia-corridor` (Lane A side). Then Lane A wires: `MarketSeed.requests/offers(now, corridor: …)` in the fake marketplace repo; `CairoIsmailiaSeed.groups` into the group catalog when the new corridor is active; fixed 160/3 `MarketSeed.tripCost/riderSeats` (T024).
READ FIRST: specs/006-cairo-ismailia-corridor/tasks.md (P5 T026–T030, P4 T022–T024) · goora-status "Lane B block".
SCOPE: seed data + tests only; Lane A files untouched.
FIT: Sonnet. EST: merge + P4 wiring 60–90 min.
ALSO OPEN: seed names/ratings/vehicles are demo copy (not ar/en strings, no ARB) · detour spread for the 12 requests is derived (see `_cairoRequest`) · 300 EGP still unverified.
BLOCKED, don't re-ask: push/merge only with the founder's OK.

## LANE A — 006 P4 + P6 done (appended 2026-10-20; supersedes the "LANE A hand-off" block above)
/goal Goora 006 — branch `006-cairo-ismailia-corridor` @ `189b179` (worktree D:/Company/80-Worktrees/Goora-006), 21 commits ahead of main `eda1844`, 0 behind. Origin is at `2d3de70`: P4/P5-merge/P6 NOT pushed. Gates: analyze 0 · flutter 1360 green · node 226.
WHERE: verify — `git -C D:/Company/80-Worktrees/Goora-006 log --oneline -4` · `git rev-list --count main..006-cairo-ismailia-corridor` · `git -C D:/Company/80-Worktrees/Goora-006 status --short`.
NEXT: founder OK → push 006. Then P7: T039 device walk (quickstart §0–§7, emulator via D:\Company\99-Ops\start-emulator.ps1 once Lane C frees it), T040 map check, T041 SC-006 docs, T042–T043 close.
READ FIRST: specs/006-cairo-ismailia-corridor/tasks.md (P4+P5 notes, P6 notes, P7) · research.md R5 (leg rule refinement + test pin) · goora-status "Lane A block 2026-10-20".
SCOPE: P7 only; no app code unless the walk finds a bug. Merge to main only with the founder's OK; Lane B (010) rebases after 006 merges.
FIT: Sonnet. EST: 60–90 min incl. walk.
ALSO OPEN: founder copy review — "التجمع · … — …، نقطة التجمع" repeats التجمع; seed meeting points sit on the home points ("0 m away") · 300 EGP unverified · six centres recalled (T040) · Cairo-side 30 min guess · `006-p5-seed` branch + worktree Goora-006-p5 are merged here and can be deleted (founder OK).
BLOCKED, don't re-ask: push/merge/delete only with the founder's OK · emulator only via start-emulator.ps1, never the personal phone.

## LANE C — 006 P7 done (appended 2026-10-20; supersedes the P7 line in the LANE A block above)
/goal Goora 006 P7 done on branch `006-cairo-ismailia-corridor` (worktree D:/Company/80-Worktrees/Goora-006), ahead of main `453e5bd`, not pushed. Gates: analyze 0 · flutter green (full run, `--concurrency=1`) · node green · cap sweep 0 over the cap.
WHERE: verify — `git -C D:/Company/80-Worktrees/Goora-006 log --oneline -8` · `git rev-list --count main..006-cairo-ismailia-corridor` · `git -C D:/Company/80-Worktrees/Goora-006 status --short`.
NEXT: founder OK → push, then merge this lane FIRST (round order C → B → A). Then someone looks at the "Open" list in research.md "T039 device walk".
READ FIRST: specs/006-cairo-ismailia-corridor/research.md ("P7 — Lane C": map check, meeting-spot decision, device-walk table + open list) · walk/ screenshots.
SCOPE: done = copy/seed fixes (named meeting spots, no "0 متر", no double التجمع) · T040 six centres from OSM · T041 brief row says company network is 010 · two 1.3× bugs fixed (stat clip, "Departure" wrap). Device walk §4 partly, §6 impossible (no corridor switch in Settings → Demo).
FIT: Sonnet for the open items; Empty-seats-empty for a member rider may need Opus-level reading of marketplace seed vs filter.
ALSO OPEN: Empty seats empty for a member rider on New Cairo ↔ Ismailia (unexplained; Lane B files) · no corridor switch in Settings → Demo (Lane A files) · Today's return-leg arrival shows area name only · "461 دقيقة" pickup wording (daily/**) · stop landmark names (90th Street, City Stars, Korba Sq., Obour Market, 1st District, El Mamar Sq.) are recalled, founder review · trip cost 300 EGP · Obour / 10th of Ramadan real pickups · SC-001 (< 2 min) not proven by the scripted walk · 002 specs still say "launch corridor" for the old route (historical, left).
BLOCKED, don't re-ask: push/merge only with the founder's OK · emulator via D:\Company\99-Ops\start-emulator.ps1, never the personal phone.
---
## LANE B walk-fix hand-off (2026-10-20)
/goal Goora — branch `fix/walk-007-009` (worktree D:/Company/80-Worktrees/Goora-walkfix) off main 453e5bd: S-1…S-6 + N-1,2,3,4,8,9 fixed, tests ar+en. Gates: analyze 0 · flutter green · node 226. Not pushed.
WHERE: verify — `git -C D:/Company/80-Worktrees/Goora-walkfix log --oneline -8` · `git status --short`.
NEXT: founder OK → merge in round order C, then this, then Lane A (keep both sides in ARB/goora-status/NEXT_GOAL). Then remaining nits N-5, N-6, N-7, N-10, N-11, N-12.
READ FIRST: Docs/walks/2026-10-20-007-009.md §5 (on docs/walk-007-009) · goora-status "Lane B walk-fix block".
SCOPE: nits only, wallet/daily/marketplace presentation + existing ARB keys.
FIT: Sonnet. EST: 1–2 h.
ALSO OPEN: S-6 repro was a constructed one-leg day, not the exact Mon 30/11 device state (test uses the old corridor) · wallet_controller.withdraw + repo withdraw now unused (Lane A owns them) · legacy 004 driver balance no longer shown anywhere · new keys `priceNoFee`, `planBundleLine`, `memberRating`, `instapaySaved` sit mid-file.
BLOCKED, don't re-ask: push/merge only with the founder's OK.
/goal Goora — main @ e9079b5 = origin/main (007 direct driver pay, 008 pay later + bundle, 009 rider ID before first trip, all merged). Founder 2026-10-19: every 007/008/009 implementer default stands as built. Change 7 (company plan) brief written on branch `docs/change-7-company-plan-brief` (worktree Goora-change7, docs only, not merged, not pushed). Branch `006-cairo-ismailia-corridor` / Goora-006 belongs to another session; don't touch.
WHERE: verify first — `git log --oneline -12 main` · `git branch --no-merged main` · `git worktree list` · `git status --short`.
NEXT: founder OK → merge `docs/change-7-company-plan-brief` into main (`--no-ff`), push, delete branch + worktree. Then paste the brief's TL;DR to the 006 session: no company plan in the 006 spec; renumber company network (007 is taken) to the next free number; keep both sides on brief §5 at 006 merge. Company-network spec (`/speckit-specify`) only after 006 merges.
READ FIRST: `Docs/briefs/change-7-company-plan.md` · `goora-status` top entry · `GOORA_PROFIT_CHANGES.md` §7, §10.3 (untracked, main checkout).
SCOPE: docs only this step. Rider-side company plan already exists (`PlanType.company`, work-email verify sheet, fee-free via `direct_pay`). Missing: company sign-up, roster, invoice, leaving rule, aggregated dashboard, HR statement + consent.
FIT: Haiku for the merge; Opus for the company-network spec + clarify.
ALSO OPEN (founder): company price (brief 75 vs model 99) · bill enrolled vs active · minimum seats (20?) · contract length (annual?) · one-off seats covered? · HR statement v1 or later · driver abuse of "ماستلمتش" · lawyer answers (CBE licence, Law 87/2018 fee, pay-later balance) · real InstaPay/Fawry/wallet/card providers · existing subscribers 129/1,290 until renewal (30-day notice job not built) · device walks for 007/008 screens not done.
BLOCKED, don't re-ask: push only with the founder's OK · emulator only, booted via `D:\Company\99-Ops\start-emulator.ps1` (adb at `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`).

---
## Lane C — company network spec (010), 2026-10-19
/goal Goora LANE C done: specs/010-company-network (spec, clarify, plan, research, data-model, contracts, quickstart, tasks T001–T054, analyzed) on branch `spec/company-network` (worktree D:/Company/80-Worktrees/Goora-company), docs only, NOT pushed, NOT merged.
WHERE: verify — `git log --oneline -8 spec/company-network` · `git worktree list`.
NEXT: founder answers Q1–Q11 (table at the top of specs/010-company-network/spec.md); then founder OK → push branch / merge docs. Implementation (P1 coverage spike first) only after 006 merges.
READ FIRST: specs/010-company-network/spec.md "Open founder questions" · research.md R0 (lawyer), R2 (coverage risk) · tasks.md analyze note.
SCOPE: implementation branch `010-company-network` off main after 006; P1–P2 Opus, P3–P9 Sonnet, one phase per session.
FIT: Opus for P1 + P2. EST: P1 ~60–90 min.
ALSO OPEN: Q1 price 99 vs 75 · Q2 enrolled peak/day · Q3 minimum 20 · Q4 annual · Q5 one-off seats covered · Q6 HR statement P3 · Q7 disputed shares excluded · Q8 lawyer/ETA/VAT/PDPL · Q9 in-app HR area · Q10 due+15, grace 7 · Q11 pause sub, no trial after leaving. Goora bank details for invoices.
BLOCKED, don't re-ask: implementation waits for 006 merge · push only with founder OK · brief/constitution amend (T001) needs founder OK.

---
## Lane B — 010 company network core (new files only), 2026-10-20
/goal Goora LANE B done: 010 T002 + P2 (T008–T012) + P3 (T013–T016) on branch `010-company-network` (worktree D:/Company/80-Worktrees/Goora-010, cut from `spec/company-network` @ 7c15d40), 3 code commits, NOT pushed, NOT merged. Gates on the branch: analyze 0 · flutter 1305 (was 1208, +97 company tests) · node 264 (was 214, +50).
WHERE: verify — `git log --oneline spec/company-network..010-company-network` · `git diff --name-only spec/company-network...010-company-network` (new files + tasks.md/research.md/NEXT_GOAL.md only).
NEXT: after 006 merges into main → rebase `010-company-network` onto main (new files, so only tasks.md/research.md/NEXT_GOAL.md can conflict: keep both), re-run gates, then P1 T003–T007 (coverage windows on `Plan`, `PricingMode.of(now)`, marketplace booking on `coversTrip`) — riskiest, Opus. Then T017–T021 seams.
READ FIRST: specs/010-company-network/research.md "Lane B notes" (defaults table, 15 choices, what waits for 006) · tasks.md (ticks + "waits for 006 merge" notes) · contracts/repositories-and-navigation.md § Seams.
SCOPE: P1 + seams edit existing wallet/marketplace/trust/notice/settings files — only after 006 is in main. Could run now, new files only: P7 domain half T041–T043 (`company_dashboard.dart` aggregator + tests; needs a citable CO₂ factor and the SZ ↔ SV km first, R7).
FIT: Opus for P1. EST: 60–90 min. Sonnet for T017–T021 and for T041–T043.
ALSO OPEN (founder): Q1–Q11 (spec top table; code uses each default, all numbers in `CompanyTerms`/`CompanyRules`) · seed 12 vs 24 employees (12 chosen, R10/F3) · Goora bank details for invoices (`CompanyTerms.bankDetails` placeholder) · push this branch?
BLOCKED, don't re-ask: no edits to existing files until 006 merges · push only with founder OK · T001 brief/constitution amend needs founder OK · lawyer answers R0 (flags stay off).

---
## Lane A — 010 P1 + P3 seams, 2026-10-20 #2 (rebased on main 453e5bd)
/goal Goora LANE A done: 010 P1 (T003–T007) + P3 seams (T017–T019, T021; T020 copy only) on `010-company-network` @ `3c3a1fe` (worktree D:/Company/80-Worktrees/Goora-010, rebased onto main 453e5bd, NOT pushed, NOT merged). Gates: analyze 0 · flutter 1484 (+27 on the 1457 baseline) · node 276.
WHERE: verify — `git -C D:/Company/80-Worktrees/Goora-010 log --oneline main..010-company-network` · `git worktree list`.
NEXT: round end (merge order C → B → A): rebase `010-company-network` onto the new main, keep both on ARB, re-run `flutter gen-l10n` (never hand-merge generated l10n), gates; founder OK → push/merge. Then P4 (T022–T030): finish T020 (4 `NoticeKind` values + arms in `daily/presentation/labels.dart` + posts), wire who calls `startCompanyPlan`/`endCompanyPlan` (research "Lane A notes" #6), routes, screens, `rider_wallet.dart` company card.
READ FIRST: specs/010-company-network/research.md R2 "P1 spike result" + "Lane A notes" · tasks.md P3 notes, P4 · contracts/repositories-and-navigation.md § Seams · goora-stack.
SCOPE: P4 edits Lane B's files of this round (wallet presentation, daily presentation) — only after Lane B merges.
FIT: Sonnet + goora-brand for P4 (Opus if the start/end wiring choice is reopened). EST: 2–3 h.
ALSO OPEN (founder): Q1–Q11 (spec top table; defaults in `CompanyTerms`/`CompanyRules`) · R11 copy review (5 new notice keys) · T001 brief/constitution needs OK.
BLOCKED, don't re-ask: push/merge only with the founder's OK · emulator only via start-emulator.ps1 · router pay-method guard still day-level (`coversDate`, not this lane's file).
