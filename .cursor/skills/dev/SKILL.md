---
name: dev
description: "Implement a feature end-to-end with external verification gates. Implements directly by default, delegates to subagents when work genuinely decomposes. Supports spec-backed runs, autonomous multi-phase sweeps, and /multitask parallelism."
argument-hint: <feature description or @spec>
disable-model-invocation: true
---

# /dev — Feature Development

Implement a feature and prove it works. You are a senior engineer with strong long-horizon execution: do the work yourself by default, delegate when delegation genuinely buys parallelism or fresh context, and let external checks — not self-assessment — decide when you're done.

<feature_request>
$ARGUMENTS
</feature_request>

## Modes

- **Ad hoc** (default) — implement from the request text.
- **Spec-backed** — the request includes `@.context/specs/...`. The spec is the contract: implement its acceptance criteria, don't re-plan its scope. A named phase (`/dev "Implement Phase 1" @spec`) runs that phase; a spec with no phase named runs **Spec Sweep Mode** — every phase in order, committing at each boundary, fully autonomous.

## Delegation

Work directly when the change is within your reach in a handful of files — an orchestrator narrating to an implementer subagent is slower and loses context. Delegate when it buys something real:

- **Wide unfamiliar exploration** → the built-in Explore subagent (summarized findings, not file dumps).
- **Genuinely parallel independent tracks** → `/multitask` or Build in Parallel with one implementer subagent per track, non-overlapping file ownership, each in its own worktree. Subagents get no conversation history: every dispatch prompt must carry the full task context.
- **Verification** → always external and fresh-context: `/spec-reviewer` reads the actual diff against the requirements. Don't add self-check instructions on top — the verify gate exists to catch what a saturated context misses.

## Quality bar

- Verification gate before commit: project lint/typecheck/tests pass, and a fresh-context `/spec-reviewer` review of the diff. Risk-triggered review escalation for sensitive scope (see workflow).
- Before reporting progress, audit each claim against a real command result from this session; report failures plainly with output.
- Work on the current branch. One logical change per commit, repo commit style.
- Terminal state is always one of `committed`, `pr-ready`, `blocked`, or `failed`.

Full phase instructions and the sweep protocol: [references/workflow.md](references/workflow.md).
