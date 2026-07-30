---
name: agent-team-spec
description: Run the Agent Team spec workflow in pi for this repo. Use when turning a validated idea or ADLC handoff into a local, uncommitted, right-sized spec with acceptance criteria, self-contained phases and goal conditions.
disable-model-invocation: true
---

# Agent Team Spec

Run the Agent Team `/spec` workflow from pi. This wrapper is a pointer plus pi-runtime translation — not an independent workflow implementation. When it disagrees with the source of truth, the source wins.

## Source of truth

- `.claude/skills/spec/SKILL.md`
- `.claude/skills/spec/references/workflow.md` (the spec template and Goal Condition rule)

Read those files before drafting. (`.cursor/` is a separate runtime adaptation, not a source for pi.)

## pi runtime translation

- **Right-size first** per the source: no spec / light / full, scaled to criticality. State the tier and why.
- The source's Explore subagent becomes **inline codebase exploration**; AskUserQuestion becomes plain numbered questions (at most 4, only where answers change the spec).
- **One approval gate**: present problem, acceptance criteria, non-goals, and phase list; wait for approval; then finish and save. No other stops.
- Use the template in the source `workflow.md` verbatim — do not reconstruct sections from memory.
- Goal Condition blocks are portable text for Claude Code `/goal` sessions; pi cannot execute them, but every spec phase still gets one.

## Output

Save to `.context/specs/spec-[feature-name].md`. Confirm `.context/` is gitignored. Keep specs uncommitted unless the user explicitly promotes one.

```markdown
SPEC complete
File: .context/specs/spec-[feature-name].md
Tier: [light / full]
Phases: [N]
Next: /skill:agent-team-dev "Implement Phase 1" @.context/specs/spec-[feature-name].md
```

## Guardrails

- Preserve the 3-command UX: discuss, spec, dev. No ADLC command sprawl.
- If this wrapper appears to contradict the `.claude` source files, the source wins — and flag the drift.
