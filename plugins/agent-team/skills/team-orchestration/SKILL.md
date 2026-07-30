---
name: team-orchestration
description: Delegation and orchestration patterns for Claude Code — when to work directly vs delegate, subagents vs Workflow fan-outs, parallel write isolation, verification topology, and effort/model tiering. Use when coordinating subagents, running multi-agent work, or deciding whether to delegate at all.
---

# Orchestration

Patterns for deciding when to delegate, what to delegate to, and how to verify the result. Every session has an implicit team: spawn named subagents with the Agent tool, message them with SendMessage, share work through the task list. There is no separate team lifecycle to manage.

## First decision: delegate at all?

Work directly when the task is within reach in a handful of files and tool calls — you have a 1M-token context and delegation costs tokens, latency, and context transfer. Delegate when it buys something real:

| Buy | Mechanism |
|-----|-----------|
| **Parallel independent work** | Named subagents, one per independent piece; async — keep working while they run |
| **Context isolation** — wide exploration whose file dumps you don't want | Explore subagent; you get the conclusion, not the transcript |
| **Fresh eyes** — verification by a context that didn't write the code | Reviewer subagent reading the actual diff |
| **Deterministic fan-out** — many items through the same stages | Workflow tool (pipeline/parallel, schema-validated outputs) |

The multiplier is real: multi-agent runs cost many times a single session, and most of the benefit comes from context isolation, not conversation between agents. If the work doesn't decompose into independent pieces, a team burns tokens without earning them.

## Subagents vs Workflow

- **Subagents (Agent tool)** — judgment-shaped work: exploration, review, research, an independent implementation track. Named agents persist and can be continued via SendMessage; prefer long-lived named agents over fresh spawns for related follow-ups.
- **Workflow** — structure-shaped work: fan out N items through find → verify → synthesize stages with deterministic control flow and schema-validated results. Reach for it for review councils, migration sweeps, and multi-lens audits. Requires explicit user opt-in for large orchestrations; keep under the session's size guideline.
- **Not usable headless in CI** — Workflow invocations hit an interactive approval gate; in CI, keep delegation to flat, one-level Task subagents (see `/agent-team:dev`'s unattended-ci reference).

## Parallel writes

No two writers on one file, ever. Give each implementer subagent an explicit file-ownership list; define shared contracts (types, API shapes) yourself before splitting the work; use worktree isolation when writers run concurrently. A file that seems to need two owners gets one owner and one consumer.

## Coordination

- **Task list** — TaskCreate/TaskUpdate with dependency chains when coordinating multiple agents or sweeping phases; skip the bookkeeping for direct single-pass work. Task descriptions carry the context a clean-context agent needs: goal, files, acceptance criteria, patterns to follow.
- **Briefs** — role + full task spec + what to return. Project context (CLAUDE.md, rules, skills, memory) loads automatically; don't paste it. Have subagents return summaries with `<*-result>`-style structure — findings and paths, not transcripts.
- **Messaging** — SendMessage to steer a running agent or continue a finished one. Intervene when a subagent is off track or missing context rather than waiting for a bad result.

## Verification topology

- Fresh-context verifiers outperform self-critique: the reviewer must not be the context that wrote the code. Don't add "double-check your work" instructions on top of current models — they self-verify; the external gate exists to catch what a saturated context misses.
- Brief reviewers for **coverage, then filter**: report every issue with severity and confidence; ranking happens downstream. "Only report high-severity issues" suppresses real findings.
- Escalate to a parallel multi-lens council (correctness, security, architecture, test coverage) only for risk-triggered scope — auth, payments, data, migrations, public contracts.

## Tiering

- **Model**: strong model for the orchestrating/implementing context; cheaper models for scouts, QA runs, and mechanical stages (set in agent frontmatter `model:`).
- **Effort**: low for mechanical subagent work, high where correctness is capability-sensitive. Hold the session's own effort constant; vary it across agents, not mid-conversation.

## Red flags

| Thought | Reality |
|---------|---------|
| "Tests pass, so it's correct" | Tests verify behavior, not requirements. Spec review catches "wrong thing built well." |
| "The implementer is confident" | Confidence isn't correctness. Verify with fresh context. |
| "One more retry won't hurt" | After 3 failures on the same gate, re-assess the approach — don't loop blindly. |
| "I'll skip clarification, it's obvious" | A wrong guess on scope wastes the whole run. One question is cheaper. |
| "The subagent can figure out the context" | Clean-context agents know only their brief. Pass the full task spec. |
| "More agents means more rigor" | Unparallelizable work in a team is pure multiplier cost. Decompose first, then delegate. |
