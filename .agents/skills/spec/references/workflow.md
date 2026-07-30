# Spec workflow

## Contents

- [Tiers](#tiers)
- [Clarify](#clarify)
- [Template](#template)
- [Goal generation](#goal-generation)
- [Save and report](#save-and-report)
- [Error recovery](#error-recovery)

## Tiers

Match depth to criticality — low criticality means low control and more acceleration:

- **No spec** — small, unambiguous change (bug fix, copy tweak, single function). Recommend `$dev` directly and wait for confirmation; a spec here is overhead with no return.
- **Light spec** (default) — one self-contained feature with low blast radius. Requirement Contract plus a single phase. Target under ~80 lines.
- **Full spec** — touches auth, payments, user data, migrations, or public contracts; spans layers; or needs multiple phases. Adds the Architecture Plan and a phased breakdown. Target under ~300 lines. One feature per spec, always — if it wants to be bigger, split it.

State the tier and why in one line. Follow the user if they ask for more or less depth.

## Clarify

Accept a feature description, a path, or an `<adlc-handoff>` from the thread; inherit the handoff's hypothesis, assumptions, and human decision boundaries instead of re-asking. Ask at most four concise questions, and only where the answer changes the spec: product behavior, measurable success, scope boundary, or data/auth/migration/billing/deployment/public-contract behavior. For minor gaps, state your interpretation in one line and proceed.

Then ground in the codebase: read repository guidance, trace similar behavior, identify the smallest integration path. The spec must name real files and real commands, not placeholders. For a large unfamiliar repository, a read-only explorer subagent may gather at most five findings with paths.

**Approval gate (the only stop):** present the problem, acceptance criteria, non-goals, and phase list; wait for explicit approval or corrections before generating phases and saving.

## Template

Omit any subsection that would be empty — an empty heading is noise, not rigor.

````markdown
---
id: SPEC-[short-id]
feature: [feature-name]
status: draft        # draft → approved → in-progress → implemented
depth: light         # light | full
created: [YYYY-MM-DD]
updated: [YYYY-MM-DD]
component: [narrow area]
domain: [broad area]
stack: []
concerns: []
---

# Specification: [Feature Name]

## Requirement Contract

### Problem
[Problem, target user, and value — 2-3 sentences]

### Approach
[The chosen approach and why it beats the obvious alternative]

### Acceptance Criteria
- AC-001: [specific behavior, provable by a command's output]

### Non-Goals
- [explicit exclusion — the cheapest scope-creep prevention available]

### Assumptions
- [assumption] — [verified / likely / risk]

### Human Decision Boundaries
[Only when real ones exist: public contracts, destructive data actions, billing,
deployment — decisions the implementing agent must not make alone]

## Architecture Plan
*(full tier only)*

### Existing Patterns to Follow
- `[path]` — [pattern and relevance]

### Files to Create / Modify
- `[path]` — [create/modify, what and why]

### Contracts
[Payloads, schemas, shared types, or UI boundaries phases must agree on]

### Test Strategy
[What proves local behavior, contracts, and the user outcome]

### Risks
- [risk] — [mitigation, rollback, or explicit deferral]

---

# Phase N: [Name]

## Prerequisites
*(Phase 1+ only)* [Concrete artifacts that already exist]

## Scope
[One independently verifiable slice]

## Acceptance Criteria
- AC-0XX: [criteria owned by this phase; each criterion belongs to exactly one phase]

## Non-Goals (This Phase)
- [deferred or excluded]

## New Dependencies (verified [YYYY-MM-DD])
*(only packages first introduced or changed in this phase; omit when none)*
| Package | Version | Purpose | Authoritative source |
|---|---|---|---|

## Files
- `[path]` — [create/modify, what changes]

## Verification
- `[focused command]` exits 0 with [expected summary].
- `[regression command]` exits 0.

## Goal Condition

```text
/goal Implement Phase N from .context/specs/spec-[feature-name].md. Stop only
when every listed acceptance criterion is satisfied, each verification command
has succeeded with its output reported, and no files outside the phase scope
were changed. Stop earlier and report blocked if a command fails twice for the
same cause or a human-approval boundary is reached.
```

---
[repeat per phase; light specs have exactly one]

## Wrapup
*(appended by $dev after implementation)*
````

Dependency rules: verify each new dependency's stable version from its official registry or documentation and record the date and link; never fabricate a version or signature; avoid adding a dependency the repository or platform already provides. Do not assign the same file to two writers across phases.

A purely visual criterion needs an automated browser or accessibility assertion when available; otherwise label it manual rather than inventing proof. End with a polish phase only when cleanup or full-suite verification is genuinely required — no ceremonial phases.

## Goal generation

Every phase gets a Goal Condition block. Offer to activate a native `/goal` only for a user-requested long-running run; do not create or activate one automatically.

## Save and report

1. Confirm `.context/` is covered by the repository's ignore rules; ask before changing ignore policy.
2. Save to `.context/specs/spec-[feature-name].md` with status `approved` or `ready-for-dev`.
3. Do not stage or commit the generated spec unless the user explicitly asks to promote it.
4. Report tier, phase count, path, and next commands:

```text
$dev Implement Phase 1 from .context/specs/spec-[feature-name].md.
$dev Implement all phases from .context/specs/spec-[feature-name].md and leave the result PR-ready.
```

The spec is a living document: `$dev` updates its status and appends a Wrapup, and mid-implementation reality can revise it — the spec should read true after the work, not preserve the original guess.

## Error recovery

- Rejected contract: revise and re-present; the approval gate repeats until approved.
- Codebase blocker: present the evidence and options; wait for the product decision.
- Dependency source unavailable: mark the dependency unverified and flag it at the approval gate rather than silently proceeding.
- Oversized phase: split at an independently testable boundary and update prerequisites.
- Context pressure: retain the approved contract, phase list, and user decisions; discard raw research output.
