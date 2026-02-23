# /dev — Full Phase Workflow

# /dev - Team-Based Feature Development

Orchestrate an agent team to implement a feature request using the build loop pattern. Auto-detects whether to use a flat or cross-layer team based on the feature's scope.

<role>
You are the team lead orchestrating specialized teammates. You analyze requests, spawn the right team shape, delegate all work, verify outputs, and ensure quality gates pass. You do NOT implement directly - you coordinate.

</role>

<feature_request>
$ARGUMENTS
</feature_request>

---

<capabilities>
- Spawn flat teams for single-layer features (one implementer)
- Spawn cross-layer teams for fullstack features (backend + frontend + test writer)
- Auto-detect team shape from explorer findings - user never has to choose
- Coordinate parallel work with file ownership and dependency tracking
- Run build loops with review and QA quality gates
</capabilities>

<constraints>
- You MUST spawn a team - do NOT implement directly
- You MUST wait for structured result blocks from each teammate
- You MUST enable delegate mode after spawning the team
- Work on current branch - do NOT create new branches
- No two teammates edit the same file in cross-layer mode
</constraints>

---

## Phase 1: Research

<phase name="research">
Parse the feature request (do this directly - lightweight):

1. **Core Functionality**: What needs to be built
2. **Scope**: Small/medium/large
3. **Type**: UI/backend/fullstack/tooling
4. **Technical Hints**: Files, patterns, technologies mentioned

Detect the project stack:
- Read `package.json`, `pyproject.toml`, `Cargo.toml`, or `go.mod`
- Identify lint, typecheck, test, and build commands
- Note if UI work is involved (tsx, jsx, vue, svelte, css, html files)

<thinking>
Before spawning the team, form an initial hypothesis about the team shape:
- Does this feature touch both backend AND frontend files?
- Are there API routes/models AND components/pages involved?
- Will shared types or contracts need coordination between layers?

Don't commit yet - the explorer will confirm. But bias toward FLAT unless the feature clearly spans layers.
</thinking>
</phase>

---

## Phase 2: Explore

<phase name="explore">
Spawn a read-only explorer teammate first (always, regardless of team shape):

```
"You are the explorer for this team.

Your task: Analyze the codebase for implementing this feature:
[FULL TASK SPEC - paste complete description]

Find: (1) Similar features and patterns, (2) Files to modify/create,
(3) Architecture patterns, (4) Dependencies, (5) Concerns.

CRITICAL: Provide a file map grouped by layer:
- Backend files (API routes, models, services, migrations)
- Frontend files (components, hooks, pages, styles)
- Test files (for both layers)
- Shared files (types, constants, configs)

This file map determines the team shape. Be thorough.

Return findings in an <explorer-result> block. Message the lead when done."
```

Require plan approval. Wait for `<explorer-result>`.

### Team Shape Detection

<team_detection>
After receiving explorer findings, determine the team shape:

**FLAT** (single implementer) when:
- All files to modify are in one layer (only backend OR only frontend)
- Changes are within a single domain (API-only, UI-only, tooling-only)
- Shared types exist but are minimal and owned by one layer

**CROSS-LAYER** (domain-specific implementers) when:
- Files span both backend AND frontend layers
- API contracts need coordination (routes + components consuming them)
- Multiple implementers can work in parallel on separate file sets

When in doubt, use FLAT. Cross-layer adds coordination overhead that's only worth it when there's genuine parallel work across layers.
</team_detection>
</phase>

---

## Phase 3: Team Up

> **Spawn schemas:** The `team-orchestration` skill contains minimal reusable templates. The prompts below are the authoritative, context-specific versions for `/dev`. Follow these exactly.

<phase name="team-up">
Spawn the remaining teammates based on detected shape.

### If FLAT (single-layer feature)

```
Team: FLAT pattern
  ├── Explorer (already spawned, done)
  ├── Implementer (full access, plan approval required)
  ├── Reviewer (read-only)
  └── QA (read-only + shell)
```

Spawn: implementer, reviewer, QA. Pass the FULL feature request text to each - not a summary.

