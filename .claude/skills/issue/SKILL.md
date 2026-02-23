---
name: issue
description: Fetch a GitHub issue, explore the codebase, ask clarifying questions, and produce an implementation plan. Stops before building.
argument-hint: <issue number or URL>
---

# /issue - GitHub Issue Analysis & Planning

Analyze a GitHub issue and prepare an implementation plan. Research, explore, clarify, and plan - stopping before implementation to let the user decide when to proceed.

<role>
You are a senior engineering lead preparing to implement a GitHub issue. You analyze the issue, understand the codebase, ask clarifying questions, and create a detailed plan. You do NOT implement - you prepare.
</role>

<issue_input>
$ARGUMENTS
</issue_input>

---

## Core Principles

<principles>
1. **Analysis-First**: Thoroughly understand the issue before planning
2. **Delegation**: Exploration delegated to a subagent (not a team - lightweight)
3. **Clarification-First**: Ask questions BEFORE committing to a plan
4. **Plan-Only**: Create the plan, then STOP
5. **Stay on Current Branch**: Do NOT create new branches
</principles>

---

## Phase 1: Fetch Issue

<phase name="fetch">
Parse the input (issue number or URL) and fetch via `gh`:

```bash
gh issue view "$ISSUE_NUM" --json title,body,labels,state,assignees,comments
gh issue view "$ISSUE_NUM"
```

Extract and present:
- Title, number, state, labels, assignees
- Description (full body)
- Discussion highlights (key comment points)
- Linked PRs

Categorize: type (bug/feature/enhancement/refactor), scope (small/medium/large), area (UI/backend/fullstack/tooling).
</phase>

---

## Phase 2: Detect Stack

<phase name="detect">
Read project configuration to understand the environment:
- Language/Framework from manifest files
- Test, lint, build commands
- Whether UI work is involved
</phase>

---

## Phase 3: Explore

<phase name="explore">
Spawn a single explorer subagent (NOT a full team - this is a planning command):

```
Task: Analyze codebase for implementing this GitHub issue:

Issue #[number]: [title]
Description: [full body]
Type: [type], Area: [area]

Find: similar features, files to modify/create, patterns, dependencies, concerns.
Return findings in <explorer-result> block.
```

Wait for `<explorer-result>` block. If incomplete, re-delegate with guidance.
</phase>

---

## Phase 4: Clarify

<phase name="clarify">
Present understanding and ask numbered questions (max 5):

```
## Issue Understanding

**Issue:** #[number] - [title]
**tl;dr:** [1-2 sentence summary of approach]

**Scope Interpretation:**
- IN scope: [list]
- OUT of scope: [list]

**Affected Files:**
- Modify: [list from explorer]
- Create: [list from explorer]

## Clarifying Questions

1. [scope/boundaries]
2. [edge cases]
3. [acceptance criteria]
4. [testing requirements]
5. [integration points]

Reply with answers, or "proceed" to continue with current understanding.
```

**STOP. Wait for user response.**
</phase>

---

## Phase 5: Plan

<phase name="plan">
Create the implementation plan:

### Implementation Steps
1. [Specific change 1]
2. [Specific change 2]

### Files to Modify/Create
| File | Change Description |
|------|-------------------|
| `[file]` | [what changes] |

### Tests Needed
- [ ] [Test case 1]
- [ ] [Test case 2]

### AI Assessment
- **Approach**: [strategy]
- **Complexity**: [Low/Medium/High]
- **Risks**: [with mitigations]
- **Success Criteria**: [testable criteria]

### Ready for Implementation

```
Issue: #[number] - [title]
Branch: [current branch]
Complexity: [level]

To implement (team shape auto-detected from file map):
  /dev Implement GitHub issue #[number]: [title]
```

**STOP.** Do not implement. Wait for user to run the command.
</phase>
