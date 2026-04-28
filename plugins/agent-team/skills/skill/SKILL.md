---
name: skill
description: "Create a new Agent Skill in .claude/skills/ following the agentskills.io specification. Use when creating skills, writing SKILL.md files, setting up skill directory structures, or validating skill frontmatter. Delegates to skill-author teammate using TDD methodology."
argument-hint: <skill description>
compatibility: "Designed for Claude Code"
---

# /agent-team:skill — Create Agent Skills

Create Agent Skills for `.claude/skills/` following the [agentskills.io](https://agentskills.io/specification) specification. Skills auto-activate based on semantic matching of your request to skill descriptions.

<role>
You are a skill creation orchestrator. You parse requests, delegate all implementation to the skill-author teammate, verify the result, and run validation. You do NOT write skills directly.
</role>

<skill_request>
$ARGUMENTS
</skill_request>

---

## Skill Types

| Type | Use when... | Key structure |
|------|------------|--------------|
| **Technique** | Teaching a concrete procedure | Pattern + Implementation + Mistakes |
| **Reference** | Quick-lookup docs or API patterns | Tables + Code snippets |
| **Guardrail** | Enforcing a critical practice | STOP block + Rationalization Defense |

---

## Directory Standard

Every skill must have `SKILL.md`. Populate the optional folders when they add value — skip them when they don't.

```
skill-name/
├── SKILL.md              # Required
├── references/           # Detailed docs the agent reads on demand
│   └── REFERENCE.md      # (or topic-specific: api-patterns.md, examples.md)
├── scripts/              # Executable code the agent runs
│   └── validate.sh       # (or helpers, extractors, validators)
└── assets/               # Static files: templates, schemas, data
    └── template.md       # (or schema.json, diagram.png)
```

**When to create each folder:**

| Folder | Create when... | Skip when... |
|--------|---------------|-------------|
| `references/` | SKILL.md would exceed 500 lines without it; or there's detailed API/pattern docs the agent should load on demand | The skill is short and self-contained |
| `scripts/` | There's a runnable validator, helper, or extractor the agent can execute | All content is instructional prose |
| `assets/` | There are starter templates, schemas, or static data files to copy/reference | There's nothing static to provide |

---

## Frontmatter Rules

| Field | Required | Rules |
|-------|----------|-------|
| `name` | Yes | 1–64 chars. Lowercase + hyphens only (`a-z`, `0-9`, `-`). No leading/trailing/consecutive hyphens. Must match directory name exactly. |
| `description` | Yes | 1–1024 chars. Must include **what** it does AND **when** to use it. Include trigger keywords. |
| `compatibility` | Recommended | Use `"Designed for Claude Code"` for Claude Code skills. |
| `license` | No | License name or reference to LICENSE file. |
| `metadata` | No | Key-value map for custom properties. |

**Good description:**
```yaml
description: "Extracts text and tables from PDF files, fills PDF forms, merges PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction."
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

❌ Never: `references/sub/deep.md` — nested chains break progressive disclosure.

---

<principles>
1. **Delegation-first** — All skill writing is delegated to skill-author. No exceptions.
2. **TDD required** — Baseline test before any content is written.
3. **Spec compliance** — Follow agentskills.io format strictly.
4. **Populate folders** — Default to creating references/, scripts/, assets/ when they add value.
5. **Validate before closing** — Run `scripts/validate-skill.sh` on the result.
</principles>

<red_flags>
| Thought | Reality |
|---------|---------|
| "This skill is simple, I'll write it myself" | Delegate. Always. No exceptions. |
| "TDD is overkill for this skill" | Untested skills cause behavior drift. Test first. |
| "I'll skip the extra folders, SKILL.md is enough" | Robust skills use references/, scripts/, assets/ when appropriate. |
| "The description is fine without keywords" | Vague descriptions = agent can't activate. Be specific. |
</red_flags>

---

<workflow>
## Phase 1: Parse Request

```markdown
**Skill Request Analysis**
**Name:** [kebab-case]
**Type:** [technique / reference / guardrail]
**Purpose:** [What problem does it solve?]
**Folders needed:**
  - references/: [yes — reason | no]
  - scripts/:    [yes — reason | no]
  - assets/:     [yes — reason | no]
```

## Phase 2: Check for Existing Skills

```bash
ls -la "/.claude/skills/
find .claude/skills -name "SKILL.md" -exec head -3 {} \; -print
```

If a similar skill exists, ask whether to extend, complement, or replace it.

## Phase 3: Delegate to skill-author

Spawn the skill-author teammate with full context:

```
"You are the skill-author for this session.

Task: Create this skill using TDD methodology.

**Request:** [full request text]
**Name:** [kebab-case]
**Type:** [technique / reference / guardrail]
**Location:** .claude/skills/[name]/

**Folder plan:**
- references/: [yes — what files | no]
- scripts/:    [yes — what scripts | no]
- assets/:     [yes — what templates/data | no]

Starter templates are in .claude/skills/skill/assets/:
  technique-template.md, reference-template.md, guardrail-template.md

TDD process:
1. Baseline test WITHOUT the skill — record failures verbatim
2. Write SKILL.md + populate folders addressing those failures
3. Test WITH the skill — verify fix
4. Close loopholes, re-test

Return a <skill-author-result> block."
```

Wait for the `<skill-author-result>` block before proceeding.

## Phase 4: Validate

```bash
bash "/skills/skill/scripts/validate-skill.sh" "/.claude/skills/[skill-name]/
ls -la "/.claude/skills/[skill-name]/
wc -l .claude/skills/[skill-name]/SKILL.md
```

If validation fails, delegate back to skill-author with specific errors.

## Phase 5: Report

```markdown
## Skill Created ✅

**Location:** `.claude/skills/[name]/`
**Type:** [technique / reference / guardrail]
**Lines:** [SKILL.md line count]

**Structure:**
- `SKILL.md` ([n] lines)
- `references/[file]` — [purpose]  ← if created
- `scripts/[file]` — [purpose]     ← if created
- `assets/[file]` — [purpose]      ← if created

**Baseline failures addressed:**
1. [failure] → [fix]

**Activates when:** [paraphrase description trigger]

**Next steps:**
- [ ] Test with a real scenario to verify activation
- [ ] `git add .claude/skills/[name]/`
```
</workflow>

---

## Resources

- [Agent Skills Specification](references/agent-skills-spec.md) — Full spec reference
- [Skill Templates](references/skill-templates.md) — Annotated templates for all three types
- Starter templates: `assets/technique-template.md`, `assets/reference-template.md`, `assets/guardrail-template.md`
- Validation: `scripts/validate-skill.sh <path-to-skill-dir>`
