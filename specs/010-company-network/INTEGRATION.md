# 010 integration dry-run

Branch `integ/merge-check` (worktree `D:/Company/80-Worktrees/Goora-integ`), cut from main `b198795`.
Local only. Nothing pushed, main untouched. Run: 2026-10-29.

## Order merged
1. `fix/wallet-caption-demo-corridor` (19c155b) — clean.
2. `010-demo-corridor-tests` (5b8b018) — 1 conflict.
3. `010-company-network` (first at 2de6802, again at 35ff080/a1bc256 after the other lane moved) — 1 conflict, first time only.

## Conflicts and how they were resolved
| File | Cause | Resolution |
|---|---|---|
| `lib/features/settings/presentation/demo_section.dart` | Wallet-fix branch added the `demo-corridor` button; demo-tests branch added six company demo buttons in the same list | Kept BOTH. Only one corridor switch exists (key `demo-corridor`), so there was no duplicate to drop and no ARB keys to remove. |
| `specs/010-company-network/research.md` | Both sides appended notes at the same spot | Kept both sections. |
ARB, `app_localizations*`, routes, router: auto-merged, no conflicts. `flutter gen-l10n` left no diff.

## Gates on the merged tree
- `flutter analyze`: 0 issues (the one unused-import warning seen on the first merge was fixed upstream by 35ff080).
- `node --test "supabase/functions/_shared/*.test.ts"`: 276 pass, 0 fail.
- `flutter test --concurrency=1`: see the result line at the bottom of this file.

## Checks done
- **R11 vs ARB** (scripted): every `company*` key in `app_ar.arb` (132, same in en) is in research.md R11, and no R11 key is missing from the ARB. Four early-draft rows named keys that were later renamed (`companyConsentSees`, `companyConsentNever`, `companyPlanPaused`); they now point to `consentSeesTitle`, `consentNeverTitle`, `nCompanyPlanPaused`. 156 keys are new vs main; the only ones not in R11 are `demoCorridor` (wallet-fix branch, not 010).
- **Copy scan** (read-only, 161 new or changed ar keys): no رحلة/سائق/مقعد/جنيه, no Arabic-Indic digits. One taste item for the copy owner: `companyStatementFee` prints `{amount}` with no "ج". Not changed.
- Not done here (handed to goora-5b by the manager): copy fixes, a11y/RTL sweep, N-15 tests, README accuracy re-read.
- No device walk (emulator is shared).

## Commands for the founder
```
cd D:/Company/10-Products/Goora
git merge --no-ff integ/merge-check -m "merge: 010 company network + wallet caption + demo corridor"
flutter gen-l10n && flutter analyze && flutter test --concurrency=1 && node --test "supabase/functions/_shared/*.test.ts"
```
