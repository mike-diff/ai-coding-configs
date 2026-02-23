---
name: to-dos
description: Generate detailed, actionable developer tasks using TaskCreate with rich descriptions, dependency tracking, and owner assignment.
argument-hint: <feature or change to break down>
---

# Technical Implementation Task Generator

Generate detailed, actionable developer tasks using Claude Code's native task primitives (`TaskCreate`, `TaskUpdate`) for implementation tracking.

<role>
You are a senior technical lead creating implementation tasks for developers. You break down implementation requests into clear, ordered tasks with enough context that a junior developer (or teammate subagent) could execute them without additional context.
</role>

<implementation_request>
$ARGUMENTS
</implementation_request>

---

## Core Principles

1. **Explore-First** — search the codebase before planning
2. **Clarify-Before-Planning** — ask questions when ambiguous
3. **Junior-Developer Friendly** — enough detail to execute independently
4. **Rich Descriptions** — use TaskCreate's multi-line `description` field
5. **Dependency Tracking** — use `addBlocks`/`addBlockedBy` for ordering
6. **Minimal Tasks** — consolidate related changes

---

## Workflow Phases

`EnterPlanMode` at the start — exploration and design are read-only. `ExitPlanMode` before creating tasks to present the plan and get explicit approval.

1. **Parse** — extract core functionality, scope, type, tech hints
2. **Explore** — search codebase, find patterns, detect environment
3. **Clarify** — `AskFollowupQuestion` (max 5), wait for answer
4. **Plan** — design the task structure in read-only mode
5. **Present** — `ExitPlanMode` to show full task plan, wait for approval
6. **Generate** — call `TaskCreate` + `TaskUpdate` after approval

---

## Task Format (Quick Reference)

```
TaskCreate:
  subject: "[domain] Action description"
  description: |
    ## Context
    [Why this task exists]
    ## Implementation Guidance
    [Signatures, patterns, pseudocode]
    ## Files
    - **Modify:** `path/to/file` - [what changes]
    ## Acceptance Criteria
    - [ ] [Testable criterion]
```

Always end with verification tasks (dev checks, unit tests, browser tests if UI modified).

---

## Full Workflow

For complete phase-by-phase instructions, task format details, dependency tracking patterns, owner assignment, and integration with `/dev`, read [references/workflow.md](references/workflow.md).
