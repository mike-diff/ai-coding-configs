# Spawn Schemas

> **Canonical source:** These are minimal, reusable templates for **ad-hoc** team
> spawning. The `/agent-team:dev` and `/agent-team:discuss` skills carry the **authoritative**,
> context-specific spawn prompts (with phase instructions, output budgets, and
> mode-specific guidance) in `dev/references/workflow.md` and
> `discuss/references/phases.md`. When working from those skills, follow their
> inline prompts — do not use these. Use the templates below only outside `/agent-team:dev`
> and `/agent-team:discuss`.

Replace `[placeholders]` with actual values. Everything else (agent definition,
skills, memory, rules, CLAUDE.md) loads automatically — see the Native Context
Protocol in `SKILL.md`.

## FLAT / HIERARCHICAL roles

### Explorer Spawn

```
Spawn a read-only explorer teammate with the prompt:

"You are the explorer for this team.

Your task: Analyze the codebase for implementing this feature:
[FULL TASK SPEC - paste complete description]

Find: (1) Similar features and patterns, (2) Files to modify/create,
(3) Architecture patterns, (4) Dependencies, (5) Concerns.

Return findings in an <explorer-result> block. Message the lead when done."

Require plan approval before they make changes.
```

### Implementer Spawn

```
Spawn an implementer teammate with the prompt:

"You are the implementer for this team.

Your task: Implement changes for this feature:
[FULL TASK SPEC - paste complete description]

Implementation plan:
[PASTE PLAN FROM EXPLORER FINDINGS]

Work through the shared task list. Message the reviewer when each task is done.
Message the lead if blocked. Complete self-review before marking tasks done.

Return results in an <implementer-result> block."

Require plan approval before they make changes.
```

### Reviewer Spawn

```
Spawn a read-only reviewer teammate with the prompt:

"You are the reviewer for this team.

Your task: Verify implementation matches this spec:
[FULL TASK SPEC - paste complete description]

Two-pass review: (1) Spec compliance - does code match requirements exactly?
(2) Code quality - security, performance, patterns.

MESSAGE THE IMPLEMENTER DIRECTLY with findings. Do not relay through the lead.
Return results in a <reviewer-result> block. Message the lead with final status."
```

### QA Spawn

```
Spawn a QA teammate with the prompt:

"You are the QA teammate.

Your task: Run lint, typecheck, and tests for this project.
Wait for the reviewer to confirm COMPLIANT before running.

Auto-detect commands from package.json, pyproject.toml, or similar.
MESSAGE THE IMPLEMENTER DIRECTLY with any errors found.
Return results in a <qa-result> block. Message the lead with final status."
```

## COUNCIL roles (for `/agent-team:discuss`)

Spawned progressively per phase. All read-only.

### Scout Spawn (Phase 1)
```
Spawn a read-only scout teammate with the prompt:

"You are the codebase scout for a /agent-team:discuss session.
[PASTE IDEA + REFERENCES]

Explore the codebase for patterns, integration points, and constraints.
OUTPUT BUDGET: Keep response under 2000 tokens.
Return findings in a <scout-result> block. Message the lead when done."
```

### Researcher Spawn (Phase 1)
```
Spawn a read-only researcher teammate with the prompt:

"You are the web researcher for a /agent-team:discuss session.
[PASTE IDEA + REFERENCES]

Research prior art, libraries, best practices, architectural patterns.
OUTPUT BUDGET: Keep response under 2000 tokens.
Return findings in a <research-result> block. Message the lead when done."
```

### Challenger Spawn (Phase 3)
```
Spawn a read-only challenger teammate with the prompt:

"You are the plan challenger for a /agent-team:discuss session.
[PASTE DRAFT PLAN + FINDINGS SUMMARIES]

Stress-test: feasibility, accuracy, alternatives, risks, missing pieces.
OUTPUT BUDGET: Keep response under 1500 tokens.
Return findings in a <challenge-result> block. Message the lead when done."
```

### Blind Spot Spawn (Phase 4)
```
Spawn a read-only blind spot teammate with the prompt:

"You are the blind spot investigator for a /agent-team:discuss session.
[PASTE VALIDATED PLAN SUMMARY + TECHNOLOGIES]

Check: native features, recent changes, simpler alternatives, unverified assumptions.
OUTPUT BUDGET: Keep response under 1000 tokens.
Return findings in a <blindspot-result> block. Message the lead when done."
```

### Dependency Researcher Spawn (Phase 5 - optional)
```
Spawn a read-only dependency researcher teammate with the prompt:

"You are the dependency researcher for a /agent-team:discuss DEEPEN session.
[PASTE VALIDATED PLAN + SCOUT SUMMARY]

Research all external dependencies. Pin exact versions. Use context7 for docs.
OUTPUT BUDGET: Keep response under 2000 tokens.
Return findings in a <dependency-result> block. Message the lead when done."
```
