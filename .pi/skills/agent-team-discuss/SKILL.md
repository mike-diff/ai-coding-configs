---
name: agent-team-discuss
description: Run the Agent Team discuss workflow in pi for this repo. Use when exploring a feature idea before writing a spec or implementation plan, validating assumptions, or preparing an ADLC handoff for /skill:agent-team-spec or /skill:agent-team-dev.
---

# Agent Team Discuss

Use this skill to run the Agent Team `/discuss` workflow from pi while maintaining repo parity.

## Source of truth

The product workflow source of truth is:

- `.claude/skills/discuss/SKILL.md`
- `.claude/skills/discuss/references/phases.md`
- `.cursor/skills/discuss/SKILL.md`
- `.cursor/skills/discuss/references/phases.md`

Read those files when details matter. This pi skill is a maintainer/operator wrapper, not a fourth independent workflow implementation.

## Goal

Answer: Should we build this, what are we assuming, and what should flow into `/skill:agent-team-spec` or `/skill:agent-team-dev`?

## Process

1. Parse the idea and detect mode:
   - Fresh idea
   - Revisit existing implementation
   - Reference-driven discussion using files, docs, URLs, or prior context
2. Ask at most 3 clarifying questions at a time.
3. Use repo search and file reads to ground the conversation in existing patterns.
4. Use subagents only when useful:
   - Codebase scout for implementation patterns
   - Web or docs researcher for external libraries or current platform behavior
   - Challenger or reviewer for blind spots on high-risk plans
5. Validate the plan before recommending build.
6. Do not implement.
7. End with a compact validated plan and an `<adlc-handoff>` block.

## Required final handoff

```xml
<adlc-handoff>
problem: [one-sentence problem]
target_user: [primary user or actor]
hypothesis: [why this approach should work]
success_metrics:
  - [measurable success signal]
core_workflow_break: [what is broken or missing today]
assumptions:
  - [assumption to validate]
risks:
  - [risk to mitigate]
human_decisions_required:
  - [decision user must make before build, or None]
recommended_next: /skill:agent-team-spec "[feature]" or /skill:agent-team-dev "[small validated change]"
</adlc-handoff>
```

## Guardrails

- Keep the public workflow lightweight. Do not introduce new ADLC commands.
- If a spec is needed, recommend `.context/specs/spec-[feature-name].md`.
- If you notice drift between `.claude/`, plugin and `.cursor/`, flag it before proceeding.
