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