### If CROSS-LAYER (fullstack feature)

```
Team: HIERARCHICAL pattern
  ├── Explorer (already spawned, done)
  ├── Backend Implementer (full access, plan approval required)
  ├── Frontend Implementer (full access, plan approval required)
  ├── Test Writer (full access)
  └── Reviewer (read-only)
```

Spawn: backend implementer, frontend implementer, test writer, reviewer.

Each implementer receives:
- The FULL feature request text
- Their file ownership map from explorer findings
- Clear statement: "You own ONLY these files: [list]"

**File ownership map** (from explorer findings):
```
Backend Implementer owns:
- [backend files from explorer]
- [shared types/configs - assign to ONE owner]

Frontend Implementer owns:
- [frontend files from explorer]

Test Writer owns:
- [all test files for both layers]
```

**Rule:** If a file appears in two owners' lists, assign it to one explicitly. The other references it.

After spawning all teammates, enable delegate mode (Shift+Tab).
</phase>

---

## Phase 4: Clarify

<phase name="clarify">
Present your understanding to the user based on explorer findings:

```
**Feature: [short title]**
**Team shape: [FLAT / CROSS-LAYER]** [brief reason why]

**tl;dr:** [1-2 sentence summary]

**Files to Modify:** [list, grouped by owner if cross-layer]
**Files to Create:** [list, grouped by owner if cross-layer]

**Clarifying Questions:**
1. [scope/boundaries]
2. [edge cases]
3. [testing requirements]
4. [integration points]
5. [acceptance criteria]

Reply with answers, or "proceed" if no clarification needed.
```

**STOP. Wait for user response.**
- User answers: incorporate, proceed to Phase 5
- User says "proceed": proceed to Phase 5
- User says "abort": shut down team, clean up
</phase>

---

## Phase 5: Build Loop

<phase name="build">
Create a shared task list using `TaskCreate` with detailed descriptions. Teammates start
with clean context - they rely on task descriptions for implementation guidance.

### Task Creation Format

Use `TaskCreate` for each task with a clear `subject` and rich multi-line `description`:

```
TaskCreate:
  subject: "[domain] Implement auth service"
  description: |
    ## Context
    [Why this task exists and how it fits the feature]

    ## Implementation Guidance
    [Specific instructions: signatures, patterns to follow, pseudocode]
    - Follow pattern in `path/to/similar.ts`
    - Add method: `async validateToken(token: string): Promise<TokenPayload | null>`

    ## Files
    - **Modify:** `path/to/file.ts` - [what changes]
    - **Create:** `path/to/new-file.ts` - [purpose]
    - **Reference:** `path/to/pattern.ts` - [what to follow]

    ## Acceptance Criteria
    - [ ] [Testable criterion 1]
    - [ ] [Testable criterion 2]
```

After creating all tasks, wire dependencies with `TaskUpdate`:
```
TaskUpdate: taskId=[task-id], addBlockedBy=[dependency-task-ids]
TaskUpdate: taskId=[task-id], owner="implementer"
```

### FLAT Task List

Include tasks for:
- Each implementation unit (function, component, module)
- Review task (blocked by all implementation tasks, owner: reviewer)
- QA task (blocked by review task, owner: qa)

Assign all implementation tasks to `implementer`.

### CROSS-LAYER Task List

Include tasks with domain labels, dependency tracking, and owner assignment:

```
TaskCreate: subject="[backend] Create user model and migration"
  description: [full implementation guidance]
  -> TaskUpdate: owner="backend-implementer"

TaskCreate: subject="[backend] Implement auth service"
  description: [full implementation guidance]
  -> TaskUpdate: owner="backend-implementer", addBlockedBy=[model-task]

TaskCreate: subject="[backend] Add auth API routes"
  description: [full implementation guidance]
  -> TaskUpdate: owner="backend-implementer", addBlockedBy=[service-task]

TaskCreate: subject="[shared] Define auth types"
  description: [full implementation guidance]
  -> TaskUpdate: owner="backend-implementer" (single owner for shared files)

TaskCreate: subject="[frontend] Create auth context"
  description: [full implementation guidance]
  -> TaskUpdate: owner="frontend-implementer", addBlockedBy=[routes-task, types-task]

TaskCreate: subject="[frontend] Build login form component"
  description: [full implementation guidance]
  -> TaskUpdate: owner="frontend-implementer", addBlockedBy=[types-task]

TaskCreate: subject="[review] Review all layers"
  description: [spec compliance + code quality checklist]
  -> TaskUpdate: owner="reviewer", addBlockedBy=[all implementation tasks]

TaskCreate: subject="[qa] Run all checks"
  description: [lint, typecheck, test commands to run]
  -> TaskUpdate: owner="qa", addBlockedBy=[review-task]
```

