# /dev — Full Workflow

Phases 1-3 set up the work, 4-6 do and check it, 7-8 land it. In spec sweep mode,
phases 4-7 repeat per spec phase. Skip what the task doesn't need — a one-file ad hoc
fix doesn't need an Explore subagent or a reflection section; a cross-layer feature
needs all of it. The gates that are never skipped: the verify gate (Phase 5) and the
terminal-state report (Phase 8).

## Phase 1: Orient

Parse the request:
1. **Mode** — Spec-backed if it includes `@.context/specs/...` (single-phase if a
   `Phase N` is named, sweep otherwise). Unattended if `--unattended` / "unattended" /
   env `DEV_UNATTENDED=1`.
2. **Scope and type** — what's being built, which layers it touches.
3. **Stack** — read `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod`;
   identify the lint, typecheck, test, and build commands you'll use in Phase 5.

Spec-backed mode: read the spec fully — Requirement Contract, Architecture Plan (if
present), phases, goal conditions. The spec is the contract; execution details may
flex, scope may not.

## Phase 2: Explore

When the touched area is unfamiliar or wide, delegate a survey to an Explore subagent:
similar features, patterns to follow, files to modify or create, integration points,
concerns. Ask for a file map grouped by layer. When you already know the ground (or the
spec's Architecture Plan already maps it), skip this phase — re-deriving a known file
map is waste.

## Phase 3: Clarify

Present your understanding before building: a short summary, the files you expect to
touch, and any genuine questions (scope boundary, edge cases, acceptance criteria).
Use AskUserQuestion for questions that change what you build.

- **Interactive:** wait for answers or "proceed" before Phase 4.
- **Unattended:** don't stop. Take the simplest reasonable interpretation, record it
  under Assumptions (surfaced again in Phase 6), and proceed.
- **Spec-backed:** the spec already answered most of this — clarify only real gaps or
  contradictions between spec and codebase, once for the whole spec (not per phase).

## Phase 4: Build

Implement. Default is direct: you write the code, matching existing patterns, minimal
diffs, tests alongside.

Delegate within this phase when it genuinely pays:
- **Parallel independent file sets** (e.g. backend + frontend with a shared contract):
  spawn named implementer subagents, each with an explicit file-ownership list — no two
  writers on one file — and worktree isolation if they run concurrently. Define the
  shared contract (types, API shape) yourself first so both sides agree.
- **Track multi-step work** with TaskCreate/TaskUpdate when coordinating subagents or
  sweeping phases; skip task bookkeeping for work you're doing directly in one pass.

High-risk assumptions — auth, user data, migrations, destructive operations, billing,
external side effects, public API contracts, deployment — are never resolved silently:
interactive, stop and ask; unattended, halt with `blocked` unless the spec explicitly
authorizes the action.

## Phase 5: Verify

The gate is external evidence, not self-assessment. Run it after the build settles, and
re-run the failed parts after every fix until clean:

1. **Checks** — project lint, typecheck, tests (the commands from Phase 1). Failures
   come back to Phase 4 as concrete fix items.
2. **Fresh-context review** — a reviewer subagent that reads the actual diff against
   the requirements with no memory of writing it. Brief it for coverage over filtering:
   report every issue found with severity and confidence; spec compliance first
   (missing requirements, scope creep), then code quality. You fix what's real,
   note what isn't.
3. **UI changes** — exercise the changed flow in a browser (page loads, interactions
   work, no console errors) when the project has a runnable UI.

### Review council triggers

Escalate from the single reviewer to a parallel review council when the change involves
auth, payments, user data, migrations or destructive operations, public API or shared
contract changes, a new dependency, cross-layer work, or when the user asks for a
thorough review. Run the council as parallel fresh-context reviewer subagents with
distinct lenses — correctness, security, architecture, test coverage — or as a Workflow
(review → adversarial verify) when available. Dedupe findings by severity, fix the
must-fix items, re-run the failed checks. Don't pause between lenses.

After 3 attempts at the same failing gate, stop looping: re-assess the approach,
and if it's genuinely stuck, that's `blocked`, not retry number four.

## Phase 6: Reflect

An honest handoff, not a ritual. Cover only what has content:

- **Coverage** — each acceptance criterion: implemented where, or explicitly not.
- **Assumptions made** — especially unattended-mode interpretations.
- **Scope check** — anything built beyond the request, and why.
- **Questions for the user** — behavior-affecting only.

Interactive: if there are behavior-affecting questions, ask before committing.
Unattended: carry them into the wrapup / PR body as notes and continue.

## Phase 7: Commit / PR-ready

1. Review the full diff (`git status`, `git diff --stat`).
2. Commit on the current branch using the repo's commit style, unless the user asked
   for PR-ready only — then report `pr-ready` with exact changed files and
   verification results.
3. Note discovered out-of-scope issues for the report.

## Phase 8: Wrapup

Spec-backed: update the spec file — status to `implemented` (or `in-progress` mid-sweep),
append a Wrapup section (what shipped, verification results, lessons,
assumptions validated or invalidated, follow-ups).

Report:

```markdown
## Feature Complete
**Terminal state:** committed / pr-ready / blocked / failed
**Commit(s):** [hashes or n/a]
**Verification:** lint [status] · typecheck [status] · tests [passed/total] · review [clean / N findings fixed]
**Assumptions / questions:** [list or none]
**Follow-ups:** [list or none]
```

---

## Spec Sweep Mode

Trigger: a spec path with no single phase named — `/dev @.context/specs/spec-X.md`,
`/dev "all phases" @<spec>`. You orchestrate every phase end-to-end autonomously.

### Setup (once)
1. Read the spec fully; enumerate phases with acceptance criteria.
2. Run Explore and Clarify once for the whole spec. Interactive: Clarify stops for
   input exactly once; after "proceed", no more pauses between phases.
3. Create one task per spec phase (TaskCreate), dependency-chained in order. If tasks
   exist from an interrupted sweep, reconcile: keep `completed`, create missing, resume
   at the first incomplete phase.

### Per phase, in order
1. Skip phases already `completed`; mark the current one `in_progress`.
2. Run Build → Verify → Reflect scoped to this phase's acceptance criteria.
3. **Commit at the phase boundary** — each phase is an independent, revertible step;
   don't defer commits to the end. (Exception: an explicit PR-ready request carries the
   tree across phases and reports `pr-ready` once — losing resume-on-interruption.)
