/goal Goora — main 4e7eced (walk-3 + F22 merged, NOT pushed; origin/main e7046ea). Branch `fix/005-f20-cash-button` (worktree Goora-005-f20) has F20 committed, not merged, not pushed. Gates: analyze 0 · flutter 1089 · node 148. Another session has `006-cairo-ismailia-corridor` (worktree Goora-006) — don't touch it.
WHERE: verify first — `git log --oneline -12 main` · `git branch --no-merged main` · `git worktree list` · `git status --short`.
NEXT: founder OK → merge `fix/005-f20-cash-button` (`--no-ff`; NEXT_GOAL + research.md conflicts: keep both research sections), re-run gates, push main. Then clean up merged worktrees Goora-005-f22 / Goora-005-walk3 / Goora-005-f20 (needs OK). Then walk F20 on the emulator (en driver, cash after drop-off).
READ FIRST: goora-status top entry · specs/005-seat-marketplace/research.md "T104 F20".
SCOPE: merge + push + cleanup only. No F1/F14/F15/F21/F23.
FIT: Sonnet. EST: ~20 min.
ALSO OPEN: F21 (driver on no-match gets "Post your trip" — changes FR-002) · F23 (demo clock without a group) · stale `.g.dart` hashes on main (router / empty_seats / one_off_section / wallet) · F1 · F14 · F15/T078 · "first month free" copy · trip = leg vs day · legal per-trip fee · 005 ARB copy review (incl. `seatReclaimedCash`, `seeYourRequest`).
BLOCKED, don't re-ask: push only with the founder's OK · emulator only, booted via `D:\Company\99-Ops\start-emulator.ps1`.
