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
