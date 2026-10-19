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
