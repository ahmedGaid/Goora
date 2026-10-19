/goal Goora 006 — branch `006-cairo-ismailia-corridor` (worktree D:/Company/80-Worktrees/Goora-006) now contains main `eda1844` (merge `f5447f6`, 0 commits behind main). P0–P3 done. Gates after the merge: analyze 0 · flutter 1239 + 1 intended red (`corridor_seed_invariant_test`, red until P5) · node 226. Pushed to origin (founder OK, 2026-10-19).
WHERE: verify first — `git -C D:/Company/80-Worktrees/Goora-006 log --oneline -4` · `git rev-list --count 006-cairo-ismailia-corridor..main` · `git -C D:/Company/80-Worktrees/Goora-006 status --short` · `git worktree list`.
NEXT: P4 — replace hard-coded corridor uses with `activeCorridorProvider`, apply the `oldCorridor()` override in the spike files (see tasks.md P4 and research.md P1 spike list). Keep 007–009 payment code paths untouched unless a P4 task names them.
READ FIRST: specs/006-cairo-ismailia-corridor/tasks.md (P3 notes, P4) · research.md (P1 spike, R4–R6) · goora-stack · `goora-status` top entry.
SCOPE: P4 only, one commit per task group. Brief §6.7 now uses main's payment model (direct pay, pay later, trial 5); line D = company network later, unnumbered, price TBD.
FIT: Sonnet. EST: 60–90 min incl. gates.
ALSO OPEN: trip cost 300 EGP unverified placeholder · map check of six recalled centres (T040) · founder review of ar/en area + stop names · trip minutes inside the Cairo side (30) is a guess · company price 75 vs 99 · Obour / 10th of Ramadan real pickups · lawyer answers (brief §8) · device walks for 007/008 screens · brief §5/§7 still say "first 10 trips" / 129 EGP in screen copy (same on main, pre-existing).
BLOCKED, don't re-ask: corridor = Cairo↔Ismailia · areas = New Cairo, Nasr City, Heliopolis, Obour, 10th of Ramadan, Ismailia · company plan is NOT in 006 · push only with the founder's OK · emulator via D:\Company\99-Ops\start-emulator.ps1, never the personal phone.

---
## Lane B — 006 P5 seed (branch `006-p5-seed`, appended 2026-10-19; the block above is Lane A's)
/goal Goora 006 P5 done on `006-p5-seed` (worktree D:/Company/80-Worktrees/Goora-006-p5, cut from 006 tip `2d3de70`). Gates: analyze 0 · flutter 1300 green · node 226. Not pushed.
WHERE: verify — `git -C D:/Company/80-Worktrees/Goora-006-p5 log --oneline -5` · `git rev-list --count 006-p5-seed..006-cairo-ismailia-corridor` (Lane A may be ahead).
NEXT: founder OK → merge `006-p5-seed` into `006-cairo-ismailia-corridor` (Lane A side). Then Lane A wires: `MarketSeed.requests/offers(now, corridor: …)` in the fake marketplace repo; `CairoIsmailiaSeed.groups` into the group catalog when the new corridor is active; fixed 160/3 `MarketSeed.tripCost/riderSeats` (T024).
READ FIRST: specs/006-cairo-ismailia-corridor/tasks.md (P5 T026–T030, P4 T022–T024) · goora-status "Lane B block".
SCOPE: seed data + tests only; Lane A files untouched.
FIT: Sonnet. EST: merge + P4 wiring 60–90 min.
ALSO OPEN: seed names/ratings/vehicles are demo copy (not ar/en strings, no ARB) · detour spread for the 12 requests is derived (see `_cairoRequest`) · 300 EGP still unverified.
BLOCKED, don't re-ask: push/merge only with the founder's OK.
