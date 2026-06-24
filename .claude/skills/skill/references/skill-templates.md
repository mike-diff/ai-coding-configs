# Skill Templates

Ready-to-use templates for the three skill types. Copy the relevant template as your starting SKILL.md, then populate. Starter files for each type also live in `assets/`.

---

## Contents

- [Choosing a Type](#choosing-a-type)
- [Matching Structure to Degrees of Freedom](#matching-structure-to-degrees-of-freedom)
- [Technique Template](#technique-template)
- [Reference Template](#reference-template)
- [Guardrail Template](#guardrail-template)

---

## Choosing a Type

| Type | Use when... | Key sections |
|------|------------|-------------|
| **Technique** | Teaching a concrete procedure with steps | Pattern, Implementation, Common Mistakes |
| **Reference** | Providing quick-lookup docs or API patterns | Quick Reference tables, code snippets |
| **Guardrail** | Enforcing a critical practice, preventing mistakes | STOP block, Rationalization Defense, The Process |

---

## Matching Structure to Degrees of Freedom

Before picking a template, decide how much latitude the task allows, and shape the skill to match (see `prompting-guide.md` §2):

- **High freedom** — the path varies; describe the goal in prose and let the model choose how to get there.
- **Medium freedom** — the shape is fixed but inputs vary; hand over a parameterized procedure or checklist.
- **Low freedom** — one correct path; provide an exact script or step list and forbid improvisation.

Three building blocks earn their place when the task calls for them — drop them into whichever template you start from:

**Copy-able checklist** for any multi-step procedure (medium/low freedom). The agent ticks items as it goes, so nothing is skipped:

```markdown
- [ ] Step 1 — [what + why]
- [ ] Step 2 — [what + why]
- [ ] Step 3 — [what + why]
```

**Validate → fix → repeat feedback loop** so completion is checkable, not self-graded:

```markdown
1. Run `[validation command]`.
2. If it reports problems, fix the first one.
3. Re-run from step 1. Done only when it passes clean.
```

**Input/output example pairs** for any skill whose output shape matters. One concrete pair pins the format better than a prose description of it:

```markdown
**Input:**  [representative input]
**Output:** [exact expected output]
```

---

## Technique Template

```markdown
---
name: skill-name
description: "[What it does]. Use when [triggering conditions, specific keywords]."
---

# Skill Title

## When to Use This Skill

Use this skill when:
- [Trigger 1]
- [Trigger 2]
- [Trigger 3]

## Overview

[One or two sentences on the core concept.]

## Quick Reference

| Without this skill | With this skill |
|-------------------|----------------|
| [bad pattern] | [good pattern] |

## The Pattern

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Implementation

```[language]
[canonical example — one excellent example, not many mediocre ones]
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| [mistake] | [fix] |

## Detailed Guides

- [Extended examples](references/examples.md)
```

---

## Reference Template

```markdown
---
name: skill-name
description: "[What it covers]. Use when [working with X, migrating from Y, building Z]."
---

# Skill Title

## When to Use This Skill

Use this skill when:
- [Trigger 1]
- [Trigger 2]

## Quick Reference

### [Topic A]

| [Column 1] | [Column 2] |
|-----------|-----------|
| [value] | [value] |

### [Topic B]

```[language]
[canonical usage pattern]
```

## Detailed Guides

- [Full API reference](references/REFERENCE.md)
```

---

## Guardrail Template

```markdown
---
name: skill-name
description: "[What it enforces]. Use when [doing X, working with Y, before Z]."
---

# Skill Title

<role>
When [doing X], ALWAYS [critical requirement]. [Why memory/assumptions are unreliable].
</role>

## STOP — Before Any [X] Code

<constraints>
1. [Mandatory step 1]
2. [Mandatory step 2]
3. [Mandatory step 3]
</constraints>

## Verification

| Context | Command |
|---------|---------|
| [context 1] | `[command]` |
| [context 2] | `[command]` |

## Red Flags — STOP Immediately

<rationalization_defense>
| Thought | Reality |
|---------|---------|
| "[rationalization agents use]" | [why it's wrong] |
| "[another rationalization]" | [why it's wrong] |
</rationalization_defense>

## The Process

```
1. STOP
2. [Verify step]
3. [Only then proceed]
```
```
