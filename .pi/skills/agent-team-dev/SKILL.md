---
name: agent-team-dev
description: Run the Agent Team dev workflow in pi for this repo. Use when implementing a validated feature or spec-backed phase with preflight, exploration, clarification, implementation, reflection, review, QA and wrapup.
---

# Agent Team Dev

Use this skill to run the Agent Team `/dev` workflow from pi while maintaining repo parity.

## Source of truth

The product workflow source of truth is:

- `.claude/skills/dev/SKILL.md`
- `.claude/skills/dev/references/workflow.md`
- `.cursor/skills/dev/SKILL.md`
- `.cursor/skills/dev/references/workflow.md`

Read those files when details matter. This pi skill is a maintainer/operator wrapper, not a fourth independent workflow implementation.

## Modes

### Spec-backed mode

Use when the request includes `@.context/specs/...`.

- Read the spec before implementation.
- Verify Requirement Validation and Architecture Validation status.
- Treat the spec as the contract.
- Do not expand scope without asking.
- Implement the requested phase or task graph slice.

### Ad hoc mode

Use for small validated changes without a spec.

- Explore the codebase first.
- Ask clarifying questions if acceptance criteria or boundaries are unclear.
- Keep scope minimal.

## Process

1. Preflight
   - Check `git status --short`.
   - Note pre-existing dirty files.
   - Restore or ignore `.claude/.logs/hooks.log` unless explicitly requested.
2. Explore
   - Read relevant files before editing.
   - Search for existing utilities and patterns.
3. Clarify
   - Ask before implementation if scope, behavior, data, auth, migrations, billing, deployment, or public API contracts are unclear.
4. Implement
   - Use test-first workflow for non-trivial code.
   - Make minimal focused changes.
   - Keep generated specs in `.context/specs/` uncommitted.
5. Reflect
   - Check spec coverage, assumptions, scope and weak spots.
6. Review and QA
   - Use focused review for low-risk work.
   - Use a risk-triggered review council for security, data, migrations, dependencies, public contracts, cross-layer work, or user-requested thorough review.
   - Run relevant validation commands.
7. Commit or PR-ready
   - Commit only if requested or appropriate for the task.
   - Otherwise report PR-ready state.
8. Wrapup
   - Capture what shipped, verification, lessons, assumptions, follow-ups and ship handoff.

## High-risk assumptions

Stop and ask before changing behavior involving:

- Product scope
- Auth or authorization
- User data or privacy
- Migrations or destructive operations
- Billing or payments
- External side effects
- Public API contracts
- Deployment

## Repo validation

After workflow config changes, run:

```bash
./tests/workflow-contract.sh
bash -n tests/workflow-contract.sh tests/smoke.sh scripts/sync-plugin.sh .claude/hooks/*.sh .cursor/hooks/*.sh plugins/agent-team/hooks/*.sh
git diff --check
```

When plugin behavior changes, run:

```bash
COMMAND_TIMEOUT_SECONDS=60 ./tests/smoke.sh
```

## Completion response

```markdown
DEV complete

Terminal state: [committed / pr-ready / blocked / failed]
Spec: [.context/specs/... or none]
Validation: [commands + status]
Review: [default / council]
Wrapup: [lessons and follow-ups captured]
```
