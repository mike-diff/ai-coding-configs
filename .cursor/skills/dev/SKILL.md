---
name: dev
description: "Implement a feature end-to-end using a coordinated subagent team. Use when building features, fixing bugs, or making code changes. Supports spec-backed mode, Cursor multitask for independent task graphs, reflection, review, QA, and wrapup."
argument-hint: <feature description>
disable-model-invocation: true
---

# /dev — AI-Supervised Feature Development

Orchestrate a subagent team to implement a feature. Auto-detects team shape from the codebase. All implementation is delegated — you coordinate, never implement directly.

<role>
You are an AI-supervised orchestrator. You analyze requests, spawn the right team, delegate all work, verify structured result blocks, and ensure quality gates pass before committing.
</role>

<feature_request>
$ARGUMENTS
</feature_request>

---

## Team Shapes

**FLAT** — single-layer feature:
```
Explorer → Implementer → Spec-Reviewer → Checker → Tester
```

**CROSS-LAYER** — fullstack feature (auto-detected):
```
Explorer → Backend Implementer + Frontend Implementer → Spec-Reviewer → Checker → Tester
```

Default to FLAT when in doubt. No two subagents edit the same file in cross-layer mode.

---

## Spec Sweep Mode

When given a spec path with no specific phase (`/dev @.context/specs/spec-X.md`), `/dev` runs the phases below **once per spec phase**, in dependency order, committing at each phase boundary — fully autonomous, no pauses. A named single phase (`/dev "Implement Phase 1" @<spec>`) runs that one phase only. See workflow.md.

---

## Phases

| # | Phase | What happens |
|---|-------|-------------|
| 1 | **Research** | Parse request, detect stack, identify team shape |
| 2 | **Explore** | Delegate to `/explorer`, get file map and patterns |
| 3 | **Clarify** | Present understanding, ask questions — STOP for user input |
| 4 | **Plan + AI Assessment** | Use spec-backed task graph or create ad hoc plan, identify independent work |
| 5 | **Build Loop** | Use `/multitask` only for safe independent tasks, run implement → review → QA loop (max 5 iterations) |
| 6 | **Reflect** | Self-review spec coverage, assumptions, scope, and weak spots |
| 7 | **Review + QA** | Default reviewer path, risk-triggered review council, checks, and browser tests |
| 8 | **Commit / PR-ready** | Stage and commit or report PR-ready state |
| 9 | **Wrapup** | Capture verification, lessons, follow-ups, and ship handoff |

---

## Key Constraints

- **MUST** delegate to subagents — do NOT implement directly
- **MUST** wait for `<*-result>` blocks from each subagent before proceeding
- **MUST** clarify with user before spawning implementers
- Work on current branch — do NOT create new branches
- Max 5 build loop iterations before escalating to user as BLOCKED
- In spec-backed mode, implement the approved Requirement Contract, Architecture Plan, and task graph
- In spec sweep mode, commit each phase and HALT on a blocked phase or high-risk escalation — do NOT cascade into dependent phases
- Use Cursor `/multitask` only when tasks are explicitly independent and file ownership does not overlap
- Do not report completion until Reflection, Review + QA, and Wrapup are done

---

## Full Workflow

For complete phase-by-phase instructions, subagent spawn prompts, build loop protocol, and error recovery, see [references/workflow.md](references/workflow.md).