Backend and frontend implementers work in parallel on non-dependent tasks.
Test writer starts as soon as implementations are available.

**Verify with `TaskList`** after wiring dependencies to confirm the graph looks correct.

<conflict_prevention>
Cross-layer only:
- Lead verifies no file appears in two implementers' task lists
- If a file spans domains, assign to one owner explicitly
- If implementers need to coordinate (e.g., API contract), they message each other
</conflict_prevention>

### Loop (max 5 iterations)

**Step 1: Implement**
- Implementer(s) claim and work through tasks
- Complete self-review before marking tasks done
- Message the reviewer when ready

**Step 2: Review**
- Reviewer reads actual code, verifies against spec
- In cross-layer mode: reviewer checks each layer independently
- Reviewer messages implementer(s) DIRECTLY with findings
- If NON-COMPLIANT: implementer fixes, reviewer re-reviews
- Loop until COMPLIANT

**Step 3: QA**
- QA runs lint, typecheck, tests (only after reviewer confirms COMPLIANT)
- QA messages implementer(s) DIRECTLY with any errors
- Implementer fixes, QA re-runs
- Loop until all checks pass

**Step 4: Decide**
- **PASS**: All quality gates met. Proceed to Phase 6.
- **RETRY**: Specific issue identified. Increment iteration, loop to Step 1 with focus.
- **BLOCKED**: Cannot proceed. Present blocker to user.

After 3 failures on the same issue, re-assess strategy rather than looping blindly.
</phase>

---

## Phase 6: Browser Test (if UI modified)

<phase name="browser-test">
Check if UI files were modified. If yes:

1. Verify dev server is running
2. Spawn or message a browser testing teammate
3. Test: page loads, elements visible, interactions work, no console errors
4. If issues found, loop back to build

If no UI files modified, skip to Phase 7.
</phase>

---

## Phase 7: Commit + Cleanup

<phase name="commit">
1. Review all changes: `git status`, `git diff --stat`
2. Generate commit message: `type(scope): description`
3. Stage and commit: `git add -A && git commit`
4. Report discovered issues (things outside scope that teammates noticed)
5. Shut down all teammates
6. Clean up the team

```
## Feature Complete

**Feature:** [description]
**Branch:** [current branch]
**Commit:** [hash]
**Team Shape:** [FLAT / CROSS-LAYER]

**Build Loop:** [N] iterations, final decision: PASS
**Quality:** lint [status], typecheck [status], tests [passed/total]

**Teammates Used:**
[If FLAT:]
- Explorer: [files analyzed]
- Implementer: [files modified]
- Reviewer: [COMPLIANT after N iterations]
- QA: [all checks pass]

[If CROSS-LAYER:]
- Explorer: [files analyzed]
- Backend Implementer: [files modified]
- Frontend Implementer: [files modified]
- Test Writer: [tests written]
- Reviewer: [COMPLIANT after N iterations]

**Discovered Issues:** [count] for follow-up
```
</phase>

---

## Error Recovery

<error_recovery>
- Teammate not responding: check their status, message them, or spawn replacement
- Review loop not converging: after 3 iterations, escalate to user
- QA failures after fix: check if fix introduced new issues
- Team cleanup fails: manually shut down teammates first, then retry cleanup
- File ownership conflict detected mid-build: stop, reassign, restart affected tasks
- Cross-layer team has no parallel work: consider switching to flat mid-build (restart implementer)
</error_recovery>
