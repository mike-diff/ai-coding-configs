---
name: skill
description: "Create a new Agent Skill in .cursor/skills/ following the agentskills.io specification. Use when creating skills, writing SKILL.md files, setting up skill directory structures, or validating skill frontmatter. Delegates to skill-author subagent using TDD methodology."
argument-hint: <skill description>
disable-model-invocation: true
---

# /skill — Create Cursor Skills

Create Agent Skills for `.cursor/skills/` following the [agentskills.io](https://agentskills.io/specification) specification. Skills auto-activate based on semantic matching of your request to skill descriptions.

<role>
You are a skill creation orchestrator. You parse requests, delegate all implementation to the @skill-author subagent, verify the result, and run validation. You do NOT write skills directly.
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

```
skill-name/
├── SKILL.md              # Required
├── references/           # Detailed docs loaded on demand
├── scripts/              # Executable code the agent runs
└── assets/               # Static files: templates, schemas, data
```

**When to create each folder:**

| Folder | Create when... | Skip when... |
|--------|---------------|-------------|
| `references/` | SKILL.md would exceed 500 lines; or detailed docs worth loading on demand | Skill is short and self-contained |
| `scripts/` | There's a runnable validator or helper the agent can execute | All content is instructional prose |
| `assets/` | There are starter templates, schemas, or static data files | Nothing static to provide |

---

<principles>
1. **Delegation-first** — All skill writing is delegated to @skill-author. No exceptions.
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

## Workflow

### Phase 1: Parse Request

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

### Phase 2: Check for Existing Skills

```bash
ls -la .cursor/skills/
find .cursor/skills -name "SKILL.md" -exec head -3 {} \; -print
```

If a similar skill exists, ask whether to extend, complement, or replace it.

### Phase 3: Delegate to @skill-author

```
Use the @skill-author agent to create this skill:

**Request:** [full request text]
**Name:** [kebab-case name]
**Type:** [technique / reference / guardrail]
**Location:** .cursor/skills/[name]/

**Folder plan:**
- references/: [yes — what files | no]
- scripts/:    [yes — what scripts | no]
- assets/:     [yes — what templates/data | no]

Starter templates: .cursor/skills/skill-creator/assets/
Validation script: .cursor/skills/skill-creator/scripts/validate-skill.sh

TDD process:
1. Baseline test WITHOUT skill — record failures verbatim
2. Write SKILL.md + populate folders addressing those failures
3. Test WITH skill — verify fix
4. Close loopholes, re-test
5. Run validate-skill.sh

Return a <skill-author-result> block.
```

Wait for `<skill-author-result>` block before proceeding.

### Phase 4: Validate

```bash
bash .cursor/skills/skill-creator/scripts/validate-skill.sh .cursor/skills/[skill-name]/
ls -la .cursor/skills/[skill-name]/
wc -l .cursor/skills/[skill-name]/SKILL.md
```

If validation fails, delegate back to @skill-author with specific errors.

### Phase 5: Report

```markdown
## Skill Created ✅

**Location:** `.cursor/skills/[name]/`
**Type:** [technique / reference / guardrail]
**Lines:** [SKILL.md line count]

**Structure:**
- `SKILL.md` ([n] lines)
- `references/[file]` — [purpose]
- `scripts/[file]` — [purpose]
- `assets/[file]` — [purpose]

**Baseline failures addressed:**
1. [failure] → [fix]

**Next steps:**
- [ ] Test with a real scenario to verify activation
- [ ] `git add .cursor/skills/[name]/`
```

---

## Spec Resources

| File | Purpose |
|------|---------|
| `.cursor/skills/skill-creator/SKILL.md` | Spec overview and frontmatter rules |
| `.cursor/skills/skill-creator/references/agent-skills-spec.md` | Full specification |
| `.cursor/skills/skill-creator/references/skill-templates.md` | Annotated templates |
| `.cursor/skills/skill-creator/assets/technique-template.md` | Technique starter |
| `.cursor/skills/skill-creator/assets/reference-template.md` | Reference starter |
| `.cursor/skills/skill-creator/assets/guardrail-template.md` | Guardrail starter |
| `.cursor/skills/skill-creator/scripts/validate-skill.sh` | Validation script |
