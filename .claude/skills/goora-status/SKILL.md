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

## Position — 2026-10-06
Three features built via speckit, all merged to `main` (`cc9b168`): 001-foundation-onboarding,
002-commute-matching, 003-daily-commute. History is one straight line (001→002→003, no branching),
so the merge was a trivial fast-forward. Remote added same day (repo previously had no git
identity and no remote — founder supplied the URL). `flutter analyze` 0 issues, `flutter test` 409
pass, `node --test` (Supabase edge function vectors) 61 pass, `/speckit-converge` clean.

**Fix landed 2026-10-06 (`cc9b168`):** `weekDriveLine`'s English copy said "rider(s)" while the
same concept (driver's passenger count on a leg) says "passenger(s)" everywhere else
(`heroDriver`, `tlPassengers`). Arabic (راكب) was already consistent; only English drifted.
Standardized on "passenger".

**Checked, not a bug:** the progress-bar fill/track contrast (~2.6:1) looked low but is a
documented, deliberate exception in `test/unit/contrast_test.dart` — `GooraProgressBar` always
shows its value as text too (`valueLabel`), so the WCAG color-alone rule doesn't apply to the fill.
Left unchanged.

**T069 (quickstart.md manual device walkthrough) — in progress 2026-10-06.** Debug APK built and
installed on a connected Android device (Samsung SM_G998U, `R5CNC0NK6ZT`) via
`flutter build apk --debug` + `adb install`; app launched (`app.goora.goora`). Founder is walking
the 6 quickstart.md scenarios (rider US1, cancel US2, driver US3, backup+week US4/US5, trust US6,
safety/SOS US7) by hand. Outcome not yet reported back.

## NEXT ACTION
Wait for founder's device-walkthrough results (T069). If all 6 scenarios pass → mark T069 done in
`specs/003-daily-commute/tasks.md`, nothing else queued for lane 003. If something's broken →
triage as its own fix (new branch/worktree per `multi-agent-git`).

Separately open, not blocking: copy review of the R14 drafted-copy table + addenda for 001/002
(003's addenda already swept 2026-10-06 — only the one `weekDriveLine` finding).

## BLOCKED — don't re-ask
None currently (repo URL was the only blocker; founder supplied it 2026-10-06).

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
