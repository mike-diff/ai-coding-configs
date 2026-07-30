# /dev — Full Workflow

Phases 1-3 set up the work, 4-6 do and check it, 7-8 land it. In spec sweep mode,
phases 4-7 repeat per spec phase. Skip what the task doesn't need — a one-file ad hoc
fix doesn't need an Explore pass or a reflection section; a cross-layer feature needs
all of it. The gates that are never skipped: the verify gate (Phase 5) and the
terminal-state report (Phase 8).

## Phase 1: Orient

Parse the request:
1. **Mode** — Spec-backed mode if it includes `@.context/specs/...` (single-phase if a
   `Phase N` is named, sweep otherwise); otherwise ad hoc.
2. **Scope and type** — what's being built, which layers it touches.
3. **Stack** — read `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod`;
   identify the lint, typecheck, test, and build commands you'll use in Phase 5.

Spec-backed mode: read the spec fully — Requirement Contract, Architecture Plan (if
present), phases, goal conditions, Safe Parallelization guidance. The spec is the
contract; execution details may flex, scope may not.

## Phase 2: Explore

When the touched area is unfamiliar or wide, delegate a survey to the built-in
**Explore** subagent: similar features, patterns to follow, files to modify or create,
integration points, concerns. When you already know the ground (or the spec's
Architecture Plan already maps it), skip this phase — re-deriving a known file map is
waste.

## Phase 3: Clarify

Present your understanding before building: a short summary, the files you expect to
touch, and any genuine questions (scope boundary, edge cases, acceptance criteria).
Wait for answers or "proceed" before Phase 4.

Spec-backed: the spec already answered most of this — clarify only real gaps or
contradictions between spec and codebase, once for the whole spec (not per phase).

## Phase 4: Build

Implement. Default is direct: you write the code, matching existing patterns, minimal
diffs, tests alongside.

Delegate within this phase when it genuinely pays:
- **Parallel independent tracks** (per the spec's Safe Parallelization section, or
  clearly independent ad hoc work): `/multitask` or Build in Parallel with one
  implementer subagent per track. Each dispatch prompt must be self-contained —
  subagents get no conversation history — and must state the track's file-ownership
  globs. No two writers on one file, ever. Define shared contracts (types, API shapes)
  yourself before splitting the work.
- Long or verbose check runs are naturally isolated by the built-in **Bash** subagent;
  don't paste walls of tool output into the conversation.

High-risk assumptions — auth, user data, migrations, destructive operations, billing,
external side effects, public API contracts, deployment — are never resolved silently:
stop and ask unless the spec explicitly authorizes the action.

## Phase 5: Verify

The gate is external evidence, not self-assessment. Run it after the build settles, and
re-run the failed parts after every fix until clean:

1. **Checks** — project lint, typecheck, tests (the commands from Phase 1). Failures
   come back to Phase 4 as concrete fix items.
2. **Fresh-context review** — `/spec-reviewer` reads the actual diff against the
   requirements with no memory of writing it. It is briefed for coverage over
   filtering: every issue reported with severity and confidence. You fix what's real,
   note what isn't.
3. **UI changes** — exercise the changed flow with the built-in **Browser** subagent
   (page loads, interactions work, no console errors) when the project has a runnable
   UI.

### Review council triggers

Escalate from the single reviewer to parallel review when the change involves auth,
payments, user data, migrations or destructive operations, public API or shared
contract changes, a new dependency, cross-layer work, or when the user asks for a
thorough review: dispatch `/spec-reviewer` in parallel with distinct lens briefs —
correctness, security, architecture, test coverage (readonly subagents, one Task call
each). Dedupe findings by severity, fix the must-fix items, re-run the failed checks.
Don't pause between lenses.

After 3 attempts at the same failing gate, stop looping: re-assess the approach, and
if it's genuinely stuck, that's `blocked`, not retry number four.

## Phase 6: Reflect

An honest handoff, not a ritual. Cover only what has content:

- **Coverage** — each acceptance criterion: implemented where, or explicitly not.
- **Assumptions made** — and their risk level.
- **Scope check** — anything built beyond the request, and why.
- **Questions for the user** — behavior-affecting only; ask before committing.

## Phase 7: Commit / PR-ready

1. Review the full diff (`git status`, `git diff --stat`).
2. Commit on the current branch using the repo's commit style, unless the user asked
   for PR-ready only — then report `pr-ready` with exact changed files and
   verification results.
3. Note discovered out-of-scope issues for the report.

## Phase 8: Wrapup

Spec-backed: update the spec file — status to `implemented` (or `in-progress`
mid-sweep), append a Wrapup section (what shipped, verification results, lessons,
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
2. Run Explore and Clarify once for the whole spec. Clarify stops for input exactly
   once; after "proceed", no more pauses between phases.
3. Keep an ordered phase checklist in your working notes or the spec file (Cursor has
   no shared task list): phase → status. On resume after an interruption, reconcile
   against git history — committed phases stay committed; continue at the first
   incomplete phase.

### Per phase, in order
1. Skip phases already complete; mark the current one in progress in your checklist.
2. Run Build → Verify → Reflect scoped to this phase's acceptance criteria.
3. **Commit at the phase boundary** — each phase is an independent, revertible step;
   don't defer commits to the end. (Exception: an explicit PR-ready request carries
   the tree across phases and reports `pr-ready` once — losing resume-on-interruption.)
4. Continue to the next phase without pausing.

### Halt the sweep
Autonomy doesn't mean barreling through failure. Halt — don't start dependent phases —
when a phase ends `blocked`, the verify gate can't pass after re-assessment, or
high-risk scope surfaces (auth, data, migrations, destructive ops, billing, public
contracts) that the spec doesn't explicitly authorize. On halt: report which phases
committed and which remain, then wait for the user.

### Operational guardrails
- Parallel tracks within a phase follow the spec's Safe Parallelization section only —
  don't invent parallelism the spec didn't mark safe.
- Cloud agents don't have subagent delegation: a sweep handed to a cloud agent runs
  single-agent — the workflow above degrades gracefully since direct build is already
  the default, but don't count on `/multitask` there.
- Prefer many small verified commits over one large one: git history is the sweep's
  externalized state, and it's what makes an interrupted run resumable.

## Error recovery

- A subagent goes off track or returns nothing useful: refine the dispatch prompt and
  re-run, or do that piece directly — don't wait on a lost cause.
- Verify gate keeps failing on the same issue: after 3 attempts, re-assess the
  approach instead of retrying; escalate or block.
- File conflict between parallel tracks: stop both, reassign ownership explicitly,
  re-run the affected track.
- Interrupted sweep: reconcile the checklist against git history and resume from the
  first incomplete phase.
