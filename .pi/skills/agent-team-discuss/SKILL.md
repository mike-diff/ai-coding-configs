---
name: agent-team-discuss
description: Run the Agent Team discuss workflow in pi for this repo. Use when exploring a feature idea before writing a spec or implementation plan, validating assumptions, or preparing an ADLC handoff for /skill:agent-team-spec or /skill:agent-team-dev.
disable-model-invocation: true
---

# Agent Team Discuss

Run the Agent Team `/discuss` workflow from pi. This wrapper is a pointer plus pi-runtime translation — not an independent workflow implementation. When it disagrees with the source of truth, the source wins.

## Source of truth

- `.claude/skills/discuss/SKILL.md`
- `.claude/skills/discuss/references/phases.md`

Read those files before running the workflow. (`.cursor/` is a separate runtime adaptation, not a source for pi.)

## pi runtime translation

pi is single-agent: the source's background research subagents and adversarial challenger run here as **sequential inline passes** in one session:

1. **Triage** (from the source): if the idea is small and already clear, say so and recommend `/skill:agent-team-dev` directly.
2. **Research passes**: scout the codebase for patterns and integration points; then research the external landscape (libraries, platform features, recent releases). Ground the conversation in what you find.
3. **Converse**: at most 2-3 questions per turn; let findings change your questions.
4. **Adversarial pass**: before delivering, deliberately try to break the drafted plan — feasibility against the real codebase, simpler alternatives, native features that replace custom work, unverified assumptions. Report only findings that would change the plan.
5. **Deliver** the validated plan with the handoff block from the source's Phase 4, ending in `<adlc-handoff>` (see phases.md for the current field list — don't reconstruct it from memory).
6. Do not implement.

## Guardrails

- Keep the public workflow lightweight; do not introduce new ADLC commands.
- If a spec is needed, recommend `.context/specs/spec-[feature-name].md` via `/skill:agent-team-spec`.
- If this wrapper appears to contradict the `.claude` source files, the source wins — and flag the drift.
