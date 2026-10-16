/goal Goora — main = origin/main after merging walk-3, F22 and F20 (`fix/005-f20-cash-button`: driver cash buttons stack full-width). Gates on the merged tree: analyze 0 · flutter 1089 · node 148. Another session has `006-cairo-ismailia-corridor` (worktree Goora-006) — don't touch it.
WHERE: verify first — `git log --oneline -12 main` · `git branch --no-merged main` · `git worktree list` · `git status --short`.
NEXT: (1) walk F20 on the emulator — English driver, cash after drop-off, both group trip and one-off trip: full "Received 40 EGP cash" label, Arabic unchanged. (2) with founder OK, delete merged branches + worktrees Goora-005-walk3 / Goora-005-f22 / Goora-005-f20 (check no process runs from them first). Then the next open item the founder picks.
READ FIRST: goora-status top entry · specs/005-seat-marketplace/research.md "T104 F20" and "T104 — leftovers walk".
SCOPE: walk + cleanup only. No F1/F14/F15/F21/F23.
FIT: Sonnet. EST: 20–30 min.
ALSO OPEN: F21 (driver on no-match gets "Post your trip" — changes FR-002) · F23 (demo clock without a group) · stale `.g.dart` hashes on main (build_runner rewrites router / empty_seats / one_off_section / wallet) · F1 · F14 · F15/T078 · "first month free" copy · trip = leg vs day · legal per-trip fee · 005 ARB copy review (incl. `seatReclaimedCash`, `seeYourRequest`).
BLOCKED, don't re-ask: push only with the founder's OK · emulator only, booted via `D:\Company\99-Ops\start-emulator.ps1`.
