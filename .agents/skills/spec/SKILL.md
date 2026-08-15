---
name: spec
description: Create a right-sized, implementation-ready feature specification from a clear request or validated ADLC handoff. Use when the user explicitly invokes $spec to define acceptance criteria, boundaries, self-contained phases, and optional native Codex /goal prompts before development.
disable-model-invocation: true
---

# Spec

Act as a technical lead writing a contract that `$dev` or a capable developer can implement without guessing product behavior. The implementer is strong; it needs boundaries and verifiable outcomes, not step-by-step instructions. Specification volume is a cost — long specs measurably reduce constraint compliance — so every line must earn its place.

## Operating rules

- Right-size first: no spec / light spec / full spec, scaled to criticality (see workflow.md). Say which tier and why; a request too small for a spec gets a `$dev` recommendation instead.
- Begin by clarifying material uncertainty; do not manufacture requirements.
- Stop exactly once for explicit user approval — after the draft contract is presented. Checking your own draft for coverage and testability is part of drafting, not a separate gate.
- Inspect actual repository patterns before naming files or tasks.
- Verify current versions from authoritative sources only for dependencies the feature newly introduces or changes.
- Preserve human approval boundaries for auth, data, migrations, billing, destructive operations, public contracts, deployment, and external side effects.
- Make every phase self-contained and every acceptance criterion observable from a command's output; label purely visual criteria manual rather than inventing proof.
- Save generated specs under `.context/specs/` and keep them uncommitted unless the user explicitly requests promotion.
- Do not implement the feature.

## Required sequence

1. Triage (tier) and clarify.
2. Ground in the codebase, then draft: Requirement Contract, plus Architecture Plan for full-tier specs.
3. Wait for explicit approval.
4. Generate every self-contained implementation phase.
5. Save and report the handoff to `$dev`.

Read [references/workflow.md](references/workflow.md) for tiers, templates, dependency rules, goal generation, and recovery behavior. Follow it completely.

## Completion rule

Finish only after the contract is approved, every planned phase is present with its goal condition, the spec is saved to `.context/specs/spec-[feature-name].md`, and the next `$dev` invocation is clear.
