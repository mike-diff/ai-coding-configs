---
name: skill-creator
description: "Create Agent Skills following the agentskills.io specification. Use when creating new skills, writing SKILL.md files, setting up skill directory structures, or validating skill frontmatter and format."
---

# Skill Creator

<role>
When creating Agent Skills, follow the official agentskills.io specification for directory structure, frontmatter, and progressive disclosure. Populate all three optional directories when they add value.
</role>

## When to Use This Skill

Use this skill when:
- Creating a new skill from scratch
- Writing or editing SKILL.md files
- Setting up skill directory structures
- Validating frontmatter and naming conventions

---

## Skill Types

| Type | Use when... | Key structure |
|------|------------|--------------|
| **Technique** | Teaching a concrete procedure | Pattern + Implementation + Mistakes |
| **Reference** | Quick-lookup docs or API patterns | Tables + Code snippets |
| **Guardrail** | Enforcing a critical practice | STOP block + Rationalization Defense |

Starter templates: `assets/technique-template.md`, `assets/reference-template.md`, `assets/guardrail-template.md`

---

## Directory Standard

```
skill-name/
├── SKILL.md              # Required
├── references/           # Detailed docs loaded on demand
│   └── REFERENCE.md
├── scripts/              # Executable code the agent runs
│   └── validate.sh
└── assets/               # Static files: templates, schemas, data
    └── template.md
```

**When to create each folder:**

| Folder | Create when... | Skip when... |
|--------|---------------|-------------|
| `references/` | SKILL.md would exceed 500 lines without it; or there are detailed docs worth loading on demand | Skill is short and self-contained |
| `scripts/` | There's a runnable validator, helper, or extractor the agent can execute | All content is instructional prose |
| `assets/` | There are starter templates, schemas, or static data files to copy | Nothing static to provide |

---

## Frontmatter Rules

| Field | Required | Rules |
|-------|----------|-------|
| `name` | Yes | 1–64 chars. Lowercase + hyphens only. No leading/trailing/consecutive hyphens. Must match directory name exactly. |
| `description` | Yes | 1–1024 chars. Must include **what** and **when**. Include trigger keywords. |
| `compatibility` | Recommended | e.g. `"Designed for Cursor"` |
| `license` | No | License name or reference to LICENSE file. |
| `metadata` | No | Key-value map for custom properties. |

**Good description:**
```yaml
description: "Extracts text and tables from PDF files, fills PDF forms, merges PDFs. Use when working with PDF documents or the user mentions PDFs, forms, or document extraction."
```

**Bad description:**
```yaml
description: "Helps with PDFs."
```

---

## File Reference Rules

Use relative paths from the skill root. One level deep only.

```markdown
See [API reference](references/api-patterns.md) for details.
Run the validation script: scripts/validate.sh
```

❌ Never: `references/sub/deep.md`

---

## Validation

Run against any skill directory:

```bash
bash scripts/validate-skill.sh .cursor/skills/[skill-name]/
```

Checks: frontmatter validity, name rules, directory/name match, line count, file reference depth.

---

## Quality Checklist

Before finalizing:

- [ ] `name` lowercase, hyphens only, matches directory exactly
- [ ] `description` includes what + when + keywords
- [ ] SKILL.md under 500 lines
- [ ] `references/` created or explicitly skipped
- [ ] `scripts/` created or explicitly skipped
- [ ] `assets/` created or explicitly skipped
- [ ] File references one level deep only
- [ ] `validate-skill.sh` run and passed

---

## Detailed Guides

- [Full Specification](references/agent-skills-spec.md) — Frontmatter rules, directory spec
- [Skill Templates](references/skill-templates.md) — Annotated templates for all three types
