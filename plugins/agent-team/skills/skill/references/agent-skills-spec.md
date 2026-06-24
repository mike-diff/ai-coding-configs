# Agent Skills Specification

Full specification for creating valid Agent Skills. Sources: https://agentskills.io/specification and Anthropic's [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).

## Contents

- Frontmatter Fields (name / description rules)
- Naming Conventions
- Optional Directories (scripts / references / assets)
- Progressive Disclosure
- File References
- MCP Tool References
- Content Guidelines

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
- Write in **third person** — the description is injected into the system prompt, where first/second-person phrasing ("I can…", "You can…") hurts discovery
- Must NOT contain XML tags (`<`, `>`)

**Good (third person, what + when):**
```yaml
description: "Extracts text and tables from PDF files, fills PDF forms, and merges PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction."
```

**Bad (first/second person, vague):**
```yaml
description: "I can help you with PDFs."
```

---

## Naming Conventions

Beyond the character rules above, choose a name that reads well and is easy to reference.

- **Prefer gerund form** (verb + -ing): `processing-pdfs`, `analyzing-spreadsheets`, `testing-code`, `writing-documentation`.
- **Acceptable alternatives:** noun phrases (`pdf-processing`, `spreadsheet-analysis`) or action-oriented (`process-pdfs`).
- **Avoid:** vague names (`helper`, `utils`, `tools`), overly generic names (`documents`, `data`, `files`), reserved words (`anthropic`, `claude`), and inconsistent patterns across a skill collection.

Consistent naming makes skills easier to reference, discover, and organize.

---

## Optional Directories

### scripts/

Contains executable code that agents can run.

- Must be self-contained or clearly document dependencies
- Must include helpful error messages
- Must handle edge cases gracefully
- Common languages: Python, Bash, JavaScript

**Purpose:** runnable by the agent, not illustrative examples (those belong in `references/`).

**Authoring guidance (from Anthropic's best practices):**

- **Solve, don't punt.** Handle error conditions inside the script (create a missing file, fall back to a default) rather than failing and leaving Claude to recover.
- **No voodoo constants.** Justify and document any configuration value (timeout, retry count). If you don't know the right value, neither will Claude.
- **Make execution intent clear** in the instructions that reference the script: "Run `analyze.py` to extract fields" (execute) vs. "See `analyze.py` for the extraction algorithm" (read as reference). Execution is preferred for most utility scripts — more reliable, fewer tokens.
- **List required packages.** The Claude API runtime has no network access and cannot install packages; claude.ai can install from npm/PyPI. Name the dependencies a script needs.

### references/

Contains additional documentation agents read on demand.

- Use descriptive filenames: `REFERENCE.md`, `FORMS.md`, `api-patterns.md`
- Keep each file focused on one topic
- Smaller files = less context used per load
- For files longer than **100 lines**, add a `## Contents` table of contents at the top so Claude sees the full scope even when previewing with a partial read

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

Use relative paths from the skill root. One level deep only — no nested chains. Always use **forward slashes** (`references/guide.md`), never Windows-style backslashes — backslash paths break on Unix.

```markdown
See [API reference](references/api-patterns.md) for details.

Run the validation script: scripts/validate.sh
```

**Wrong:**
```markdown
See [nested file](references/sub/deep.md)      ← nested chain, not allowed
See [guide](references\guide.md)               ← backslash path, not allowed
```

---

## MCP Tool References

If a skill uses MCP (Model Context Protocol) tools, reference them by **fully qualified name** — `ServerName:tool_name` — to avoid "tool not found" errors when multiple MCP servers are available.

```markdown
Use the BigQuery:bigquery_schema tool to retrieve table schemas.
Use the GitHub:create_issue tool to create issues.
```

---

## Content Guidelines

- **Avoid time-sensitive information** that will become wrong (e.g. "before August 2025, use the old API"). Document the current method in the body and isolate deprecated guidance in an "Old patterns" `<details>` block.
- **Use consistent terminology.** Pick one term per concept and use it throughout (always "field", not a mix of "field"/"box"/"element"). Consistency helps Claude follow instructions.
