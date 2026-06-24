## Summary

Updates the `/skill` meta-skill (`.claude/skills/skill`) to align with Anthropic's
latest [Agent Skills best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices),
so skills produced by `/skill` reflect current official guidance. The doc was read
in full and cached under `.context/mcp-cache/`; every change below is justified by a
specific section of it. Changes are targeted — the `/skill` phase flow and
skill-author delegation are preserved.

## Gap analysis (doc → current state → change)

| Best practice (doc section) | Current state in the skill | Change applied |
|---|---|---|
| **Naming conventions** — prefer gerund form; avoid vague/generic/reserved | Only character rules (`a-z0-9-`) | Added a Naming Conventions section to the spec + a naming note in SKILL.md |
| **YAML frontmatter** — `name` cannot contain XML tags or reserved words `anthropic`/`claude` | Not enforced | Spec + SKILL.md rules + validator **fail** checks |
| **Writing descriptions** — always third person; no XML tags | Not mentioned | Spec (with good/bad pair) + SKILL.md + validator (fail on XML tags, warn on 1st/2nd person) |
| **Degrees of freedom** — high/medium/low by task fragility | Only "altitude" (single axis) | Added degrees-of-freedom guidance to prompting-guide §2 + skill-templates |
| **Structure longer reference files with a ToC** (>100 lines) | Not mentioned | Spec rule + `## Contents` added to the skill's 3 long references + validator warn |
| **Avoid time-sensitive info / consistent terminology** | Implicit | Spec Content Guidelines + prompting-guide §9 |
| **Avoid Windows-style paths** — forward slashes only | Omitted | Spec + SKILL.md + validator warn |
| **Avoid offering too many options** — default + single escape hatch | Not explicit | prompting-guide §9 + skill-templates |
| **Scripts** — solve-don't-punt, no voodoo constants, execute-vs-read intent, list deps | Partial | Expanded the spec `scripts/` subsection |
| **MCP tool references** — fully-qualified `Server:tool` | Not mentioned | New MCP Tool References section in the spec |
| **Evaluation-driven dev** — build evals first; ≥3 evals; test Haiku/Sonnet/Opus | General eval guidance only | SKILL.md principle #7 + prompting-guide §11 + checklist; baked into the delegate brief |

## Key changes

- **`references/agent-skills-spec.md`** — added a `## Contents` ToC; `name` rules now
  forbid XML tags and reserved words; new Naming Conventions section (gerund form);
  `description` rules now require third person and forbid XML tags (with a bad
  first-person example); expanded `scripts/` guidance (solve-don't-punt, voodoo
  constants, execute-vs-read, package deps); reference-file ToC rule; forward-slash
  path rule; new MCP Tool References and Content Guidelines sections.
- **`SKILL.md`** — frontmatter table updated (name: no XML/reserved words;
  description: third person, no XML tags); naming note; new principle #7
  (evaluate-don't-assume); Phase 3 delegate brief now propagates the best-practice
  rules so emitted skills inherit them.
- **`references/prompting-guide.md`** — added a ToC; degrees-of-freedom guidance
  (§2); default-plus-escape-hatch and timeless/consistent-terminology guidance (§9);
  evaluation-driven + multi-model testing guidance (§11); three new checklist items.
- **`references/skill-templates.md`** — added a ToC; degrees-of-freedom note plus
  checklist / feedback-loop / example-pairs guidance under "Choosing a Type".
- **`scripts/validate-skill.sh`** — new **fail** checks (name: XML tags, reserved
  words; description: XML tags) and **warn** checks (description not third person;
  backslash paths; reference files >100 lines lacking a ToC). Frontmatter extraction
  hardened to drop the fragile `xargs` trim that crashed on apostrophes/quotes in a
  description.
- **`assets/*.md`** — checked, no change needed (placeholders already neutral/third
  person; ToCs belong in reference files, not the emitted templates).
- Regenerated the `plugins/agent-team/skills/skill/` mirror via `sync-plugin.sh`.

## Verification

```
validate-skill.sh .claude/skills/skill              → ✅ no errors, no warnings
validate-skill.sh plugins/.../skills/skill          → ✅ no errors, no warnings
all 32 SKILL.md dirs (.claude + plugins)            → rc=0 (no regressions)
sync-plugin.sh                                      → exit 0, "Sync complete."
apostrophe-in-description regression                → rc=0 (no xargs crash)
```

New **fail** checks were verified safe before adding: no existing skill `name`
contains XML tags or reserved words, and no existing `description` contains XML tags.
The third-person / ToC / backslash checks are **warn-only**, so no existing skill
changes pass/fail status (the ToC warn does surface other skills' long references —
addressing those is out of scope for this issue).

## Assumptions & flagged conflict

- **House-convention conflict (repo convention kept):** the doc's *Template pattern*
  illustrates a strict `ALWAYS use this exact template` / `MUST filter` style, which
  conflicts with this repo's calibrated-language rule (reserve `ALWAYS`/`NEVER` for
  true invariants). Per the scope boundary, the repo convention was kept — no blanket
  absolutes were pushed into emitted templates. Flagged here for human review.
- Reference-ToC and backslash checks are intentionally warn-only (not fail) to avoid
  breaking the many existing skills with long un-ToC'd references.

Closes #13
