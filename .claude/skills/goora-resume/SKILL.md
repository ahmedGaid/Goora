---
name: goora-resume
description: Resume work on Goora — the daily-commute coordination Flutter app for Egypt at C:\AhmedGaid\Goora. Use whenever the user wants to continue, pick up, start the next session on, or check the status of Goora, especially in a fresh session or after pasting a /goal block. Checks live git first, reads Docs/NEXT_GOAL.md and the top goora-status entry, proposes ONE task and waits for "go".
---

# goora-resume — session start procedure

Project: Goora, `C:\AhmedGaid\Goora`. Default branch: `main` (remote `origin`, GitHub).
Spec-driven via speckit: `.specify/` + `specs/NNN-*/` (spec · plan · tasks · quickstart).
Status file = **`goora-status`** skill (top "Position" entry only).
Gates (from `goora-stack`): `flutter analyze` (0 issues) · `flutter test --concurrency=1` ·
`node --test "supabase/functions/_shared/*.test.ts"`. UI/copy → also `goora-brand` checklist.

## 1. Git first — git wins over notes
Read-only, in the main checkout:
- `git status --short` · `git branch --show-current`
- `git log --oneline -10 main`
- `git worktree list` (one worktree per in-flight feature, e.g. `Goora-004`)
- `git branch -a --no-merged main`
A note (NEXT_GOAL.md, status skill, tasks.md ticks) that disagrees with git is wrong. Fix it in this
session's hand-off.

## 2. Read the hand-off, then stop reading
1. `Docs/NEXT_GOAL.md` — use `git show main:Docs/NEXT_GOAL.md`. If an unmerged feature branch has a
   newer commit on that file, read that copy instead. Missing → create it from the `goora-status`
   top entry + step 1 facts.
2. Then ONLY the top entry of `goora-status`.
3. Open other files only when the task needs them (the feature's `tasks.md` phase, `goora-stack`,
   `goora-brand`).
Blocker named? It comes first.

## 3. Reply — at most 10 lines, then wait
- Where we are (main sha, last merged feature)
- Unmerged branches (name + one word: done / in progress / stale)
- Next task + one-line scope (which speckit step / task IDs)
- What the founder must do first (merge X, connect a phone, decide Y — or "nothing")
- Best model (Haiku / Sonnet / Opus) + time estimate
Print the `/goal` block for that task, then ask **"Start <task>?"** and wait.

## 4. On "go"
1. Next task continues an unmerged feature branch → work in that feature's existing worktree.
   Otherwise new branch + worktree off `main`: `git worktree add ../Goora-<NNN> -b <NNN>-<name> main`.
   All reads and edits from there. Recall `multi-agent-git` before any git write.
2. Speckit — don't hand-write feature code: `/speckit-specify` → `/speckit-plan` →
   `/speckit-tasks` → `/speckit-analyze` → `/speckit-implement`, one step per session.
3. Recall `goora-stack` (any code) and `goora-brand` (any UI/copy/Arabic wording).
4. Do ONE task (one speckit step, one task phase, one fix). Acceptance criterion honestly met.
5. Gates: `flutter analyze` · `flutter test --concurrency=1` · `node --test "supabase/functions/_shared/*.test.ts"`.
   Manual device walkthroughs (quickstart.md) need a real phone/emulator — none connected → say
   so and pick another open item instead of blocking.
6. Commit (conventional message with feature/task IDs). **Never push without the founder's OK.**
   "Author identity unknown" in a fresh worktree → set `git config user.name`/`user.email`
   locally there, never `--global` without asking.
7. Update the `goora-status` top entry: position, NEXT ACTION, blocker.

## 5. Close — overwrite Docs/NEXT_GOAL.md
Build it from live git (`git log --oneline -12 main`, `git branch --merged main`, `git status`) —
never copy old notes. Overwrite `Docs/NEXT_GOAL.md` with the new `/goal` block (WHERE · NEXT ·
READ FIRST · SCOPE · FIT · ALSO OPEN · BLOCKED; shape → `ag-fable` § Exit ritual), commit it on the
task branch, and print it in the last message with the **How to test** block. Never pin line
numbers, ownership or free ID ranges. Then: clear session, start fresh.
