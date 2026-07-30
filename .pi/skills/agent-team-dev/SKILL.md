---
name: agent-team-dev
description: Run the Agent Team dev workflow in pi for this repo. Use when implementing a validated feature or spec-backed phase end-to-end with an external verify gate and a committed, pr-ready, blocked, or failed handoff.
disable-model-invocation: true
---

# Agent Team Dev

Run the Agent Team `/dev` workflow from pi. This wrapper is a pointer plus pi-runtime translation — not an independent workflow implementation. When it disagrees with the source of truth, the source wins.

## Source of truth

- `.claude/skills/dev/SKILL.md`
- `.claude/skills/dev/references/workflow.md`

Read those files before building. (`.cursor/` is a separate runtime adaptation, not a source for pi.)

## pi runtime translation

pi is single-agent, so the source's delegation options collapse to direct work — which is already the source's default posture:

- **Build directly.** Subagent delegation (parallel implementers, Explore agents) doesn't exist on pi; do that work inline, sequentially.
- **Verify gate stays external**: run the project's real lint/typecheck/test commands, then do a deliberate separate review pass over the actual diff against the requirements (coverage first — list every finding with severity, then fix what's real). For risk-triggered scope (auth, data, migrations, public contracts, new dependencies), review in multiple sequential lenses — correctness, security, architecture, tests — instead of the source's parallel council.
- **Spec-backed mode**: the spec is the contract; don't re-plan scope. A named phase builds that phase. A spec path with no phase named is a **sweep**: explore + clarify once, then work phases in dependency order, committing at every phase boundary, halting on a blocked phase or high-risk escalation. pi has no TaskCreate — track the sweep as an ordered checklist in your working notes or the spec file; native compaction handles long sweeps.
- `/goal` and `/loop` are Claude Code features; a spec's Goal Condition blocks are portable text, not executable here.

## Preflight

- Check `git status --short`; note pre-existing dirty files and preserve them.
- `.claude/.logs/hooks.log` is generated noise — restore or ignore unless asked.

## High-risk assumptions

Stop and ask before changing behavior involving product scope, auth, user data, migrations or destructive operations, billing, external side effects, public API contracts, or deployment.

## Repo validation (when the change touches workflow config)

```bash
./tests/workflow-contract.sh
./tests/codex-workflow-contract.sh
bash -n tests/*.sh scripts/*.sh .claude/hooks/*.sh .cursor/hooks/*.sh plugins/agent-team/hooks/*.sh
git diff --check
```

When plugin behavior changes: `COMMAND_TIMEOUT_SECONDS=60 ./tests/smoke.sh`

## Completion response

```markdown
DEV complete
Terminal state: [committed / pr-ready / blocked / failed]
Spec: [.context/specs/... or none]
Verification: [commands + status]
Wrapup: [lessons and follow-ups captured]
```
