# Dev workflow

## Contents

- [Modes](#modes)
- [Phase 1: Preflight](#phase-1-preflight)
- [Phase 2: Explore](#phase-2-explore)
- [Phase 3: Clarify and plan](#phase-3-clarify-and-plan)
- [Phase 4: Implement](#phase-4-implement)
- [Phase 5: Reflect](#phase-5-reflect)
- [Phase 6: Review and QA](#phase-6-review-and-qa)
- [Phase 7: Deliver and wrap up](#phase-7-deliver-and-wrap-up)
- [Sweep mode](#sweep-mode)
- [Unattended mode](#unattended-mode)
- [Error recovery](#error-recovery)

## Modes

Detect these dimensions independently:

- **Ad hoc**: a bounded change without a saved spec.
- **Spec-backed**: the request names a file under `.context/specs/` or another approved contract.
- **Single-phase**: the request names one phase or task slice.
- **Sweep**: the request asks for all or remaining phases and names no single phase.
- **Interactive**: user input is available; default.
- **Unattended**: the prompt explicitly requests unattended local execution.
- **PR-ready**: leave verified changes uncommitted; default.
- **Commit requested**: create commits only within the scope the user named.

Do not infer unattended operation, commits, deployment, pushes, or pull-request creation from a generic implementation request.

## Phase 1: Preflight

1. Read applicable `AGENTS.md` files and repository guidance.
2. Run `git status --short --branch` when the workspace is a Git repository.
3. Record every pre-existing modified, staged, and untracked path. Treat these as user-owned unless the request clearly includes them.
4. Read the relevant spec or request completely.
5. In Spec-backed mode, verify Requirement Validation and Architecture Validation are PASS or explicitly accepted. If not, stop for direction.
6. Detect manifests, stack, and configured lint, typecheck, test, build, browser, or CLI verification commands.
7. Identify destructive operations, external side effects, and human approval boundaries before editing.

Never discard, overwrite, stage, or commit unrelated pre-existing changes. If a requested file already has overlapping user edits, inspect the diff and preserve them; ask only when safe integration is ambiguous.

## Phase 2: Explore

Read the actual entry points, related implementations, tests, and callers. Search for existing utilities before creating new files or dependencies.

For a large or unfamiliar change, ask a built-in read-only explorer subagent:

```text
Inspect the repository for this exact implementation request. Return at most five
findings: the existing behavior, patterns to follow, files and tests likely
touched, verification commands, and material concerns. Cite paths and line
numbers. Do not edit anything.
```

Wait for the result and summarize it. Do not delegate when the main thread can establish the file map cheaply.

Create an ownership map:

```text
Writer owns: [implementation and directly related test files]
Reviewer reads: [entire scoped diff and contract]
QA runs: [exact commands]
User-owned paths to preserve: [pre-existing changes]
```

Use one writer unless two implementation slices have no shared files, no ordering dependency, and a clear contract between them. Parallel read-heavy work is preferred over parallel writes.

## Phase 3: Clarify and plan

State:

- feature and mode;
- approved scope and acceptance criteria;
- files likely created or modified;
- verification commands;
- assumptions and approval boundaries.

Ask at most three questions only when the answer materially changes behavior, scope, auth, data, migration, billing, destructive action, public contracts, deployment, or external side effects. Otherwise record the smallest reversible interpretation and proceed.

Maintain one main-thread plan. For each item include the deliverable, owned files, dependency, and proof. In Spec-backed mode, reuse the approved task IDs and acceptance criteria instead of inventing a competing plan.

If a native `/goal` is already active because the user explicitly requested it, align the plan with that objective and stopping condition. Do not create a goal merely because the work is large.

## Phase 4: Implement

Choose the writer:

- Main thread for small and medium changes or changes requiring tight user interaction.
- One worker subagent for a large, well-bounded slice with complete context and file ownership.
- Two workers only when the ownership rule in Phase 2 is satisfied.

Every writer receives the full request or approved phase, relevant repository patterns, exact owned files, acceptance criteria, verification commands, and this rule: stop and return a blocker before crossing a human approval boundary.

Use this loop, with at most five meaningful iterations:

1. Implement the smallest coherent slice.
2. Add or update behavior-focused tests for non-trivial logic.
3. Run the narrowest relevant check.
4. Inspect the diff for omissions, unrelated edits, and stale references.
5. Decide:
   - PASS: scoped behavior and focused checks succeed.
   - RETRY: a specific fix is known.
   - BLOCKED: progress requires new authority, unavailable state, or a different contract.

After the same failure twice, reassess the cause instead of repeating the command. Never loosen tests or delete coverage merely to make the suite green.

When a worker subagent writes code, wait for its result and independently inspect the resulting files and diff. Subagent self-assessment is not proof.

## Phase 5: Reflect

Before independent review, write:

```markdown
## Reflection

### Contract coverage
- AC-001: [implemented at path / missing / not applicable]

### Assumptions
- [assumption] — [validated / still open / invalidated]

### Scope check
- Requested scope only: yes / no
- User-owned changes preserved: yes / no

### Known weak spots
- [risk, edge case, or None]

### Questions requiring the user
- [behavior-affecting question or None]
```

In Interactive mode, stop for a behavior-affecting question. In Unattended mode, continue only for low-risk reversible assumptions; high-risk uncertainty becomes `blocked`.

## Phase 6: Review and QA

Run independent verification after reflection.

### Default review

Ask one read-only reviewer subagent for non-trivial work, or run a distinct skeptical pass in the main thread when delegation is unavailable:

```text
Review the actual scoped diff against the supplied contract. First verify every
acceptance criterion and identify scope creep. Then inspect correctness, failure
paths, security, maintainability, tests, and stale references. Return only
actionable findings with severity and file:line evidence. Do not edit anything.
```

Fix must-fix findings through the single writer, then re-review the affected areas.

### Risk-triggered review

Use a risk-triggered review council when the change involves auth, authorization, security, privacy, user data, migrations, payments, destructive operations, public contracts, new dependencies, cross-layer behavior, external side effects, or a user request for thorough review.

Ask bounded parallel read-only subagents for only the relevant lenses:

- correctness and concurrency;
- architecture and integration contracts;
- security and data exposure;
- test coverage and failure paths;
- scope, quality, and stale references.

Wait for all requested results, deduplicate findings by severity, and send one consolidated must-fix set to the writer. Do not parallelize lenses that add no distinct evidence.

### QA

Run the repository's configured focused tests first, then applicable lint, typecheck, full tests, build, browser, CLI, or proof commands. A QA subagent may run independent commands and summarize results, but must not edit implementation files.

For each command report the command, exit status, and meaningful summary. If a check cannot run, state why; do not call it passing.

## Phase 7: Deliver and wrap up

Review `git status`, the scoped diff, and the diff stat. Confirm user-owned paths remain preserved.

Commit only when the user explicitly requested a commit. Before committing, stage only scoped paths, review the staged diff, use the repository's commit convention, and report the hash. Otherwise leave the result `pr-ready` and name the changed files.

Do not push, deploy, open a pull request, or perform external side effects unless separately authorized.

Produce:

```markdown
## Wrapup

### What shipped
- [behavior]

### Verification
- `[command]`: [pass / fail / not run, summary]

### Review
- [default / risk-triggered review, findings resolved or outstanding]

### Assumptions validated or invalidated
- [assumption and result]

### Follow-ups
- [item or None]

### Ship handoff
- deploy: [needed / not needed / requires approval]
- smoke test: [command]
- rollback: [revert strategy]
- monitoring: [signal]
```

End with exactly one terminal state:

- `committed`: requested commit exists and checks are reported.
- `pr-ready`: scoped verified changes are uncommitted and ready for human review.
- `blocked`: progress requires authority, external state, or a contract decision.
- `failed`: the workflow encountered a terminal execution failure and leaves a clear recovery path.

## Sweep mode

For a Spec-backed request covering all or remaining phases:

1. Read the whole spec and enumerate phases in dependency order.
2. Explore and clarify once for the feature.
3. Keep an explicit ordered checklist in the main-thread plan.
4. For each incomplete phase: implement, run focused checks, reflect, review, and QA before moving forward.
5. Stop before a dependent phase when the current phase is blocked or a human approval boundary is reached.
6. Default to one final PR-ready worktree. Create per-phase commits only when explicitly requested.
7. Run the full regression set and one combined wrapup after the last phase.

If the user explicitly invokes native `/goal`, use the goal's objective and stopping condition to sustain the sweep across turns. The skill remains the quality workflow; the goal is only the persistence layer.

## Unattended mode

Unattended means no new user answer can be obtained during the run:

- Do not stop for low-risk reversible ambiguity; choose the smallest interpretation and record it.
- Do not silently cross auth, user-data, migration, billing, destructive, public-contract, deployment, or external-side-effect boundaries.
- At a high-risk boundary, leave a clean scoped state when possible and finish `blocked`.
- Never wait indefinitely. Bound subagent tasks and verification loops.
- Do not infer permission to commit, push, deploy, or create a pull request.

This mode covers local non-interactive execution only. Distribution to remote runners is outside this workflow.

## Error recovery

- Subagent stalls: inspect status, steer it once, then stop it and continue or use a replacement.
- File ownership conflict: stop both writers, choose one owner, inspect the diff, and resume sequentially.
- Review loop does not converge: after three review cycles, report the concrete disagreement or blocker.
- Test failure outside scope: prove whether it is pre-existing; do not modify unrelated code without approval.
- Overlapping dirty file: preserve both intents when safe; otherwise stop with the exact conflict.
- Missing tool or dependency: use a repository-native alternative or report the missing prerequisite; do not install unrelated global tooling silently.
- Context pressure: retain the approved contract, current plan, dirty-file inventory, diff summary, verification results, and blockers.
