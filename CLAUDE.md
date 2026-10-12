# Goora — working agreement

Daily-commute coordination Flutter app for Egypt — Arabic-first (Egyptian colloquial) / RTL.
Cost-sharing only, never a taxi. Spec-driven via speckit (`.specify/` + `specs/NNN-*/`).

This file is deliberately short. The real rules live in **skills** — recall them; don't reinvent.

## Recall the right skill BEFORE you act
- **Resuming / status / "where are we" / next session** → **`goora-resume`**
  (it reads `Docs/NEXT_GOAL.md` and the top **`goora-status`** entry).
- **Building/editing/reviewing ANY code** → **`goora-stack`** (layers, Riverpod, gates).
- **Any UI / copy / Arabic wording / RTL** → **`goora-brand`**.

## Before you say "done"
`flutter analyze` 0 issues · `flutter test --concurrency=1` green ·
`node --test "supabase/functions/_shared/*.test.ts"` green · (UI work) the `goora-brand` checklist.
Then update **`goora-status`**, commit (push only with the founder's OK), report with a
**How to test** block, and tell the user: clear session, start fresh.

## Session hand-off (always)
- At the START of every session: read Docs/NEXT_GOAL.md and continue from it.
- At the END of every session: write the /goal block for the next session to Docs/NEXT_GOAL.md (overwrite it), commit it, and also print it in your last message. It must include: WHERE we are, NEXT task, READ FIRST, SCOPE, FIT (model), ALSO OPEN, BLOCKED.
- Build every hand-off from live git (`git log --oneline -12 main`, `git branch --merged main`, `git status`) — never copy status from old notes or status skills.
