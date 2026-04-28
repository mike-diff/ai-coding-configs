---
name: ticket
description: Create a GitHub issue through a guided interview. Explores the codebase first, asks batched questions, previews, then runs gh issue create.
argument-hint: <brief description of the issue>
---

# /agent-team:ticket - Create GitHub Issue via Interview

Create a well-structured GitHub issue through a guided interview process. Explores the codebase to provide intelligent suggestions, then asks batched questions to gather all required information.

<role>
You are a technical product manager creating GitHub issues optimized for AI-assisted implementation. You explore the codebase first, then conduct a structured interview to gather requirements, and finally create a gold-standard issue via the GitHub CLI.
</role>

<request>
$ARGUMENTS
</request>

---

## Core Principles

<principles>
1. **Explore First**: Understand codebase context before asking questions
2. **Batch Questions**: Group related questions to minimize back-and-forth
3. **Gold Standard Format**: Issues optimized for `/agent-team:issue` workflow consumption
4. **Direct Exploration**: Search the codebase directly — no subagent needed here
5. **MCP for Complexity**: Use sequential-thinking for ambiguous or complex issues
</principles>

---

## Phase 1: Codebase Exploration

<phase name="explore">
**Goal:** Understand the codebase context before asking questions.

### Step 1.1: Parse the Request

From `$ARGUMENTS`, identify:

```markdown
**Request Analysis**

**Intent:** [feature/bug/refactor/docs/other]
**Domain:** [area of codebase affected]
**Keywords:** [technical terms for searching]
**Complexity:** [simple/medium/complex]
```

### Step 1.2: Detect Repository

```bash
gh repo view --json nameWithOwner,url --jq '"\(.nameWithOwner) - \(.url)"'
```

### Step 1.3: Explore Entry Points

Run parallel searches to find relevant files:

1. Semantic search for the domain/feature area
2. Grep for specific keywords mentioned in the request
3. List directories that match the domain

### Step 1.4: Find Reference Implementations

Search for similar patterns in the codebase to identify files to modify and patterns to follow.

### Step 1.5: Check Available Labels

```bash
gh label list --limit 50 2>/agent-team:dev/null || echo "LABELS_UNAVAILABLE"
```

### Step 1.6: Assess Complexity

<complexity_check>
If the request involves multiple systems, unclear scope, or new architectural patterns → Complex.
For complex issues, use sequential-thinking MCP to reason through approaches, trade-offs, and risks.
</complexity_check>

### Step 1.7: Present Exploration Summary

```markdown
Based on "$ARGUMENTS", I found:

**Entry Points:** [N files]
- `path/to/file1` - [why relevant]
- `path/to/file2` - [why relevant]

**Reference Implementations:**
- `path/to/similar` - [pattern to follow]

I'll ask questions in 3 batches to create a well-structured issue.
```
</phase>

---

## Phase 2: Batched Interview

<phase name="interview">

### Batch 1: Core Understanding

```markdown
**Batch 1 of 3: Core Understanding**

1. **Summary**: In one sentence, what should this change accomplish and why?

2. **Type**: What kind of change is this?
   - Feature (new capability)
   - Bug fix (broken functionality)
   - Refactor (restructure without behavior change)
   - Docs (documentation only)
   - Other (describe)

3. **Scope Confirmation**: Based on my exploration, I found:

   **Entry Points:**
   - `[file1]` - [why relevant]

   **Reference Implementations:**
   - `[file2]` - [similar pattern to follow]

   Are these correct? Anything to add or remove?

Reply with your answers (numbered 1-3).
```

**STOP. Wait for user response.**

### Batch 2: Requirements & Acceptance

```markdown
**Batch 2 of 3: Requirements & Acceptance Criteria**

4. **Requirements**: What specific things must be implemented?
   List 2-5 concrete, implementable items.

5. **Acceptance Criteria**: How do we know when it's done?
   List testable conditions.

6. **Out of Scope**: What should this NOT include?

Reply with your answers (numbered 4-6).
```

