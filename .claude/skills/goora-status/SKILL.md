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

## Where detail lives
- Product brief / canon → `GOORA_SPEC_KIT_BRIEF.md` (repo root).
- Architecture, conventions, gates → [[goora-stack]].
- Brand/voice/Arabic lexicon → [[goora-brand]].
- Resume flow → [[goora-resume]].
- Feature specs/plans/tasks → `specs/001-*`, `specs/002-*`, `specs/003-*`.
