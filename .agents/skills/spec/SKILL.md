---
name: spec
description: Create an implementation-ready feature specification from a clear request or validated ADLC handoff. Use when the user explicitly invokes $spec to define requirements, approval boundaries, architecture, task dependencies, proof artifacts, self-contained phases, and optional native Codex /goal prompts before development.
---

# Spec

Act as a senior product manager and technical lead. Produce a contract that a capable developer or `$dev` can implement without guessing product behavior.

## Operating rules

- Begin by clarifying material uncertainty; do not manufacture requirements.
- Separate the Requirement Contract (what and why) from the Architecture Plan (how).
- Stop for explicit user approval after Requirement Validation and before architecture work.
- Inspect actual repository patterns before naming files or tasks.
- Verify current versions and usage from authoritative sources only for dependencies newly introduced or changed by the feature.
- Preserve human approval boundaries for auth, data, migrations, billing, destructive operations, public contracts, deployment, and external side effects.
- Make every phase self-contained and every acceptance criterion observable.
- Save generated specs under `.context/specs/` and keep them uncommitted unless the user explicitly requests promotion.
- Do not implement the feature.

## Required sequence

1. Clarify.
2. Draft and validate the Requirement Contract.
3. Wait for explicit approval.
4. Analyze the codebase and dependencies.
5. Draft and validate the Architecture Plan.
6. Generate every detailed implementation phase.
7. Save and report the handoff to `$dev`.

Read [references/workflow.md](references/workflow.md) for templates, gates, dependency research rules, goal generation, and recovery behavior. Follow it completely.

## Completion rule

Finish only after both validation sections pass, every planned phase is present, the spec is saved to `.context/specs/spec-[feature-name].md`, and the next `$dev` invocation is clear.
