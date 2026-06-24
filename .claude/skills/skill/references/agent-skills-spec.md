# Agent Skills Specification

Full specification for creating valid Agent Skills. Sources: https://agentskills.io/specification and Anthropic's [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).

## Contents

- Frontmatter Fields (`name`, `description`, and rules)
- Naming Conventions (gerund form; names to avoid)
- Optional Directories (`scripts/`, `references/`, `assets/`)
- Progressive Disclosure
- File References
- MCP Tool References
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

## Naming Conventions

Prefer **gerund form** (verb + -ing) — it names the activity the skill provides and reads consistently across a skill library.

- **Preferred (gerund):** `processing-pdfs`, `analyzing-spreadsheets`, `testing-code`, `writing-documentation`
- **Acceptable:** noun phrases (`pdf-processing`, `spreadsheet-analysis`) or action-oriented (`process-pdfs`, `analyze-spreadsheets`)
- **Avoid:** vague names (`helper`, `utils`, `tools`), overly generic names (`documents`, `data`, `files`), reserved words (`anthropic-helper`, `claude-tools`), and inconsistent patterns within a collection

### description field rules

- Must describe both **what** the skill does and **when** to use it
- Include keywords for semantic discovery
- Write in **third person** — the description is injected into the system prompt, where first/second person (`I can…`, `You can…`) hurts discovery
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
description: "I can help you process PDF files and fill out forms."
```

---

## Optional Directories

### scripts/

Contains executable code that agents can run.

- **Solve, don't punt** — handle error conditions in the script rather than failing and leaving Claude to recover. Include helpful, specific error messages.
- **No voodoo constants** — justify and document every config value (timeout, retry count). If you can't explain the value, Claude can't either.
- **Make execution intent clear** — state whether Claude should *execute* the script ("Run `analyze.py` to extract fields") or *read it as reference* ("See `analyze.py` for the algorithm"). Execution is preferred for utility scripts: more reliable, fewer tokens.
- **List required packages** in SKILL.md and verify availability. The Claude API runtime has no network or package installation; claude.ai can install from npm/PyPI.
- Common languages: Python, Bash, JavaScript

**Purpose:** runnable by the agent, not illustrative examples (those belong in `references/`).

### references/

Contains additional documentation agents read on demand.

- Use descriptive filenames: `REFERENCE.md`, `FORMS.md`, `api-patterns.md`
- Keep each file focused on one topic
- Smaller files = less context used per load
- **Add a `## Contents` table of contents to any reference file longer than 100 lines** — Claude may preview long files with partial reads, and a ToC keeps the full scope visible.

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

Use relative paths from the skill root. One level deep only — no nested chains. Use **forward slashes** in every path, never backslashes — Unix-style paths work on all platforms; Windows-style paths break on Unix.

```markdown
See [API reference](references/api-patterns.md) for details.

Run the validation script: scripts/validate.sh
```

**Wrong:**
```markdown
See [nested file](references/sub/deep.md)        ← nested, not allowed
See [windows path](references\api-patterns.md)   ← backslash, not allowed
```

---

## MCP Tool References

When a skill references an MCP (Model Context Protocol) tool, use the fully qualified name `ServerName:tool_name` — without the server prefix Claude may fail to locate the tool when several MCP servers are loaded.

```markdown
Use the GitHub:create_issue tool to open issues.
Use the BigQuery:bigquery_schema tool to retrieve table schemas.
```

---

## Content Guidelines

- **Avoid time-sensitive information** that will go stale. Don't write "before August 2025, use the old API." Document the current method in the body and isolate deprecated guidance in an `## Old patterns` section using a collapsed `<details>` block.
- **Use consistent terminology.** Pick one term per concept and use it throughout — always "API endpoint" (not also "URL"/"route"/"path"), always "extract" (not also "pull"/"get"/"retrieve"). Consistency helps Claude follow instructions.
