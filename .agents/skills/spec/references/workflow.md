# Spec workflow

## Contents

- [Input and gates](#input-and-gates)
- [Phase 1: Clarify](#phase-1-clarify)
- [Phase 2: Requirement Contract](#phase-2-requirement-contract)
- [Phase 3: Architecture Plan](#phase-3-architecture-plan)
- [Phase 4: Implementation phases](#phase-4-implementation-phases)
- [Save and report](#save-and-report)
- [Error recovery](#error-recovery)

## Input and gates

Accept a feature description, a path, or an `<adlc-handoff>` from the thread. If there is no usable input, ask what should be specified.

Run this sequence without reordering:

```text
Clarify
  -> Requirement Contract
  -> Requirement Validation
  -> explicit approval
  -> Architecture Plan
  -> Architecture Validation
  -> self-contained implementation phases
  -> save
```

Stop after Clarify when answers are required. Stop after Requirement Validation until the user explicitly approves the contract. Architecture Validation is an internal quality gate; when it passes, continue directly to phase generation.

## Phase 1: Clarify

Extract the core problem, target user, desired outcome, boundaries, integrations, proof expectations, and human decision boundaries. Ask no more than five concise questions, and fewer when the handoff already answers them.

Questions must materially affect at least one of:

- product behavior or target user;
- measurable success;
- in-scope or excluded work;
- data, auth, migration, billing, deployment, or public contract behavior;
- evidence needed to accept the feature.

State the current interpretation. If the request is too small to benefit from a spec, recommend `$dev` and wait for confirmation. If it is too large, propose a coherent phase boundary without discarding the user's larger goal.

## Phase 2: Requirement Contract

Draft the global contract without implementation tasks:

```markdown
---
id: SPEC-[short-id]
feature: [feature-name]
status: draft
created: [YYYY-MM-DD]
updated: [YYYY-MM-DD]
component: [narrow area]
domain: [broad area]
stack: []
concerns: []
tags: []
---

# Specification: [Feature Name]

## Requirement Contract

### Problem
[Problem, target user, and value]

### Hypothesis
We believe [change] will improve [outcome] for [target user] by [mechanism].

### Goals
1. [Measurable goal]

### Success Metrics
- [ ] SC-001: [observable end-to-end outcome]

### Acceptance Criteria
- [ ] AC-001: [specific testable behavior]

### Assumptions
| Assumption | Status | Validation path |
|---|---|---|
| [assumption] | verified / likely / risk | [proof or approval needed] |

### Responsibility Model
| Decision or action | Agent may decide? | Human approval required? | Notes |
|---|---|---|---|
| Reversible implementation detail within approved scope | yes | no | Follow repository patterns |
| Public contract, destructive data action, billing, or deployment | no | yes | Include rollback when relevant |

## Technical Stack
[Existing known stack; do not invent new dependencies]

## Non-Goals (Global)
1. [Explicit exclusion]

## Requirement Validation

Status: PASS / NEEDS REVISION / BLOCKED

- [ ] Problem and target user are explicit.
- [ ] Hypothesis and success metrics are testable.
- [ ] Acceptance criteria are observable.
- [ ] Non-goals prevent scope creep.
- [ ] Assumptions have validation paths.
- [ ] Human approval boundaries are explicit.
- [ ] No unresolved blocker remains.

## Open Questions
- [Question or None]

## Planned Phases
| Phase | Name | User stories | Priority |
|---|---|---|---|
| 0 | [first independently useful slice] | US1 | P0 |
```

Revise until Requirement Validation is PASS. Present a concise contract summary and ask the user to reply with approval or corrections. Do not analyze detailed architecture, generate tasks, or save a ready-for-development spec before approval.

## Phase 3: Architecture Plan

After approval:

1. Read repository guidance, manifests, relevant implementation files, and tests.
2. Trace similar behavior and identify the smallest integration path.
3. For a large or unfamiliar repository, ask a read-only explorer subagent for at most five findings with paths and line numbers. Wait for and summarize the result.
4. Identify new or changed external dependencies by phase.
5. Verify each such dependency's stable version from its official registry or project documentation and record the verification date and link.
6. Read authoritative documentation for core APIs. Use available official documentation tools, MCP servers, or web search; never fabricate a version or method signature.
7. Avoid adding a dependency when the repository or platform already provides the capability.

Add:

```markdown
## Architecture Plan

### Existing Patterns to Follow
- `[path]` — [pattern and relevance]

### Project Structure
[Touched directory tree]

### Integration Points
- [boundary] — [contract]

### Files to Modify
- `[path]` — [reason]

### Files to Create
- `[path]` — [purpose]

### Data / API / UI Contracts
- [payload, schema, state, CLI, or UI boundary]

### Test Strategy
- Unit: [behavior]
- Integration: [contract]
- E2E, browser, or CLI: [user outcome]

### Risk Plan
- [risk] — [mitigation, rollback, or deferral]

### Key Architectural Decisions
- [decision] — [rationale]

### Task Graph
- T001 [task]
- T002 [task] depends on T001

## Architecture Validation

Status: PASS / NEEDS REVISION / BLOCKED

- [ ] Every acceptance criterion maps to one or more tasks.
- [ ] The task graph is valid and phase ordering is explicit.
- [ ] File ownership is unambiguous.
- [ ] Tests cover happy paths, failure paths, and integration contracts.
- [ ] New dependency versions and documentation are verified.
- [ ] Risks have mitigation, rollback, or explicit deferral.
- [ ] Responsibility Model boundaries remain intact.
```

Revise internally until Architecture Validation is PASS. Ask the user only when new evidence exposes a product decision or authority boundary.

## Phase 4: Implementation phases

Generate every row from Planned Phases. Each phase must stand alone:

````markdown
---

# Phase N: [Name]

## Prerequisites
[Required for Phase 1 and later: concrete artifacts that already exist]

## Scope
[One independently verifiable slice]

## User Stories
### USX: [Title] (Priority: PN)
As a [user], I want [action] so that [value].

Acceptance Criteria:
- Given [state], when [action], then [observable result].

## Functional Requirements
- FR-XXX [USX]: The system MUST [behavior].

## Non-Goals (This Phase)
1. [Deferred or excluded behavior]

## Dependencies (verified [YYYY-MM-DD])
Only dependencies first introduced or changed in this phase.

| Package | Version | Purpose | Authoritative source |
|---|---|---|---|
| [name] | [exact version] | [reason] | [link] |

## Implementation Guidance
- [Repository pattern, signature, error behavior, or configuration]

## Tasks
- T0XX [USX] [task]
- T0XX [P] [USX] [independent task]
- T0XX [USX] [task] (depends on T0XX)

## Files to Create
- `[path]` — [purpose]

## Files to Modify
- `[path]` — [change]

## Success Criteria
1. [Observable result]

## Proof Artifacts
- Test, CLI output, browser assertion, screenshot, or diff that proves the result.

## Verify Before Proceeding
- [ ] `[focused command]` exits 0 with [expected summary].
- [ ] `[regression command]` exits 0.
- [ ] Required proof artifact is captured.

## Goal Condition

```text
/goal Implement Phase N from .context/specs/spec-[feature-name].md. Stop only
when every listed acceptance criterion is satisfied, each phase verification
command has succeeded, the proof is reported, and no files outside the phase
scope were changed. Stop earlier and report blocked if a command fails twice for
the same cause or a human-approval boundary is reached.
```
````

Use `[P]` only for truly independent tasks. Do not assign the same file to two writers. A purely visual criterion needs an automated browser or accessibility assertion when available; otherwise label it manual rather than inventing proof.

End with a small polish phase only when cleanup, documentation, or full-suite verification is genuinely required. Do not create ceremonial phases with no user or quality value.

## Save and report

1. Confirm `.context/` is covered by the repository's ignore rules. If it is not, ask before changing ignore policy when that would affect the repository.
2. Create `.context/specs/` as needed.
3. Save the complete document to `.context/specs/spec-[feature-name].md`.
4. Set status to `approved` or `ready-for-dev` as appropriate.
5. Do not stage or commit the generated spec unless the user explicitly asks to promote it.
6. Report phase count, validation status, path, and next commands:

```text
$dev Implement Phase 0 from .context/specs/spec-[feature-name].md.
$dev Implement all phases from .context/specs/spec-[feature-name].md and leave the result PR-ready.
```

Offer the phase's `/goal` block only for a user-requested long-running run. Do not create or activate a goal automatically.

## Error recovery

- Rejected contract: revise Phase 2 and run Requirement Validation again.
- Codebase blocker: present the evidence and options; wait for the product decision.
- Dependency source unavailable: mark the dependency unverified and keep validation from passing until verified or explicitly accepted.
- Architecture validation failure: revise the architecture before task generation.
- Oversized phase: split at an independently testable boundary and update prerequisites.
- Context pressure: retain the approved contract, architecture, task graph, and user decisions; discard raw research output.
