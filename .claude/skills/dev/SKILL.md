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

## Phases

1. **Research** — parse request, detect stack
2. **Explore** — spawn explorer, get file map
3. **Clarify** — present understanding, ask questions, STOP for user input
4. **Team Up** — spawn teammates based on team shape, enable delegate mode
5. **Build Loop** — implement → review → QA → decide (PASS/RETRY/BLOCKED, max 5 iterations)
6. **Browser Test** — if UI files modified
7. **Commit** — stage, commit, report discovered issues, shut down team

---

## Key Constraints

- **MUST** spawn a team — do NOT implement directly
- **MUST** wait for structured result blocks from each teammate
- **MUST** enable delegate mode after spawning the team
- Work on current branch — do NOT create new branches
- No two teammates edit the same file in cross-layer mode

---

## Full Workflow

For complete phase-by-phase instructions including spawn prompts, task creation format, build loop protocol, and error recovery, read [references/workflow.md](references/workflow.md).
