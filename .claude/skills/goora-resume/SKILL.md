---
name: goora-resume
description: Resume work on Goora — the daily-commute coordination Flutter app for Egypt at C:\AhmedGaid\Goora. Use whenever the user wants to continue, pick up, start the next session on, or check the status of Goora, especially in a fresh session or after pasting a /goal block. Recalls goora-status, checks it against live git, prints the current state, and does ONE task.
---

# goora-resume — resume Goora

1. Recall **`goora-status`** for the live position, NEXT ACTION, and blockers.
2. Recall **`multi-agent-git`** before any git write — pre-flight `git status` /
   `git branch --show-current` / `git worktree list` in `C:\AhmedGaid\Goora` (worktrees may exist
   per in-flight feature, e.g. `Goora-003`).
3. Verify the status file against live state: `git log --oneline -5`, `git status`,
   `git worktree list`. If they disagree, trust git and say so — the status file may be stale.
4. If touching UI/copy/Arabic wording → also recall **`goora-brand`**. If touching app code →
   also recall **`goora-stack`**.
5. Do ONE task (one speckit step, one fix, one review pass — not several), per `ag-fable`'s
   one-task-one-session rule.
6. At close-out: update `goora-status` (position · NEXT ACTION · blocker), commit + push per
   `multi-agent-git`, then give the founder a `/goal` pointer block (`ag-fable` § Exit ritual).

## Notes specific to this project
- No git identity was configured in this repo until 2026-10-06 (set locally, not global — see
  `goora-status`). If a fresh clone/worktree hits "Author identity unknown" on commit, set
  `git config user.name`/`user.email` locally there too, never `--global` without asking.
- Spec-driven via speckit — don't hand-write feature code; follow `/speckit-specify` →
  `/speckit-plan` → `/speckit-tasks` → `/speckit-analyze` → `/speckit-implement`, one step per
  session (same rule as `atyab-resume`).
- Manual device walkthroughs (quickstart.md) need a real phone/emulator — not always available;
  if none is connected, say so and pick another open item instead of blocking.
