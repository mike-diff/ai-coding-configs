# Agent Skills Specification

Full specification for creating valid Agent Skills. Source: https://agentskills.io/specification

---

## Frontmatter Fields

| Field | Required | Constraints |
|-------|----------|-------------|
| `name` | Yes | 1–64 chars. Lowercase letters, numbers, hyphens only. Must match directory name exactly. |
| `description` | Yes | 1–1024 chars. Describes what the skill does AND when to use it. |
| `compatibility` | No | 1–500 chars. Use only when the skill has specific environment requirements. |
| `license` | No | License name or reference to a bundled license file. |
| `metadata` | No | Arbitrary key-value map for additional properties. |
| `allowed-tools` | No | Space-delimited list of pre-approved tools. Experimental. |

### name field rules

- Lowercase letters, numbers, and hyphens only (`a-z`, `0-9`, `-`)
- Must NOT start or end with `-`
- Must NOT contain consecutive hyphens (`--`)
- Must match parent directory name exactly

**Valid:** `pdf-processing`, `code-review`, `react-query-v5`
**Invalid:** `PDF-Processing`, `-pdf`, `pdf--processing`, `my_skill`

### description field rules

- Must describe both **what** the skill does and **when** to use it
- Include keywords for semantic discovery

**Good:**
```yaml
description: "Extracts text and tables from PDF files, fills PDF forms, and merges PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction."
```

**Bad:**
```yaml
description: "Helps with PDFs."
```

---

## Optional Directories

### scripts/

Contains executable code that agents can run.

- Must be self-contained or clearly document dependencies
- Must include helpful error messages
- Must handle edge cases gracefully
- Common languages: Python, Bash, JavaScript

**Purpose:** runnable by the agent, not illustrative examples (those belong in `references/`).

### references/

Contains additional documentation agents read on demand.

- Use descriptive filenames: `REFERENCE.md`, `FORMS.md`, `api-patterns.md`
- Keep each file focused on one topic
- Smaller files = less context used per load

**Purpose:** detailed docs the agent reads when it needs depth beyond what SKILL.md provides.

### assets/

Contains static resources that don't change.

- Templates (document templates, configuration starters)
- Images (diagrams, architecture diagrams)
- Data files (schemas, lookup tables)

**Purpose:** static files, not instructions. If it's instructional prose, it belongs in `references/` not `assets/`.

---

## Progressive Disclosure

| Stage | What loads | Target size |
|-------|-----------|-------------|
| Metadata | `name` + `description` | ~100 tokens |
| Instructions | Full `SKILL.md` body | <500 lines |
| Resources | `scripts/`, `references/`, `assets/` files | On demand only |

---

## File References

Use relative paths from the skill root. One level deep only — no nested chains.

```markdown
See [API reference](references/api-patterns.md) for details.

Run the validation script: scripts/validate.sh
```

**Wrong:**
```markdown
See [nested file](references/sub/deep.md)   ← not allowed
```
