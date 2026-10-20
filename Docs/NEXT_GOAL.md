/goal Goora — main @ e9079b5 = origin/main (007 direct driver pay, 008 pay later + bundle, 009 rider ID before first trip, all merged). Founder 2026-10-19: every 007/008/009 implementer default stands as built. Change 7 (company plan) brief written on branch `docs/change-7-company-plan-brief` (worktree Goora-change7, docs only, not merged, not pushed). Branch `006-cairo-ismailia-corridor` / Goora-006 belongs to another session; don't touch.
WHERE: verify first — `git log --oneline -12 main` · `git branch --no-merged main` · `git worktree list` · `git status --short`.
NEXT: founder OK → merge `docs/change-7-company-plan-brief` into main (`--no-ff`), push, delete branch + worktree. Then paste the brief's TL;DR to the 006 session: no company plan in the 006 spec; renumber company network (007 is taken) to the next free number; keep both sides on brief §5 at 006 merge. Company-network spec (`/speckit-specify`) only after 006 merges.
READ FIRST: `Docs/briefs/change-7-company-plan.md` · `goora-status` top entry · `GOORA_PROFIT_CHANGES.md` §7, §10.3 (untracked, main checkout).
SCOPE: docs only this step. Rider-side company plan already exists (`PlanType.company`, work-email verify sheet, fee-free via `direct_pay`). Missing: company sign-up, roster, invoice, leaving rule, aggregated dashboard, HR statement + consent.
FIT: Haiku for the merge; Opus for the company-network spec + clarify.
ALSO OPEN (founder): company price (brief 75 vs model 99) · bill enrolled vs active · minimum seats (20?) · contract length (annual?) · one-off seats covered? · HR statement v1 or later · driver abuse of "ماستلمتش" · lawyer answers (CBE licence, Law 87/2018 fee, pay-later balance) · real InstaPay/Fawry/wallet/card providers · existing subscribers 129/1,290 until renewal (30-day notice job not built) · device walks for 007/008 screens not done.
BLOCKED, don't re-ask: push only with the founder's OK · emulator only, booted via `D:\Company\99-Ops\start-emulator.ps1` (adb at `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`).

---

## Lane C block — device walk 007/008/009 (2026-10-20, branch `docs/walk-007-009`, docs only)
/goal Goora — walk done, findings only: `Docs/walks/2026-10-20-007-009.md` + 71 PNGs in `Docs/walks/2026-10-20/`. 0 blocker · 6 should-fix · 12 nits. `flutter analyze` on main = 0 issues.
WHERE: branch `docs/walk-007-009` off main `eda1844`, committed, NOT pushed, NOT merged. Worktree `D:/Company/80-Worktrees/Goora-walk`. Verify first: `git log --oneline -3 docs/walk-007-009`.
NEXT: founder reads the report §5 and picks which should-fix go to a fix lane (one branch each, test first): S-1 driver "Withdraw to InstaPay" button · S-2 subscriber row omits "40 ج للسواق" (`labels.dart:60`) · S-3 bundle active but "each trip has a fee" banners · S-4 Subscribe top-up banner below the fold · S-5 Trust header "verified" over ID "not verified" · S-6 repro the Mon 30/11 missing cash card (may be nothing).
READ FIRST: `Docs/walks/2026-10-20-007-009.md` §2 (how it was walked, what was injected) and §5.
SCOPE: fixes touch `lib/**`, ARB (both files), `test/**` — a different lane from this one. Two quickstart gaps worth a docs tweak: no demo "+24 h / +N trips" control; signed-in user can't be the unpaid rider.
FIT: Sonnet per fix (S-1/S-2/S-3/S-5 small); Opus only if S-6 turns out real.
ALSO OPEN: Book-on-a-seat never walked (seed has no seats on this route) · driver side of the dispute · ID "pending" state · Arabic of the rider debt banner · English of match / pay-method / bundle.
BLOCKED, don't re-ask: push only with the founder's OK · emulator only via `D:\Company\99-Ops\start-emulator.ps1`. The emulator is still booted with the app installed (`emulator-5554`); font scale reset to 1.0.
