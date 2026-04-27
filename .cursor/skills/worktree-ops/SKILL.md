---
name: worktree-ops
description: "Operational guidance for Cursor's /worktree command. Activates when deciding whether to isolate a task in a dedicated worktree for parallel or risky work."
---

# /worktree — Task Isolation via Worktrees

Guidance for when and how to use Cursor's worktree isolation feature.

## When to use

- Risky refactors that may break the working tree
- Parallel implementations of independent features
- Experimental spikes you want to discard cleanly
- Long-running tasks that shouldn't block the main branch

## How it works

1. `/worktree` creates an isolated git worktree with its own branch
2. Work proceeds independently — no conflicts with main
3. When done, merge or cherry-pick back, then clean up the worktree

## Best practices

- Name worktrees descriptively: `feat/short-description` or `fix/issue-ref`
- Keep worktree lifespan short — merge or discard within a session
- Use `--worktree` flag with `cursor agent` for headless runs