4. Mark the phase `completed` and continue without pausing.

### Halt the sweep
Autonomy doesn't mean barreling through failure. Halt — don't start dependent phases —
when a phase ends `blocked`, the verify gate can't pass after re-assessment, or
high-risk scope surfaces (auth, data, migrations, destructive ops, billing, public
contracts) that the spec doesn't explicitly authorize. On halt: mark the phase task
blocked, report which phases committed and which remain. Interactive: wait.
Unattended: post the blocker, leave the tree clean, end `blocked`.

### Operational guardrails (unattended sweeps)
- Cap spend on headless runs: `claude -p "/dev @<spec> --unattended" --max-budget-usd N`,
  plus `--max-turns` and a CI wall-clock timeout as backstops.
- Keep delegation flat (one level) in CI — see
  [unattended-ci.md](unattended-ci.md) for the verified constraints.
- Prefer many small verified commits over one large one: git history is the sweep's
  externalized state, and it's what makes an interrupted run resumable.

---

## Unattended Mode

Trigger: `--unattended` / "unattended" in the request, or env `DEV_UNATTENDED=1`.
Composes with ad hoc, spec-backed, and sweep.

Every human-input gate is replaced with an autonomous behavior:
- **Clarify** — don't stop; simplest reasonable interpretation, logged under Assumptions.
- **Reflect questions** — become notes in the wrapup / PR body.
- **Any halt-and-wait** — never wait: post the blocker (issue comment / wrapup), leave
  the working tree clean, end with terminal state `blocked`.

Halt (do not continue) only for genuinely destructive or irreversible scope — auth
changes, migrations, billing, data deletion, public API breaks — or a verify gate that
still fails after re-assessment. These bounds are what make it safe to suspend the
other gates.

## Error recovery

- Subagent goes off track or returns nothing useful: refine the brief and re-run, or do
  that piece directly — don't wait on a lost cause.
- Verify gate keeps failing on the same issue: after 3 attempts, re-assess the approach
  instead of retrying; escalate or block.
- File conflict between parallel subagents: stop both, reassign ownership explicitly,
  re-run the affected piece.
- Interrupted sweep: reconcile the task list (Setup step 3) and resume from the first
  incomplete phase — committed phases stay committed.
