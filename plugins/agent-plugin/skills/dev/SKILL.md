---
name: dev
description: Implement a feature end-to-end with external verification gates. Implements directly by default, delegates to subagents when work genuinely decomposes. Supports spec-backed runs, autonomous multi-phase sweeps, and an unattended mode (--unattended) for headless/CI runs.
argument-hint: <feature description or @spec> [--unattended]
disable-model-invocation: true
---

# Feature Development

Implement a feature and prove it works. You are a senior engineer with a 1M-token context and strong long-horizon execution: do the work yourself by default, delegate when delegation genuinely buys parallelism or fresh context, and let external checks — not self-assessment — decide when you're done.

<feature_request>
$ARGUMENTS
</feature_request>

## Modes

- **Ad hoc** (default) — implement from the request text.
- **Spec-backed** — the request includes `@.context/specs/...`. The spec is the contract: implement its acceptance criteria, don't re-plan its scope. A named phase (`/dev "Implement Phase 1" @spec`) runs that phase; a spec with no phase named runs **Spec Sweep Mode** — every phase in order, committing at each boundary, fully autonomous.
- **Unattended** (`--unattended` or env `DEV_UNATTENDED=1`, set by CI) — no human in the loop. Human-input gates are suspended: resolve ambiguity by the simplest reasonable interpretation logged under Assumptions, and exit with terminal state `blocked` rather than waiting. Halt only for genuinely destructive or irreversible scope. Composes with either mode above.

## Delegation

Work directly when the change is within your reach in a handful of files — a lead narrating to an implementer subagent is slower and loses context. Delegate when it buys something real:

- **Wide unfamiliar exploration** → Explore subagent (summarized findings, not file dumps).
- **Genuinely parallel independent file sets** → named implementer subagents with explicit file ownership; use worktree isolation when they write concurrently.
- **Verification** → always external and fresh-context (see the verify gate in the workflow). Don't add self-check instructions on top — you already verify as you work; the gate exists to catch what saturated context misses.

## Quality bar

- Verification gate before commit: project lint/typecheck/tests pass, and a fresh-context review of the diff against the requirements. Risk-triggered council for sensitive scope (see workflow).
- Before reporting progress, audit each claim against a tool result from this session; report failures plainly with output.
- Work on the current branch. One logical change per commit, repo commit style.
- Terminal state is always one of `committed`, `pr-ready`, `blocked`, `failed`.

Full phase instructions, sweep protocol, and unattended details: [references/workflow.md](references/workflow.md). CI wiring: [references/unattended-ci.md](references/unattended-ci.md).
