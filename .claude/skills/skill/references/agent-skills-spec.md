# Agent Skills Specification

Full specification for creating valid Agent Skills. Sources: https://agentskills.io/specification and Anthropic's [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).

## Contents

- Frontmatter Fields (`name`, `description`, and rules for each)
- Naming Conventions (gerund form, what to avoid)
- Optional Directories (`scripts/`, `references/`, `assets/`)
- Progressive Disclosure (load tiers, size targets)
- File References (one level deep, forward slashes)
- MCP Tool References (fully-qualified names)
- Content Guidelines (time-sensitive info, consistent terminology)

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
- Must NOT contain XML tags (`<`, `>`)
- Must NOT contain the reserved words `anthropic` or `claude`
- Must match parent directory name exactly

**Valid:** `pdf-processing`, `code-review`, `react-query-v5`
**Invalid:** `PDF-Processing`, `-pdf`, `pdf--processing`, `my_skill`, `claude-tools`

### description field rules

- Must describe both **what** the skill does and **when** to use it
- Include keywords for semantic discovery
- Write in **third person** — the description is injected into the system prompt, so first/second-person phrasing ("I can…", "You can…") creates POV inconsistency that hurts discovery
- Must NOT contain XML tags (`<`, `>`)

**Good (third person, what + when):**
```yaml
description: "Extracts text and tables from PDF files, fills PDF forms, and merges PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction."
```

**Bad (vague):**
```yaml
description: "Helps with PDFs."
```

**Bad (first/second person):**
```yaml
description: "I can help you process PDF files and you can use this to fill forms."
```

---

## Naming Conventions

Consistent naming makes skills easier to reference, discover, and maintain.

- **Prefer gerund form** (verb + -ing): `processing-pdfs`, `analyzing-spreadsheets`, `testing-code`, `writing-documentation`
- **Acceptable alternatives:** noun phrases (`pdf-processing`, `spreadsheet-analysis`) or action-oriented (`process-pdfs`, `analyze-spreadsheets`)
- **Avoid:**
  - Vague names: `helper`, `utils`, `tools`
  - Overly generic names: `documents`, `data`, `files`
  - Reserved words: `anthropic-helper`, `claude-tools`
  - Inconsistent patterns within a skill collection

---

## Optional Directories

### scripts/

Contains executable code that agents can run.

- Must be self-contained or clearly document dependencies
- **List required packages** in SKILL.md and verify availability: claude.ai can install from npm/PyPI, but the Claude API code-execution environment has no network access and no runtime install
- **Solve, don't punt:** handle error conditions in the script (create defaults, provide alternatives) rather than failing and leaving Claude to recover
- **No "voodoo constants":** justify and document config values in a comment. If you can't say why a timeout is 30s, Claude can't either
- **Make execution intent clear:** "Run `analyze.py` to extract fields" (execute — the common case, more reliable and token-cheap) vs. "See `analyze.py` for the algorithm" (read as reference)
- Common languages: Python, Bash, JavaScript

**Purpose:** runnable by the agent, not illustrative examples (those belong in `references/`).

### references/

Contains additional documentation agents read on demand.

- Use descriptive filenames: `REFERENCE.md`, `FORMS.md`, `api-patterns.md`
- Keep each file focused on one topic
- Smaller files = less context used per load
- **For files longer than 100 lines, add a `## Contents` table of contents** near the top, so Claude sees the full scope even when previewing with a partial read

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
Always use **forward slashes** (`references/guide.md`), never backslashes — Unix-style
paths work on every platform; Windows-style paths break on Unix.

```markdown
See [API reference](references/api-patterns.md) for details.

Run the validation script: scripts/validate.sh
```

**Wrong:**
```markdown
See [nested file](references/sub/deep.md)        ← nested, not allowed
See [windows path](references\guide.md)          ← backslash, not allowed
```

---

## MCP Tool References

If a skill uses MCP tools, reference them by their **fully-qualified** name so Claude
can locate them when multiple servers are connected.

**Format:** `ServerName:tool_name`

```markdown
Use the BigQuery:bigquery_schema tool to retrieve table schemas.
Use the GitHub:create_issue tool to open issues.
```

Without the server prefix, Claude may fail to find the tool.

---

## Content Guidelines

- **Avoid time-sensitive information** that will become outdated ("before August 2025, use the old API"). Put deprecated content in an "Old patterns" `<details>` section instead, so the main content stays current.
- **Use consistent terminology** — pick one term and use it throughout (always "field", not a mix of "field"/"box"/"element"). Consistency helps Claude follow instructions.
