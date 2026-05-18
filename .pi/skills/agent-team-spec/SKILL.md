---
name: agent-team-spec
description: Run the Agent Team spec workflow in pi for this repo. Use when turning a validated idea or ADLC handoff into a local, uncommitted spec with requirement validation, architecture validation, task graph and implementation phases.
---

# Agent Team Spec

Use this skill to run the Agent Team `/spec` workflow from pi while maintaining repo parity.

## Source of truth

The product workflow source of truth is:

- `.claude/skills/spec/SKILL.md`
- `.claude/skills/spec/references/workflow.md`
- `.cursor/skills/spec/SKILL.md`
- `.cursor/skills/spec/references/workflow.md`

Read those files when details matter. This pi skill is a maintainer/operator wrapper, not a fourth independent workflow implementation.

## Output path

Save generated specs to:

```text
.context/specs/spec-[feature-name].md
```

Before saving, confirm `.context/` is gitignored. Do not stage or commit generated specs by default. Only promote a spec to committed docs when the user explicitly asks.

## Required phases

1. Clarify
2. Requirement Contract
3. Requirement Validation
4. User approval gate
5. Architecture Plan
6. Architecture Validation
7. Self-contained task phases
8. Save

## Requirement Contract must include

- Problem
- Hypothesis
- Goals
- Success Metrics
- Acceptance Criteria
- Non-goals
- Assumptions with validation path
- Responsibility Model
- Open Questions

## Requirement Validation must include

```markdown
## Requirement Validation

Status: PASS / NEEDS REVISION / BLOCKED

- [ ] Problem and target user are explicit
- [ ] Hypothesis is testable
- [ ] Success metrics are measurable
- [ ] Acceptance criteria are observable
- [ ] Non-goals prevent scope creep
- [ ] Assumptions have validation paths
- [ ] Human approval boundaries are explicit
```

Stop for user approval after Requirement Validation unless the user explicitly pre-approved proceeding.

## Architecture Plan must include

- Existing patterns to follow
- Project structure
- Integration points
- Files to modify
- Files to create
- Data, API, or UI contracts
- Test strategy
- Risk plan
- Task graph
- Safe parallelization guidance when relevant

## Architecture Validation must include

```markdown
## Architecture Validation

Status: PASS / NEEDS REVISION / BLOCKED

- [ ] Every acceptance criterion maps to at least one task
- [ ] Tasks form a valid dependency graph
- [ ] File ownership is clear and no file has two implementer owners
- [ ] Test strategy covers happy path, failure path and integration contracts
- [ ] Dependency versions are pinned and docs references are recorded
- [ ] Risks have mitigation or explicit deferral
- [ ] Human approval boundaries from the Responsibility Model are still respected
```

Only proceed to task phases when Architecture Validation is PASS.

## Completion response

After saving, report:

```markdown
SPEC complete

File: .context/specs/spec-[feature-name].md
Status: [draft / approved / ready-for-dev]
Phases: [N]
Next: /skill:agent-team-dev "Implement Phase 1" @.context/specs/spec-[feature-name].md
```

## Guardrails

- Preserve the 3-command UX: discuss, spec and dev.
- Do not create ADLC command sprawl.
- Keep specs local and uncommitted unless explicitly promoted.
- If workflow semantics changed during the work, update Claude, plugin and Cursor surfaces, then run `./tests/workflow-contract.sh`.
