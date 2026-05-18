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
- Run build loops with reflect, review, QA, and wrapup quality gates
</capabilities>

<constraints>
- You MUST spawn a team - do NOT implement directly
- You MUST wait for structured result blocks from each teammate
- You MUST enable delegate mode after spawning the team
- Work on current branch - do NOT create new branches
- No two teammates edit the same file in cross-layer mode
- In Spec-backed mode, implement the approved Requirement Contract, Architecture Plan, and task graph; do not re-plan scope
- Do not report completion until Reflection, Review + QA, and Wrapup are done
</constraints>

---

## Phase 1: Research

<phase name="research">
Parse the feature request (do this directly - lightweight):

1. **Mode**: Spec-backed mode if the request includes `@.context/specs/...`; otherwise Ad hoc mode
2. **Core Functionality**: What needs to be built
3. **Scope**: Small/medium/large
4. **Type**: UI/backend/fullstack/tooling
5. **Technical Hints**: Files, patterns, technologies mentioned

### Spec-backed mode

If a spec file is provided:
- Read the Requirement Contract, Requirement Validation, Architecture Plan, Architecture Validation, and task graph before spawning teammates
- Verify Requirement Validation and Architecture Validation are PASS or explicitly accepted by the user
- Treat the spec as the contract; later phases may refine execution details but must not expand scope
- If the spec lacks the ADLC-lite sections, continue in compatibility mode but flag that reflection/wrapup will be less precise

Detect the project stack:
- Read `package.json`, `pyproject.toml`, `Cargo.toml`, or `go.mod`
- Identify lint, typecheck, test, and build commands
- Note if UI work is involved (tsx, jsx, vue, svelte, css, html files)

<thinking>
Before spawning the team, form an initial hypothesis about the team shape:
- Does this feature touch both backend AND frontend files?
- Are there API routes/models AND components/pages involved?
- Will shared types or contracts need coordination between layers?

Don't commit yet - the explorer will confirm. But bias toward FLAT unless the feature clearly spans layers. In spec-backed mode, the approved Architecture Plan and task graph override the initial hypothesis unless the explorer finds a blocking mismatch.
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

## Phase 3: Clarify

<phase name="clarify">
Present your understanding to the user based on explorer findings before spawning implementers. This is the ADLC requirement-validation checkpoint inside `/dev`: make sure the request, boundaries, and acceptance criteria are clear before code-writing teammates exist.

```
**Feature: [short title]**
**Mode:** [Spec-backed mode / Ad hoc mode]
**Team shape: [FLAT / CROSS-LAYER]** [brief reason why]

**tl;dr:** [1-2 sentence summary]

**Spec-backed mode:** [if @.context/specs/... was provided, list the spec path, validation status, and task graph source]
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
- User answers: incorporate, proceed to Phase 4
- User says "proceed": proceed to Phase 4
- User says "abort": shut down all teammates (via `shutdown_request`), then call `TeamDelete`
</phase>

---

## Phase 4: Team Up

> **Spawn schemas:** The `team-orchestration` skill contains minimal reusable templates. The prompts below are the authoritative, context-specific versions for `/dev`. Follow these exactly.

<phase name="team-up">
Spawn the remaining teammates based on detected shape only after clarification is complete.

### If FLAT (single-layer feature)

```
Team: FLAT pattern
  ├── Explorer (already spawned, done)
  ├── Implementer (full access, plan approval required)
  ├── Reviewer (read-only)
  └── QA (read-only + shell)
```

Spawn: implementer, reviewer, QA. Pass the FULL feature request text to each - not a summary. In spec-backed mode, also pass the Requirement Contract, Architecture Plan, Architecture Validation, and task graph from the spec.

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
- In spec-backed mode: the exact task IDs and acceptance criteria they own
- Their file ownership map from explorer findings
- Clear statement: "You own ONLY these files: [list]"
- Clear statement: "Do not expand scope beyond the approved spec without asking the lead."

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

## Phase 6: Reflect

<phase name="reflect">
Before independent review, produce an honest self-review from the lead's perspective. This is not a substitute for reviewer/QA; it is the handoff that tells reviewers what to scrutinize.

```markdown
## Reflection

