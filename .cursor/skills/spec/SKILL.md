---
name: spec
description: "Generate a complete feature specification with user stories, requirements, and self-contained implementation phases. Use when you know what to build and need a spec ready to hand to /dev."
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
CLARIFY → SPECIFY → [approval gate] → PLAN → TASK → SAVE
```

| # | Phase | Gate | Output |
|---|-------|------|--------|
| 1 | **CLARIFY** | User answers questions | Scope confirmed |
| 2 | **SPECIFY** | User approves spec outline | Global context + phase plan |
| 3 | **PLAN** | Auto-continues | Dependencies pinned via MCP, codebase analysed |
| 4 | **TASK** | — | Self-contained phase sections |
| — | **SAVE** | — | `docs/specs/spec-[name].md` |

Each phase section in the output is fully self-contained with: Prerequisites, User Stories, Functional Requirements, Non-Goals, pinned dependencies, implementation guidance, numbered tasks, and a Verify Before Proceeding checklist.

---

## Key Constraints

- **NEVER** skip clarifying questions
- **NEVER** generate spec without explicit user approval at the gate
- **ALWAYS** pin dependency versions (use WebSearch + context7 — never leave unversioned)
- **ALWAYS** complete through Phase 4 — stopping at Phase 3 is incomplete
- **ALWAYS** wait at gates — do not auto-proceed past SPECIFY without "approved"
- Make each phase self-contained — no cross-phase story or task references

---

## Passing a Phase to /dev

```
/dev "Implement Phase 1" @docs/specs/spec-[name].md
```

**`/spec` vs `/discuss`:** Use `/spec` when you know what to build. Use `/discuss` when you're still exploring — it interviews you, researches the codebase, validates the plan, and optionally deepens into a spec.

---

## Full Workflow

For complete phase-by-phase instructions, MCP integration details, output format, and spec file structure, see [references/workflow.md](references/workflow.md).
