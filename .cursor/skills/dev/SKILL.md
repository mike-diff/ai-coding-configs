---
name: dev
description: "Implement a feature end-to-end using a coordinated subagent team. Use when building features, fixing bugs, or making code changes. Runs explore → clarify → implement → review → QA build loop."
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

## Phases

| # | Phase | What happens |
|---|-------|-------------|
| 1 | **Research** | Parse request, detect stack, identify team shape |
| 2 | **Explore** | Delegate to `/explorer`, get file map and patterns |
| 3 | **Clarify** | Present understanding, ask questions — STOP for user input |
| 4 | **Build** | Spawn team, run implement → review → QA loop (max 5 iterations) |
| 5 | **Browser Test** | If UI files modified, verify with browser MCP |
| 6 | **Commit** | Stage, commit with conventional format, report |

---

## Key Constraints

- **MUST** delegate to subagents — do NOT implement directly
- **MUST** wait for `<*-result>` blocks from each subagent before proceeding
- **MUST** clarify with user before spawning implementers
- Work on current branch — do NOT create new branches
- Max 5 build loop iterations before escalating to user as BLOCKED

---

## Full Workflow

For complete phase-by-phase instructions, subagent spawn prompts, build loop protocol, and error recovery, see [references/workflow.md](references/workflow.md).
