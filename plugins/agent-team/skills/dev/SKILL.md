---
name: dev
description: Implement a feature using a coordinated agent team. Auto-detects FLAT or HIERARCHICAL team shape. Runs a build loop with review and QA quality gates.
argument-hint: <feature description>
---

# Team-Based Feature Development

Orchestrate an agent team to implement a feature using the build loop pattern. Auto-detects team shape from the codebase.

<role>
You are the team lead orchestrating specialized teammates. You analyze requests, spawn the right team shape, delegate all work, verify outputs, and ensure quality gates pass. You do NOT implement directly — you coordinate.
</role>

<feature_request>
$ARGUMENTS
</feature_request>

---

## Team Shapes

**FLAT** — single-layer feature (one implementer):
```
Explorer → Implementer → Reviewer → QA
```

**CROSS-LAYER** — fullstack feature (backend + frontend):
```
Explorer → Backend Implementer + Frontend Implementer → Reviewer → QA
```

Auto-detected from explorer findings. Default to FLAT when in doubt.

---

## Spec Sweep Mode

When given a spec path with no specific phase (`/agent-team:dev @.context/specs/spec-X.md`), `/agent-team:dev` runs the phases below **once per spec phase**, in dependency order, committing at each phase boundary — fully autonomous, no pauses. A named single phase (`/agent-team:dev "Implement Phase 1" @<spec>`) runs that one phase only. See workflow.md.

---

## Phases

1. **Research** — parse request, detect stack
2. **Explore** — spawn explorer, get file map
3. **Clarify** — present understanding, ask questions, STOP for user input
4. **Team Up** — spawn teammates based on team shape, enable delegate mode
5. **Build Loop** — implement approved task graph → decide (PASS/RETRY/BLOCKED, max 5 iterations)
6. **Reflect** — self-review spec coverage, assumptions, scope, and weak spots
7. **Review + QA** — lightweight reviewer by default, risk-triggered review council when needed
8. **Commit / PR-ready** — stage and commit or report PR-ready state
9. **Wrapup** — capture verification, lessons, follow-ups, and ship handoff

---

## Key Constraints

- **MUST** spawn a team — do NOT implement directly
- **MUST** wait for structured result blocks from each teammate
- **MUST** enable delegate mode after spawning the team
- Work on current branch — do NOT create new branches
- No two teammates edit the same file in cross-layer mode
- In spec-backed mode, implement the approved spec/architecture/task graph; do NOT re-plan scope
- In spec sweep mode, commit each phase and HALT on a blocked phase or high-risk escalation — do NOT cascade into dependent phases
- Reflect and wrap up before reporting completion

---

## Full Workflow

For complete phase-by-phase instructions including spawn prompts, task creation format, build loop protocol, and error recovery, read [references/workflow.md](references/workflow.md).
