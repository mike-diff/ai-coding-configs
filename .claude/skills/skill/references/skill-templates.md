# Skill Templates

Ready-to-use templates for the three skill types. Copy the relevant template as your starting SKILL.md, then populate. Starter files for each type also live in `assets/`.

## Contents

- Choosing a Type (technique / reference / guardrail) + degrees of freedom
- Technique Template
- Reference Template
- Guardrail Template

---

## Choosing a Type

| Type | Use when... | Key sections |
|------|------------|-------------|
| **Technique** | Teaching a concrete procedure with steps | Pattern, Implementation, Common Mistakes |
| **Reference** | Providing quick-lookup docs or API patterns | Quick Reference tables, code snippets |
| **Guardrail** | Enforcing a critical practice, preventing mistakes | STOP block, Rationalization Defense, The Process |

**Degrees of freedom** cut across all three types — match the template's specificity to
the task's fragility (see [prompting-guide.md](prompting-guide.md) §2): high-freedom prose
steps for open-ended work, an exact script for fragile sequences. Reach for these patterns
when they fit:

- **Copy-able checklist** for multi-step procedures — a `- [ ] Step N` block Claude ticks off as it goes.
- **Validate → fix → repeat feedback loop** for quality-critical output — run a checker, fix, re-run until clean.
- **Input/output example pairs** when output shape matters more than prose can convey.

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