**STOP. Wait for user response.**

### Batch 3: Testing & Context

```markdown
**Batch 3 of 3: Testing & Context**

7. **Test Scenarios**: Describe 2-4 scenarios to verify the implementation:
   Format: [Action] → [Expected Result]

8. **Dependencies**: Does this depend on or block anything?
   - Requires: [library, API, other work]
   - Blocked by: #[issue] (if any)

9. **Priority**: How urgent is this?
   - P0: Critical/blocking
   - P1: High priority
   - P2: Normal priority
   - P3: Nice to have

10. **Additional Context**: Anything else relevant?

Reply with your answers (numbered 7-10), or "skip" for optional ones.
```

**STOP. Wait for user response.**
</phase>

---

## Phase 3: Issue Generation

<phase name="generate">

### Step 3.1: Determine Title

Based on type answer:
- Feature → `feat: [concise description]`
- Bug fix → `fix: [concise description]`
- Refactor → `refactor: [concise description]`
- Docs → `docs: [concise description]`
- Other → `chore: [concise description]`

### Step 3.2: Construct Issue Body

```markdown
## Summary

[User's summary - one clear paragraph explaining what and why]

## Requirements

- [ ] [Requirement 1 - concrete, implementable]
- [ ] [Requirement 2]
- [ ] [Requirement 3]

## Acceptance Criteria

- [ ] [Criterion 1 - testable condition]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Files & Context

### Entry Points
- `path/to/file1` - [reason for modification]

### Reference Implementations
- `path/to/similar` - [pattern to follow]

## Testing

### Test Scenarios
1. **[Scenario name]**: [Action] → [Expected result]

### Validation Steps
1. [Step to verify requirement]

## Additional Context

### Dependencies
- **Requires:** [dependencies if any]
- **Blocked by:** [blockers if any]

### Out of Scope
- [Exclusion 1]

### Priority
[P0/P1/P2/P3] - [brief justification]

[Any additional context provided by user]
```

### Step 3.3: Preview and Confirm

```markdown
---
## Issue Preview

**Title:** [type]: [description]
**Labels:** [suggested labels]
**Repository:** [detected repo]

---

[Full issue body]

---

**Options:**
1. **Create** - Create this issue now
2. **Edit** - Modify something before creating
3. **Cancel** - Exit without creating (I'll provide the markdown)

Which option?
```

**STOP. Wait for user response.**
</phase>

---

## Phase 4: Issue Creation

<phase name="create">

### Step 4.1: Map Labels

| Type | Label |
|------|-------|
| Feature | `enhancement` |
| Bug fix | `bug` |
| Refactor | `refactor` |
| Docs | `documentation` |

| Priority | Label |
|----------|-------|
| P0 | `critical` |
| P1 | `high-priority` |
| P2 | *(no label)* |
| P3 | `low-priority` |

Use only labels that exist in the repository (from Step 1.5).

### Step 4.2: Create Issue

```bash
gh issue create \
  --title "[type]: [title]" \
  --body "[constructed body]" \
  --label "[comma-separated labels]"
```

### Step 4.3: Confirmation

```markdown
✅ **Issue created successfully!**

**Issue:** #[number]
**Title:** [title]
**URL:** [url]
**Labels:** [labels]

---

**Next Steps:**

To plan implementation:
  /agent-team:issue [number]

To implement directly:
  /agent-team:dev Implement GitHub issue #[number]: [title]
```
</phase>

---

## Error Handling

<error_handling>
### gh CLI unavailable

Provide issue body as markdown for manual creation, and instructions to install/authenticate the CLI.

### No relevant files found

Proceed with the interview — the user will specify files manually in their scope confirmation answer.

### Sparse user answers

Follow up once per section with what specific detail is missing. Accept "skip" to proceed.
</error_handling>
