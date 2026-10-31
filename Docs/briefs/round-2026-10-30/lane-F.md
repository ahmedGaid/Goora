/goal Goora — Lane F: fix the 010 walk-6 findings (F-W1 consent bug first), the once-driver landing, and tick T049/T054. Autonomous: you will NOT be asked anything and must NOT ask — pick the defensible option, write it in specs/010-company-network/research.md under a new "Walk 6 fixes" section with the rejected alternative, continue.

RULES (hold even if no skill loads):
- Recall first: goora-resume (live git), goora-stack, goora-brand, ag-ui-standard, multi-agent-git. Fit: Sonnet. Est: 3–4 h.
- Other sessions share this repo (4 lanes this round: F, 011, M, L). One session = one task = one branch = one worktree. Pre-flight: git status / branch --show-current / worktree list / stash list. Never `git add .` — exact paths, `git diff --cached --name-only` before each commit. Never revert/reset/clean or `dart format` files you did not edit.
- Branch + worktree BEFORE the first edit: in D:\Company\10-Products\Goora `git fetch --all --prune && git pull --ff-only`, confirm main ≥ b19efec, then `git worktree add D:/Company/80-Worktrees/Goora-laneF -b fix/010-walk6 main`.
- Tests first, confirmed failing, one commit per finding. Commit + push your branch after each. Never merge/push main — the conductor (session "managere") does. When managere says "merge main", run `git merge main` (additive ARB conflicts keep BOTH sides).
- Copy: goora-brand checklist, Egyptian colloquial, 1.3× text, 44 px targets. New ARB keys only at the END of app_ar.arb / app_en.arb. No secrets in the repo. Flags companyInvoicesLive / hrStatementExport stay OFF. One emulator per session.
- End: append your own dated block to the top of the goora-status skill (never rewrite others'), then SendMessage managere "Lane F done" with gates, goldens changed, files touched.

EVIDENCE: specs/010-company-network/walk6/REPORT.md (findings F-W1..F-W6 + PNGs).
FIX, in this order:
1. F-W1 (should-fix, privacy): Plan sheet "Through my company" row puts the rider on the company plan AT ONCE ("free · your company pays"), with no consent sheet and no enrollment, replacing a paid Monthly (also walk-4 N-1; PNGs q4-via-company-ar / -after-ar). It must go through the same path as Settings → Company account: verify work email → offer → consent sheet → enroll (CompanyEnrollment in company/presentation/company_controller.dart). Decline = nothing changes. A paid Monthly is not silently replaced — choose and log the rule (e.g. company plan starts, personal plan pauses per 010 pausedPlan). Tests: no company plan without consent; decline keeps the old plan.
2. Once DRIVER lands on Offer a trip with no tab bar (the same bug N-11 fixed for riders; see onboarding_flow.dart + lib/app/router.dart in the Lane W merge) → land in the shell; Back never reaches onboarding.
3. F-W3: HR share switch row — tapping the label must toggle too (whole row, 44 px).
4. F-W4 (demo): Settings → Reset demo data must reset the demo clock too.
5. F-W5: plan sheet copy uses رحلة and mixes جنيه with ج → مشوار and ج, per goora-brand (planFuelNote is on the known debt list — fix it here).
6. F-W6: HR screens print numeric d/m/yyyy in English too → use the shortDateYear/day+month-name pattern Lane W introduced. N-14: the English bank placeholder inside the Arabic invoice → an Arabic placeholder ("بيانات الحساب البنكي هتوصلك قريب" or better per goora-brand), still flagged as a placeholder in research.
7. Tick T049 and the walk part of T054 in specs/010-company-network/tasks.md (walk 6 = evidence).
DO NOT FIX: F-W2 "الشركة بتستلم كشف … أول كل شهر" (waits for the lawyer, Q8 b) — leave it, note it is still open.

OWNS: lib/features/company/** · lib/features/wallet/presentation/** (plan sheet, company card) · lib/features/onboarding/domain/onboarding_flow.dart · lib/app/router.dart · lib/app/routes.dart · the marketplace offer screen's shell wiring · lib/features/settings/presentation/demo_section.dart (demo reset) · specs/010-company-network/{tasks.md,research.md} · their tests and goldens · new ARB keys at the end.
MUST NOT TOUCH:
- Lane 011 (real backend, branch 011-real-backend): pubspec.yaml/.lock · lib/core/config/env.dart · lib/core/backend/** · any lib/features/*/data/ file (providers wiring, supabase_*.dart) · supabase/** · test/contract/**.
- Lane M (OSM map, branch feat/osm-map): lib/core/map/** · lib/core/widgets/goora_pickup_map.dart · lib/features/commute/presentation/match_result_screen.dart · lib/features/daily/presentation/today/{rider_today,driver_today}.dart.
- Lane L (launch prep, branch chore/launch-prep): android/** · ios/** · .github/** · flutter_launcher_icons.yaml · flutter_native_splash.yaml · Docs/release/**.
- Docs/NEXT_GOAL.md (conductor writes it). Domain rules + Dart↔TS twins: unchanged.

DONE = F-W1, the once-driver landing, F-W3..F-W6 + N-14 fixed with tests · T049/T054 ticked · research "Walk 6 fixes" written · goldens regenerated only where changed (say which) · gates in your worktree: `flutter analyze` 0 · `flutter test --concurrency=1` green (≥ 1769) · `node --test "supabase/functions/_shared/*.test.ts"` green (276) · goora-status block · branch pushed · "Lane F done" sent to managere.
READ FIRST: walk6/REPORT.md · research.md "P8 notes" + R9 (consent) · company_controller.dart · goora-brand lexicon.
BLOCKED, don't re-ask: flags companyInvoicesLive / hrStatementExport stay OFF · lawyer copy (F-W2) · Goora bank details (founder).
