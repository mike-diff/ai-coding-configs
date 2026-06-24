# Agent Skills Specification

Full specification for creating valid Agent Skills. Source: https://agentskills.io/specification

---

## Contents

- [Frontmatter Fields](#frontmatter-fields)
- [Naming Conventions](#naming-conventions)
- [Optional Directories](#optional-directories)
- [Progressive Disclosure](#progressive-disclosure)
- [File References](#file-references)
- [MCP Tool References](#mcp-tool-references)
- [Content Guidelines](#content-guidelines)

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
**Invalid:** `PDF-Processing`, `-pdf`, `pdf--processing`, `my_skill`, `claude-helper`

### description field rules

- Must describe both **what** the skill does and **when** to use it
- Include keywords for semantic discovery
- Write in third person — the description is injected into the system prompt, so first/second person (`I can…`, `You can…`) reads oddly there and weakens discovery
- Must NOT contain XML tags (`<`, `>`)

**Good (third person):**
```yaml
description: "Extracts text and tables from PDF files, fills PDF forms, and merges PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction."
```

**Bad (first/second person):**
```yaml
description: "I can help you with PDFs whenever you need to read or edit one."
```

**Bad (too vague):**
```yaml
description: "Helps with PDFs."
```

---

## Naming Conventions

Name the skill after what it *does*, in a form that reads well alongside other skill names.

- **Prefer the gerund form:** `processing-pdfs`, `testing-code`, `analyzing-spreadsheets`
- **Also acceptable:** noun phrases (`pdf-processing`) or action-oriented names (`process-pdfs`)
- **Avoid:**
  - vague labels (`helper`, `utils`, `tools`) — they say nothing about scope
  - over-generic names (`documents`, `data`) — too broad to route to reliably
  - the reserved words `anthropic` and `claude`
  - inconsistent patterns across a skill set — pick one form and stay consistent

---

## Optional Directories

### scripts/

Contains executable code that agents can run.

- Must be self-contained or clearly document dependencies
- Must include helpful error messages
- Must handle edge cases gracefully
- Common languages: Python, Bash, JavaScript
- **Solve, don't punt:** a script should do the work, not emit a stub or a "TODO: implement" placeholder for the agent to finish
- **No voodoo constants:** name and justify any magic number or threshold instead of hard-coding an unexplained value
- **State the intent — execute vs. read:** say up front whether the agent should *run* the script (deterministic step, output enters context) or *read* it as an example (then it belongs in `references/` instead)
- **List required packages:** declare every dependency the script needs. The API runtime has no network and cannot install packages; claude.ai can install from npm/PyPI. Skills that must run in both should prefer the standard library or document the install step clearly.

**Purpose:** runnable by the agent, not illustrative examples (those belong in `references/`).

### references/

Contains additional documentation agents read on demand.

- Use descriptive filenames: `REFERENCE.md`, `FORMS.md`, `api-patterns.md`
- Keep each file focused on one topic
- Smaller files = less context used per load
- Add a `## Contents` table of contents to any reference file over 100 lines, so the agent can jump to the right section without reading the whole file

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
Use forward slashes (`/`) only, never backslashes — skills must work on every platform, and `\` is not a valid path separator here.

```markdown
See [API reference](references/api-patterns.md) for details.

Run the validation script: scripts/validate.sh
```

**Wrong:**
```markdown
See [nested file](references/sub/deep.md)   ← not allowed
See [backslash path](references\api-patterns.md)   ← not allowed
```

---

## MCP Tool References

When a skill references a tool exposed by an MCP server, write it as `ServerName:tool_name` — the server name, a colon, then the tool name. This is the form the agent resolves the tool by.

```markdown
Fetch the page with `Browser:navigate`, then extract content with `Browser:get_content`.
```

---

## Content Guidelines

- **Avoid time-sensitive information.** Phrases like "the new API", "as of last release", or "currently" go stale and mislead later readers. State patterns in durable terms. When a deprecated approach must be documented for migration, isolate it in a collapsed block so it doesn't compete with the current guidance:

  ```markdown
  <details>
  <summary>Old patterns (pre-v5 — for migration only)</summary>

  [legacy approach here]

  </details>
  ```

- **Use consistent terminology.** Pick one term for each concept and use it everywhere. Switching between synonyms (e.g. "skill" vs. "plugin" vs. "module" for the same thing) forces the reader to re-map terms and weakens discovery.