### Spec Coverage
- AC-001: [implemented in `path` / not applicable / missing]
- AC-002: [implemented in `path` / not applicable / missing]

### Assumptions Made
- [assumption] — [low-risk proceeded / high-risk approved / unresolved]

### Scope Check
- Built only requested scope: yes/no
- Scope changes approved by user: [list or none]

### Known Weak Spots
- [edge case, risk, or area reviewers should inspect]

### Questions for User
- [behavior-affecting question, or "None"]
```

If Questions for User is not "None", STOP and ask before Phase 7. Otherwise continue.
</phase>

---

## Phase 7: Review + QA

<phase name="review-qa">
Run independent verification after reflection.

### Default path
Use the existing reviewer + QA teammates:
1. Reviewer verifies spec compliance, scope discipline, code quality, and reference integrity.
2. QA runs lint, typecheck, and tests.
3. If UI files changed, run browser testing in this phase: page loads, elements visible, interactions work, no console errors.
4. Fix findings through the implementer loop, then re-run the failed checks.

### Review council triggers
Use a risk-triggered review council instead of only the default reviewer when any condition is true:
- Auth, authorization, security, privacy, payments, or user data is involved
- Database migration, destructive operation, or external side effect is involved
- A public API contract or shared type changes
- A new dependency is added
- The feature is cross-layer or cross-repo
- The user asks for "thorough" review

When triggered, spawn multiple reviewer teammates using the existing reviewer agent with role-specific prompts:
- Correctness reviewer: logic, race conditions, async, edge cases
- Architecture reviewer: layering, contracts, file ownership, maintainability
- Security reviewer: input validation, auth, secrets, data exposure
- Test coverage reviewer: missing tests, mocks, failure paths
- Quality reviewer: naming, duplication, scope creep, stale references

Dispatch council reviewers in one gate, wait for all findings, dedupe by severity, then send consolidated must-fix items to implementers. Do not ask between reviewer lenses.
</phase>

---

## Phase 8: Commit / PR-ready

<phase name="commit">
1. Review all changes: `git status`, `git diff --stat`
2. Generate commit message: `type(scope): description`
3. Stage and commit unless the user requested PR-ready only: `git add -A && git commit`
4. If commit is skipped, report terminal state `pr-ready` with exact changed files and verification results
5. Report discovered issues (things outside scope that teammates noticed)

Do not shut down the team yet if wrapup needs final facts from a teammate.
</phase>

---

## Phase 9: Wrapup

<phase name="wrapup">
Capture what changed and what the next session should know. If a spec file was used, append or update a wrapup section and set its frontmatter status to `complete` or `implemented`.

```markdown
## Wrapup

### What shipped
- [user-facing or developer-facing change]

### Verification
- lint: [command + status]
- typecheck: [command + status]
- tests: [command + status]
- browser / CLI / proof artifacts: [status]

### Lessons
- [lesson future agents should reuse, or "None"]

### Assumptions Validated / Invalidated
- [assumption] — [validated / invalidated / still open]

### Follow-ups
- [item, owner if known]

### Ship Handoff
- deploy: [needed / not needed / command]
- smoke test: [needed / not needed / command]
- rollback: [how to revert]
- monitoring: [logs, metrics, errors, user signal]
```

Terminal state must be one of: `committed`, `pr-ready`, `blocked`, or `failed`.

After wrapup, shut down all teammates via `shutdown_request`, then call `TeamDelete`.

```
## Feature Complete

**Terminal State:** [committed / pr-ready / blocked / failed]
**Feature:** [description]
**Branch:** [current branch]
**Commit:** [hash or n/a]
**Team Shape:** [FLAT / CROSS-LAYER]

**Build Loop:** [N] iterations, final decision: PASS
**Quality:** lint [status], typecheck [status], tests [passed/total]
**Reflection:** [questions none / questions answered]
**Review:** [default / council, findings fixed]
**Wrapup:** [lessons/follow-ups captured]
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
