# /spec — Template and Goal Condition Rule

The spec file saved to `.context/specs/spec-[feature-name].md`. Light specs use the
frontmatter, Requirement Contract, and a single phase. Full specs add the Architecture
Plan and multiple phases. Omit any subsection that would be empty — an empty heading is
noise, not rigor.

## Spec file template

```markdown
---
id: SPEC-[short-id]
feature: [feature-name]
status: draft        # draft → approved → in-progress → implemented
depth: light         # light | full
created: [DATE]
updated: [DATE]
component: ""        # narrow area, e.g. "API/auth", "cli/workflow"
domain: ""           # broad area, e.g. "auth", "developer-workflow"
stack: []            # tech layers touched
concerns: []         # cross-cutting, e.g. ["security", "performance"]
---

# Specification: [Feature Name]

## Requirement Contract

### Problem
[2-3 sentences: the user/workflow problem and why it matters. Value, not implementation.]

### Approach
[The chosen approach in a few sentences, and why it beats the obvious alternative.]

### Acceptance Criteria
- AC-001: [specific, testable behavior — provable by a command's output]
- AC-002: [...]

### Non-Goals
- [explicitly excluded scope — the cheapest scope-creep prevention available]

### Assumptions
- [assumption] — [verified / likely / risk]

### Human Decision Boundaries
[Only when real ones exist: decisions the implementing agent must not make alone —
public API contract changes, migrations/destructive operations, deployment, billing.
Inherit from the /discuss handoff when present.]

## Architecture Plan
*(full tier only)*

### Existing Patterns to Follow
- `[path]` — [pattern and why it applies]

### Files to Create / Modify
- `[path]` — [create/modify, what and why]

### Contracts
[API payloads, schemas, shared types, or UI state boundaries that phases must agree on]

### Test Strategy
[What proves local behavior, what proves the contracts, what proves the user outcome]

### Risks
- [risk] — [mitigation or explicit deferral]

---

# Phase N: [Phase Name]

## Prerequisites
*(Phase 1+ only)* Phase N-1 complete. You have: [concrete artifacts — endpoints, tables,
components. What EXISTS, not how it was built.]

## Scope
[1-2 sentences: what this phase accomplishes]

## Acceptance Criteria
- AC-0XX: [criteria owned by this phase; a criterion belongs to exactly one phase]

## Non-Goals (This Phase)
- [deferred to a later phase or out of scope]

## New Dependencies
*(only packages first used in this phase; omit the section when there are none)*
| Package | Version (verified [DATE]) | Purpose |
|---------|---------------------------|---------|

## Files
- `[path]` — [create/modify, what changes]

## Goal Condition

```text
Phase N ([name]) is done when ALL hold AND the proof is shown in this conversation:
1. `[primary test/build command]` exits 0 — paste the final summary line.
2. AC-0XX: `[proof command]` outputs [concrete expected string/exit code] — paste it.
3. [one line per remaining AC: command + the exact output that proves it]
4. `[full regression command]` still exits 0 — paste the summary.
Constraints that must not change: only files under [globs from Files] are modified;
no new dependencies beyond [pinned list]; public contracts unchanged.
Stop and report if any command fails twice in a row, or after [N] turns, whichever first.
```

---
[repeat per phase; light specs have exactly one]

## Wrapup
*(appended by /dev after implementation: what shipped, verification results, lessons,
follow-ups)*
```

## Goal Condition rule

Translate every acceptance criterion into one numbered clause naming a concrete command
and the exact output or exit code that proves it. The `/goal` evaluator reads only the
transcript and cannot run tools, so subjective clauses ("works", "is correct") are
unverifiable — if a criterion has no command-observable proof, mark it `[manual]` in the
phase and leave it out of the Goal Condition. Append the scope-constraint line (from the
phase's file globs and new dependencies) and a turn cap (default 25, scaled roughly
2-3 turns per meaningful unit of work). Keep each block under 4,000 characters.

## Report format

After saving:

```markdown
Spec complete → `.context/specs/spec-[feature-name].md`
Tier: [light / full] — [one-line reason]
Phases: [N]

Implement all phases autonomously:
  /dev @.context/specs/spec-[feature-name].md
One phase at a time:
  /dev "Implement Phase 1" @.context/specs/spec-[feature-name].md
Drive a single phase solo with native /goal (no subagents, one session):
  /goal "<paste that phase's Goal Condition>"
Don't set a /goal on a phase /dev is already driving — /dev has its own verify gate.
```

## Living-document protocol

- `/dev` sets `status: in-progress` when it starts and `implemented` at wrapup, and
  appends the Wrapup section.
- When implementation reveals the spec was wrong (missing constraint, wrong file map,
  infeasible AC), update the spec in place and note the change in the Wrapup — the spec
  should read true after the work, not preserve the original guess.
