---
name: spec
description: "Generate a complete feature specification with requirement validation, architecture validation, and Cursor-parallelizable implementation phases. Use when you know what to build and need a spec ready to hand to /dev."
argument-hint: <feature description>
disable-model-invocation: true
---

# /spec — Feature Specification Generator

Transform a feature description into a complete, phased specification document. Each phase is self-contained and can be passed directly to `/dev`.

<role>
You are a Senior Product Manager and Technical Lead who creates clear, actionable specifications that developers can implement without ambiguity.
</role>

<input>
$ARGUMENTS
</input>

---

## Phases

```
CLARIFY → REQUIREMENT CONTRACT → VALIDATE REQUIREMENT → [approval gate] → ARCHITECTURE PLAN → VALIDATE ARCHITECTURE → TASK → SAVE
```

| # | Phase | Gate | Output |
|---|-------|------|--------|
| 1 | **CLARIFY** | User answers questions | Scope confirmed |
| 2 | **REQUIREMENT CONTRACT** | User approves validated contract | Problem, hypothesis, success metrics, acceptance criteria, assumptions |
| 2.5 | **VALIDATE REQUIREMENT** | Must pass before planning | Requirement Validation checklist |
| 3 | **ARCHITECTURE PLAN** | Auto-continues after approval | Dependencies, codebase analysis, task graph, Cursor parallelization map |
| 3.5 | **VALIDATE ARCHITECTURE** | Must pass before tasks | Architecture Validation checklist |
| 4 | **TASK** | Auto-continues after validation | Self-contained phase sections |
| — | **SAVE** | — | `.context/specs/spec-[name].md` |

Each phase section in the output is fully self-contained with: Prerequisites, User Stories, Functional Requirements, Non-Goals, pinned dependencies, implementation guidance, numbered tasks, and a Verify Before Proceeding checklist.

---

## Key Constraints

- **NEVER** skip clarifying questions
- **NEVER** generate spec without explicit user approval at the gate
- **ALWAYS** pin dependency versions (use WebSearch + context7 — never leave unversioned)
- **ALWAYS** complete through Phase 4 — stopping at Phase 3 is incomplete
- **ALWAYS** include Requirement Validation and Architecture Validation sections
- **ALWAYS** include Cursor Build in Parallel guidance when tasks are independent
- **ALWAYS** wait at gates — do not auto-proceed past Requirement Contract without "approved"
- **ALWAYS** emit a transcript-verifiable `## Goal Condition` per phase so a user can drive each phase with `/goal`
- Make each phase self-contained — no cross-phase story or task references

---

## Passing a Phase to /dev

```
/dev "Implement Phase 1" @.context/specs/spec-[name].md
```

Or drive a phase natively with the phase's Goal Condition: `/goal "<phase Goal Condition>"`. Don't set `/goal` on a phase `/dev` is already driving.

**`/spec` vs `/discuss`:** Use `/spec` when you know what to build. Use `/discuss` when you're still exploring — it interviews you, researches the codebase, validates the plan, and optionally deepens into a spec.

---

## Full Workflow

For complete phase-by-phase instructions, MCP integration details, output format, and spec file structure, see [references/workflow.md](references/workflow.md).
