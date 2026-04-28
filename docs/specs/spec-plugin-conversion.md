# Spec: Convert `.claude/` to a Distributable Claude Code Plugin

## Overview

Convert the existing standalone `.claude/` config (14 skills, 5 agents, 13 hooks, 2 rules, 1 output style) into a Claude Code plugin distributed via a same-repo marketplace at `mike-diff/ai-coding-configs`. Plugin name `agent-team`, marketplace name `mike-diff`. Standalone `.claude/` is preserved as a fallback. No symlinks between standalone and plugin (silently break per docs); manual `sync.sh` script handles drift.

## Goals

1. Users can run `/plugin marketplace add mike-diff/ai-coding-configs` then `/plugin install agent-team@mike-diff` and have the full workflow available as `/agent-team:<command>`.
2. Standalone `.claude/` continues to work for users who prefer `cp -r` distribution.
3. Plugin and standalone behave identically (same hooks fire, same agents respond, same skills available).
4. Min Claude Code version: `2.1.108`.

## Technical Stack

- Claude Code 2.1.108+ plugin API (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`)
- Bash (system) for hook scripts and sync/test tooling
- `jq` (system, ubiquitous) for parsing hook input JSON
- `sed`, `grep`, `find` (system) for migration-time rewrites
- Plugin runtime variables: `${CLAUDE_PLUGIN_ROOT}` (read-only cache), `${CLAUDE_PLUGIN_DATA}` (persistent state), `$CLAUDE_PROJECT_DIR` (workspace root)

## Non-Goals (Global)

- Do NOT remove the standalone `.claude/` folder.
- Do NOT modify Cursor configs (`.cursor/`).
- Do NOT submit to the official Anthropic plugin marketplace (tier-2 distribution only).
- Do NOT rename the GitHub repo.
- Do NOT introduce a templating/build pipeline; rely on direct copies and sed.
- Do NOT port `statusline.sh` (plugin schema mismatch — only `subagentStatusLine` is honored, different shape).
- Do NOT port `env.ENABLE_PROMPT_CACHING_1H` from `settings.json` (plugin `settings.json` doesn't accept `env`). Document as user-level config in plugin README.

---

## Phase 0: Foundation

**Prerequisites:** None.

**Scope:** Create the minimal plugin/marketplace scaffolding that loads cleanly via `claude --plugin-dir`, with no real components yet. Proves the manifest schemas are valid before adding content.

**User Stories:**
- US1: As a developer, I can run `claude --plugin-dir ./plugins/agent-team --print "hello"` and Claude Code starts without manifest errors.
  - Acceptance: exit code 0, no stderr containing `manifest`, `plugin.json`, or `marketplace.json` errors.

**Functional Requirements:**
- [US1] Marketplace manifest exists at `.claude-plugin/marketplace.json` with required fields (`name`, `owner`, `plugins`).
- [US1] Plugin manifest exists at `plugins/agent-team/.claude-plugin/plugin.json` with required fields (`name`, `version`).
- [US1] `plugins/agent-team/hooks/hooks.json` exists with an empty hooks object (placeholder for later phases).
- [US1] `claude plugin validate .` from repo root returns no errors.

**Non-Goals (This Phase):** No agents, skills, hook scripts, or rules content yet. No SessionStart logic.

**Dependencies:** None.

**Implementation Guidance:**

```jsonc
// .claude-plugin/marketplace.json
{
  "name": "mike-diff",
  "owner": {
    "name": "Mike Salvati",
    "email": "cdnmikes@gmail.com"
  },
  "metadata": {
    "description": "Mike's AI coding workflow plugins",
    "version": "0.1.0"
  },
  "plugins": [
    {
      "name": "agent-team",
      "source": "./plugins/agent-team",
      "description": "Coordinated agent-team workflow: skills, agents, hooks, rules.",
      "version": "0.1.0",
      "category": "workflow",
      "keywords": ["agent-team", "workflow", "skills", "hooks"]
    }
  ]
}
```

```jsonc
// plugins/agent-team/.claude-plugin/plugin.json
{
  "name": "agent-team",
  "version": "0.1.0",
  "description": "Coordinated multi-agent workflow with skills, hooks, and structured output gates.",
  "author": {
    "name": "Mike Salvati",
    "email": "cdnmikes@gmail.com"
  },
  "homepage": "https://github.com/mike-diff/ai-coding-configs",
  "repository": "https://github.com/mike-diff/ai-coding-configs",
  "license": "MIT",
  "keywords": ["agent-team", "workflow", "claude-code"]
}
```

```jsonc
// plugins/agent-team/hooks/hooks.json
{
  "hooks": {}
}
```

**Versioning policy:** Pin `0.1.0`. Bump per user-visible change (semver). Both `marketplace.json` and `plugin.json` carry the same version; update them together.

**Tasks:**
1. [US1] Create directory `plugins/agent-team/.claude-plugin/`.
2. [US1] Create directory `plugins/agent-team/hooks/`.
3. [US1] Create directory `.claude-plugin/` at repo root.
4. [US1] Write `.claude-plugin/marketplace.json` with the schema above.
5. [US1] Write `plugins/agent-team/.claude-plugin/plugin.json` with the schema above.
6. [US1] Write `plugins/agent-team/hooks/hooks.json` with empty `hooks` object.
7. [P] Run `claude plugin validate .` from repo root and confirm no errors.

**Files to Create/Modify:**

| File | Action | Description |
|------|--------|-------------|
| `.claude-plugin/marketplace.json` | create | Marketplace manifest |
| `plugins/agent-team/.claude-plugin/plugin.json` | create | Plugin manifest |
| `plugins/agent-team/hooks/hooks.json` | create | Empty hooks placeholder |

**Success Criteria:**
- [ ] `claude --plugin-dir ./plugins/agent-team --print "test"` exits 0.
- [ ] `claude plugin list --json` (with marketplace added via `claude plugin marketplace add ./.`) lists `agent-team@mike-diff`.
- [ ] `claude plugin validate .` returns no errors.

**Verify Before Proceeding:**
- [ ] No `manifest`, `JSON syntax`, or `Required` errors in validation output.
- [ ] Plugin tree is at `plugins/agent-team/`, NOT inside `.claude-plugin/` (common mistake per docs).

---

## Phase 1: Port Shared Content (agents, output styles, rules sources)

**Prerequisites:** Phase 0 complete.

**Scope:** Copy 5 agents, 1 output style, and 2 rule files from `.claude/` into the plugin tree. Strip the per-agent `hooks:` frontmatter (forbidden in plugin agents) AND remove the same frontmatter from the standalone `.claude/agents/*.md` to keep both versions in sync. The project-level `TeammateIdle` hook in `.claude/settings.json` continues to handle structured-output gating in standalone; the plugin will get the same coverage in Phase 2.

**User Stories:**
- US1: As a Claude Code user with the plugin installed, I can see all 5 agents in `/agents` namespaced as `agent-team:explorer`, `agent-team:implementer`, etc.
  - Acceptance: each plugin agent appears with the correct name and role description.
- US2: As a Claude Code user, the `teaching` output style is available via `/output-style` when the plugin is loaded.
- US3: As a contributor maintaining both standalone and plugin versions, the agent files are byte-identical between `.claude/agents/` and `plugins/agent-team/agents/`.

**Functional Requirements:**
- [US1] All 5 agent files exist at `plugins/agent-team/agents/<name>.md` with `hooks:` removed from frontmatter.
- [US1] All 5 agent files at `.claude/agents/<name>.md` also have `hooks:` removed (kept identical to plugin versions).
- [US1] Each agent ends with a self-assertion mandating its `<*-result>` block (replaces the per-agent Stop hook gating).
- [US2] `plugins/agent-team/output-styles/teaching.md` is a byte-identical copy of `.claude/output-styles/teaching.md`.
- [US3] `plugins/agent-team/rules-source/coding-standards.md` and `plugins/agent-team/rules-source/mcp-caching.md` are byte-identical copies of the originals.

**Non-Goals (This Phase):** Skills, hook scripts, hooks.json content, SessionStart logic, sync script.

**Dependencies:** None new.

**Implementation Guidance:**

For each of the 5 agents, the current frontmatter looks like:

```yaml
---
name: explorer
description: Read-only codebase analysis teammate...
model: sonnet
tools: Read, Grep, Glob, Bash, WebFetch, WebSearch
hooks:
  Stop:
    - hooks:
        - type: command
          command: '"$CLAUDE_PROJECT_DIR"/.claude/hooks/teammate-idle.sh'
---
```

Strip the `hooks:` block and everything under it:

```yaml
---
name: explorer
description: Read-only codebase analysis teammate...
model: sonnet
tools: Read, Grep, Glob, Bash, WebFetch, WebSearch
---
```

**Inlined structured-output assertion** — append to each agent's body (above any existing closing content):

```markdown
<output_gate>
STOP. Before sending your final message to the lead or going idle, you MUST include a `<{role}-result>` block as the last element of your response. The block contains your structured findings per the project's `coding-standards.md` rule.

If you cannot produce findings (task aborted, blocked, etc.), still return an empty `<{role}-result>` block with an explanatory `<reason>` tag inside.

The project-level `TeammateIdle` hook will reject your idle attempt without this block.
</output_gate>
```

Replace `{role}` with the agent's role: `explorer`, `implementer`, `reviewer`, `qa`, or `skill-author`.

**Tasks:**
1. [US1] Create directory `plugins/agent-team/agents/`.
2. [US1] Copy `.claude/agents/{explorer,implementer,qa,reviewer,skill-author}.md` to `plugins/agent-team/agents/`.
3. [US1] Edit `plugins/agent-team/agents/*.md`: remove the `hooks:` frontmatter block (5 files).
4. [US1] Edit `plugins/agent-team/agents/*.md`: append the `<output_gate>` block with the correct `{role}` substitution per file.
5. [US1] Edit `.claude/agents/*.md`: same `hooks:` removal and `<output_gate>` append. (Keep `.claude/` and plugin agent files byte-identical.)
6. [US2] Create directory `plugins/agent-team/output-styles/`.
7. [US2] Copy `.claude/output-styles/teaching.md` to `plugins/agent-team/output-styles/teaching.md`.
8. [US3] Create directory `plugins/agent-team/rules-source/`.
9. [US3] Copy `.claude/rules/coding-standards.md` to `plugins/agent-team/rules-source/coding-standards.md`.
10. [US3] Copy `.claude/rules/mcp-caching.md` to `plugins/agent-team/rules-source/mcp-caching.md`.
11. [P] Run `diff .claude/agents/explorer.md plugins/agent-team/agents/explorer.md` (and similar for the other 4) — expect zero output.

**Files to Create/Modify:**

| File | Action | Description |
|------|--------|-------------|
| `.claude/agents/explorer.md` | modify | Remove `hooks:` frontmatter; append `<output_gate>` block |
| `.claude/agents/implementer.md` | modify | Remove `hooks:` frontmatter; append `<output_gate>` block |
| `.claude/agents/qa.md` | modify | Remove `hooks:` frontmatter; append `<output_gate>` block |
| `.claude/agents/reviewer.md` | modify | Remove `hooks:` frontmatter; append `<output_gate>` block |
| `.claude/agents/skill-author.md` | modify | Remove `hooks:` frontmatter; append `<output_gate>` block |
| `plugins/agent-team/agents/*.md` (5 files) | create | Byte-identical copies of the modified `.claude/agents/*.md` |
| `plugins/agent-team/output-styles/teaching.md` | create | Copy of `.claude/output-styles/teaching.md` |
| `plugins/agent-team/rules-source/coding-standards.md` | create | Copy of `.claude/rules/coding-standards.md` |
| `plugins/agent-team/rules-source/mcp-caching.md` | create | Copy of `.claude/rules/mcp-caching.md` |

**Success Criteria:**
- [ ] All 10 file pairs (5 agents × 2 locations) are byte-identical (`diff` returns nothing).
- [ ] No `hooks:` key remains in any agent file (`grep -l "^hooks:" .claude/agents/ plugins/agent-team/agents/` returns empty).
- [ ] Each agent file contains a `<output_gate>` block with the correct role name.
- [ ] `claude --plugin-dir ./plugins/agent-team --print "list agents"` causes Claude to mention the 5 plugin-namespaced agents (smoke check).

**Verify Before Proceeding:**
- [ ] All 5 agent files compile (no YAML frontmatter errors). Run `claude plugin validate .`.
- [ ] Standalone `.claude/agents/` still works after the strip — open the existing setup in a Claude Code session and confirm the project-level `TeammateIdle` hook in `settings.json` still gates teammate close-outs.

---

## Phase 2: Port Hooks (scripts + hooks.json)

**Prerequisites:** Phase 0 complete.

**Scope:** Copy all 13 hook scripts to `plugins/agent-team/hooks/`. Apply uniform sed pattern to redirect log paths to a dual-mode env-fallback variable that works in both standalone and plugin contexts. Adapt `session-start.sh` and `notify-compact.sh` for plugin context. Wire all 11 hook events via `hooks/hooks.json` using `${CLAUDE_PLUGIN_ROOT}` paths.

**User Stories:**
- US1: As a developer with the plugin installed, all hook events that fire in standalone also fire in plugin mode (same enforcement, same logging).
- US2: As a developer using the standalone `.claude/`, hooks continue to work unchanged after the log-path refactor.
- US3: As a developer, plugin hook logs land at `~/.claude/plugins/data/agent-team-mike-diff/logs/` (not `.claude/.logs/` in the workspace).

**Functional Requirements:**
- [US1] All 13 hook scripts at `plugins/agent-team/hooks/<name>.sh` are byte-identical to `.claude/hooks/<name>.sh` after the log-path sed pass (one source of truth content; plugin-context vs standalone-context is differentiated by env var presence).
- [US1] `plugins/agent-team/hooks/hooks.json` wires 11 events using `${CLAUDE_PLUGIN_ROOT}` paths.
- [US2] Hook scripts in `.claude/hooks/` retain their behavior under standalone (logs go to `${CLAUDE_PROJECT_DIR}/.claude/.logs/`).
- [US3] Plugin hook scripts write logs to `${CLAUDE_PLUGIN_DATA}/logs/` when invoked through the plugin.

**Non-Goals (This Phase):** SessionStart rules-injection (Phase 4). Skills migration (Phase 3). Sync script (Phase 5).

**Dependencies:** Phase 0 plugin manifest.

**Implementation Guidance:**

**Uniform log-path sed pass.** Every hook script currently has a line like:

```bash
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
```

Replace it across all 13 scripts (in BOTH `.claude/hooks/` and `plugins/agent-team/hooks/`) with the env-fallback pattern:

```bash
LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"
```

Add `mkdir -p "$LOG_DIR"` if not already present (defensive: plugin data dir exists on first reference per docs, but this avoids a race if scripts run before any other plugin process has touched it).

Sed command:
```bash
# Run from repo root
for f in .claude/hooks/*.sh; do
  sed -i '' 's|LOG_DIR="\${CLAUDE_PROJECT_DIR:-\.}/\.claude/\.logs"|LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"|g' "$f"
done
```

(macOS `sed -i ''`; on Linux drop the `''`.)

**Adapt `session-start.sh`.** Current behavior iterates `${CLAUDE_PROJECT_DIR}/.claude/hooks/` and `chmod +x` each script. Under plugin context, this read-only cache makes that misfire. Wrap with a context check:

```bash
# at session-start.sh line ~7, replace HOOKS_DIR resolution with:
if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
  HOOKS_DIR="$CLAUDE_PLUGIN_ROOT/hooks"
  # Plugin context: scripts are pre-installed via cache copy; skip the chmod loop
  SKIP_EXEC_CHECK=1
else
  HOOKS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks"
  SKIP_EXEC_CHECK=0
fi

# the chmod loop becomes:
if [ "$SKIP_EXEC_CHECK" = "0" ]; then
  for hook in "$HOOKS_DIR"/*.sh; do
    [ -x "$hook" ] || chmod +x "$hook" 2>/dev/null
  done
fi
```

**Adapt `notify-compact.sh`.** Currently reads `${CLAUDE_PROJECT_DIR:-.}/.claude/rules` to enumerate surviving rule files. In plugin context, rules live at `${CLAUDE_PLUGIN_ROOT}/rules-source/`. Add a context check:

```bash
# at notify-compact.sh line ~25, replace RULES_DIR resolution with:
if [ -n "$CLAUDE_PLUGIN_ROOT" ] && [ -d "$CLAUDE_PLUGIN_ROOT/rules-source" ]; then
  RULES_DIR="$CLAUDE_PLUGIN_ROOT/rules-source"
else
  RULES_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/rules"
fi
```

**`hooks/hooks.json`.** Mirror the event wiring from `.claude/settings.json`. Use `${CLAUDE_PLUGIN_ROOT}` paths so the plugin's installed cache copy is referenced (not the workspace).

```jsonc
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh" },
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/inject-rules.sh" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/block-dangerous.sh" },
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/validate-commit.sh" }
        ]
      },
      {
        "matcher": "Read",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/redact-secrets.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/post-edit-lint.sh" }
        ]
      }
    ],
    "PermissionDenied": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/permission-denied.sh" } ] }
    ],
    "TeammateIdle": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/teammate-idle.sh" } ] }
    ],
    "TaskCompleted": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/task-completed.sh" } ] }
    ],
    "PreCompact": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/notify-compact.sh" } ] }
    ],
    "FileChanged": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/file-changed.sh" } ] }
    ],
    "CwdChanged": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/cwd-changed.sh" } ] }
    ],
    "TaskCreated": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/task-created.sh" } ] }
    ],
    "StopFailure": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/stop-failure.sh" } ] }
    ]
  }
}
```

`SessionStart` includes both `session-start.sh` and a forthcoming `inject-rules.sh` (Phase 4 creates it). The reference is forward — Phase 4 must complete before this hooks.json reference resolves at runtime, but the file can list both now since execution is deferred until the hook fires.

**Tasks:**
1. [US2] Run sed across `.claude/hooks/*.sh` to apply the log-path env-fallback pattern.
2. [P] Verify standalone hooks still write logs correctly: open a Claude Code session in `.claude/`, trigger any tool use, confirm logs land at `${CLAUDE_PROJECT_DIR}/.claude/.logs/hooks.log` (not `${CLAUDE_PLUGIN_DATA}/logs/`).
3. [US1] Copy all 13 modified `.claude/hooks/*.sh` to `plugins/agent-team/hooks/` (byte-identical copies post-sed).
4. [US1] Apply `chmod +x` to all 13 plugin hook scripts.
5. [US1] Edit `plugins/agent-team/hooks/session-start.sh` per the plugin-context check shown above.
6. [US1] Edit `plugins/agent-team/hooks/notify-compact.sh` per the plugin-context check shown above.
7. [US2] Apply the same `session-start.sh` and `notify-compact.sh` edits to `.claude/hooks/` versions (keep byte-identical post-modification).
8. [US1] Re-copy from `.claude/hooks/` to `plugins/agent-team/hooks/` to restore byte-identity after any drift.
9. [US1] Replace `plugins/agent-team/hooks/hooks.json` content with the schema above (overwrites Phase 0's empty placeholder).
10. [P] Confirm with `diff -r .claude/hooks/ plugins/agent-team/hooks/` — expect only `hooks.json` to differ (it doesn't exist in `.claude/hooks/`).

**Files to Create/Modify:**

| File | Action | Description |
|------|--------|-------------|
| `.claude/hooks/*.sh` (13 files) | modify | Apply uniform log-path sed pass; adapt `session-start.sh` and `notify-compact.sh` for plugin-context |
| `plugins/agent-team/hooks/*.sh` (13 files) | create | Byte-identical copies of modified `.claude/hooks/*.sh` |
| `plugins/agent-team/hooks/hooks.json` | modify | Replace empty placeholder with full event wiring |

**Success Criteria:**
- [ ] `diff -r .claude/hooks/ plugins/agent-team/hooks/` shows only `hooks.json` as a difference (it's plugin-only).
- [ ] All plugin hook scripts are executable (`find plugins/agent-team/hooks -name "*.sh" ! -perm -u+x` returns empty).
- [ ] `claude plugin validate .` returns no errors after writing `hooks.json`.
- [ ] Smoke test: in plugin mode, trigger a `PreToolUse` event (any Bash command); confirm `${CLAUDE_PLUGIN_DATA}/logs/hooks.log` is created and written to.
- [ ] Standalone behavior unchanged: in `.claude/` workspace, trigger a tool use, confirm `.claude/.logs/hooks.log` continues to receive entries.

**Verify Before Proceeding:**
- [ ] No hook script references the old hardcoded path `${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"` anywhere (`grep -r ':-\.}/\.claude/\.logs' .claude/hooks/ plugins/agent-team/hooks/` returns empty).
- [ ] Both `session-start.sh` versions branch on `$CLAUDE_PLUGIN_ROOT` correctly.
- [ ] `notify-compact.sh` reads from `${CLAUDE_PLUGIN_ROOT}/rules-source/` when in plugin context.

---

## Phase 3: Port Skills with Namespace Rewrites

**Prerequisites:** Phase 0 complete. Phase 1 not strictly required but recommended for clean ordering (skills reference agents).

**Scope:** Copy all 14 skill directories from `.claude/skills/` to `plugins/agent-team/skills/`. Apply sed pattern to rewrite ~97 slash-command cross-references to the `/agent-team:<command>` form. Rewrite hardcoded `bash .claude/skills/...validate-skill.sh` paths in `skills/skill/SKILL.md` to use `${CLAUDE_PLUGIN_ROOT}`. Standalone `.claude/skills/` is left untouched (continues to use unprefixed `/discuss`, etc.).

**User Stories:**
- US1: As a Claude Code user with the plugin installed, every command is invocable as `/agent-team:<command>` and works end-to-end.
- US2: As a Claude Code user, skill cross-references inside SKILL.md files use the correctly-prefixed form so the model invokes the right command.
- US3: As a developer creating a new skill via `/agent-team:skill`, the validate-skill.sh script runs from the plugin cache, validating a new skill written into the user's workspace.

**Functional Requirements:**
- [US1] All 14 skill directories exist at `plugins/agent-team/skills/<name>/SKILL.md` (with sub-files like `references/*.md` copied recursively).
- [US2] No bare slash-command reference in plugin skills matches the pattern `/(<skill-names>)\b` (i.e., everything is prefixed). Verified by post-rewrite grep.
- [US3] `plugins/agent-team/skills/skill/SKILL.md` references the validator script via `${CLAUDE_PLUGIN_ROOT}/skills/skill/scripts/validate-skill.sh` and writes new skills to `${CLAUDE_PROJECT_DIR}/.claude/skills/<name>/`.
- [US3] `plugins/agent-team/agents/skill-author.md` is updated with the same path rewrite (this file came over in Phase 1 as a copy of standalone — needs the plugin-specific path adjustment now).

**Non-Goals (This Phase):** Standalone `.claude/skills/` modifications. Sync script. Smoke test harness.

**Dependencies:** None new.

**Implementation Guidance:**

**Skill name list (14 total):**
```
ask, code-review, dev, discuss, issue, loop-patterns, orient, primitives,
skill, spec, team-orchestration, testing-patterns, ticket, to-dos
```

**Sed pattern for namespace prefix rewrite.** The pattern needs to:
- Match `/<skill-name>` followed by a word boundary
- NOT match if already prefixed (`/agent-team:discuss` should not become `/agent-team:agent-team:discuss`)
- NOT match inside file paths or URLs

Use a lookahead-style approach (gnu sed required, or use perl):

```bash
# Run from repo root after copying skills to plugins/agent-team/skills/
SKILL_NAMES='ask|code-review|dev|discuss|issue|loop-patterns|orient|primitives|skill|spec|team-orchestration|testing-patterns|ticket|to-dos'

# Use perl for reliable lookahead/lookbehind regex
find plugins/agent-team/skills -name "*.md" -exec perl -i -pe \
  "s{(?<![:/\w-])/($SKILL_NAMES)\b(?!:)}{/agent-team:\$1}g" {} +
```

The lookbehind `(?<![:/\w-])` prevents matching inside file paths and URLs. The lookahead `(?!:)` prevents double-prefixing.

**Verification grep:** After the rewrite, ensure no unprefixed references remain:

```bash
SKILL_NAMES='ask|code-review|dev|discuss|issue|loop-patterns|orient|primitives|skill|spec|team-orchestration|testing-patterns|ticket|to-dos'
grep -rE "(^|[^:/\w-])/($SKILL_NAMES)\b" plugins/agent-team/skills | grep -v "/agent-team:" || echo "Clean: no unprefixed refs"
```

**Hardcoded path rewrites in `plugins/agent-team/skills/skill/SKILL.md`:**

Current (~6 lines, search the file for `.claude/`):
```bash
ls -la .claude/skills/[name]/
bash .claude/skills/skill/scripts/validate-skill.sh .claude/skills/[name]/
```

Plugin replacements:
```bash
ls -la "${CLAUDE_PROJECT_DIR}/.claude/skills/[name]/"
bash "${CLAUDE_PLUGIN_ROOT}/skills/skill/scripts/validate-skill.sh" "${CLAUDE_PROJECT_DIR}/.claude/skills/[name]/"
```

The validator script lives in the plugin (read-only); the new skill is created in the user's workspace `.claude/skills/[name]/` (writable).

**Same rewrites apply to `plugins/agent-team/agents/skill-author.md`** at lines ~123 and ~157 (per scout findings).

**Tasks:**
1. [US1] Create directory `plugins/agent-team/skills/`.
2. [US1] Recursively copy all 14 skill directories from `.claude/skills/` to `plugins/agent-team/skills/` (preserve file structure including `references/` subdirs and any `scripts/` subdirs).
3. [US2] Run the perl rewrite command above across all `.md` files under `plugins/agent-team/skills/`.
4. [US2] Run the verification grep; confirm clean output.
5. [US3] Edit `plugins/agent-team/skills/skill/SKILL.md`: rewrite the ~6 hardcoded `.claude/skills/...` paths to the plugin-context forms shown above.
6. [US3] Edit `plugins/agent-team/agents/skill-author.md`: rewrite the 2 hardcoded paths similarly.
7. [P] Confirm with `claude plugin validate .` no errors.

**Files to Create/Modify:**

| File | Action | Description |
|------|--------|-------------|
| `plugins/agent-team/skills/<name>/` (14 dirs) | create | Recursive copy from `.claude/skills/` |
| `plugins/agent-team/skills/**/*.md` | modify | Sed pass for `/agent-team:` namespace prefix |
| `plugins/agent-team/skills/skill/SKILL.md` | modify | Hardcoded path rewrites (~6 occurrences) |
| `plugins/agent-team/agents/skill-author.md` | modify | Hardcoded path rewrites (2 occurrences at L123, L157) |

**Success Criteria:**
- [ ] 14 skill directories exist under `plugins/agent-team/skills/`.
- [ ] Verification grep returns "Clean: no unprefixed refs".
- [ ] No `.claude/skills/` literal remains in `plugins/agent-team/skills/skill/SKILL.md` or `plugins/agent-team/agents/skill-author.md` (`grep -l '\.claude/skills/' plugins/agent-team/{skills/skill/SKILL.md,agents/skill-author.md}` returns empty).
- [ ] `claude plugin validate .` reports no skill schema errors.

**Verify Before Proceeding:**
- [ ] Spot-check 3 random skill files: open them, find a known cross-reference, confirm it now reads `/agent-team:<name>`.
- [ ] No accidental rewrites in URLs or file paths (search for `/agent-team:` followed by `/` or `.` or other suspicious chars).

---

## Phase 4: SessionStart Rules-Injection + Prerequisite Check

**Prerequisites:** Phases 0, 1, 2 complete.

**Scope:** Write the new `inject-rules.sh` hook script that (a) cats `rules-source/*.md` content to stdout for SessionStart context injection, AND (b) warns to stderr if `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is unset (which would silently break agent functionality).

**User Stories:**
- US1: As a user starting a fresh Claude Code session with the plugin enabled, the agents see the contents of `coding-standards.md` and `mcp-caching.md` in their initial context.
- US2: As a user who installed the plugin without setting `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, I see a clear warning at session start telling me to add the env var.

**Functional Requirements:**
- [US1] `plugins/agent-team/hooks/inject-rules.sh` exists, is executable, and emits the contents of `rules-source/*.md` to stdout when run.
- [US1] The hook is wired into the SessionStart event in `hooks/hooks.json` (already declared in Phase 2; this phase fills in the script).
- [US2] The hook checks `$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` and prints a stderr warning if unset or empty.
- [US1] The hook detects whether it's running in plugin context (`$CLAUDE_PLUGIN_ROOT` set) vs standalone (skips itself if standalone).

**Non-Goals (This Phase):** Modifications to existing hook scripts. UserPromptSubmit fallback for issue #10373 (deferred).

**Dependencies:** None new.

**Implementation Guidance:**

```bash
#!/usr/bin/env bash
# plugins/agent-team/hooks/inject-rules.sh
# SessionStart hook: emits plugin-shipped rules to stdout (becomes context per docs),
# and warns if the prerequisite env var for Agent Teams is unset.

set -euo pipefail

# Standalone context: rules are auto-loaded from .claude/rules/, skip injection.
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  exit 0
fi

RULES_DIR="$CLAUDE_PLUGIN_ROOT/rules-source"

# Prerequisite check: warn if Agent Teams env var is missing.
if [ -z "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" ]; then
  cat >&2 <<'WARN'
[agent-team plugin] WARNING: $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS is not set.
Multi-agent workflows (the explorer/implementer/reviewer/qa teammates) require this
environment variable to function. Add the following to your user-level
~/.claude/settings.json:

  {
    "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }
  }

Restart Claude Code for the change to take effect.
WARN
fi

# Inject rules content as context. SessionStart stdout is appended to the model's context.
if [ -d "$RULES_DIR" ]; then
  echo "# Project Rules (loaded from agent-team plugin)"
  echo
  for rule_file in "$RULES_DIR"/*.md; do
    [ -f "$rule_file" ] || continue
    echo "## $(basename "$rule_file" .md)"
    echo
    cat "$rule_file"
    echo
  done
fi
```

**Tasks:**
1. [US1] Write `plugins/agent-team/hooks/inject-rules.sh` per the script above.
2. [US1] `chmod +x plugins/agent-team/hooks/inject-rules.sh`.
3. [P] Verify the script works in isolation: `CLAUDE_PLUGIN_ROOT=$(pwd)/plugins/agent-team bash plugins/agent-team/hooks/inject-rules.sh` should emit `# Project Rules ...` followed by both rule files' contents.
4. [P] Verify the warning fires when env var is unset: `unset CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS && CLAUDE_PLUGIN_ROOT=$(pwd)/plugins/agent-team bash plugins/agent-team/hooks/inject-rules.sh 2>&1 1>/dev/null` should print the WARN block.
5. [P] Verify standalone bypass: `unset CLAUDE_PLUGIN_ROOT && bash plugins/agent-team/hooks/inject-rules.sh` should exit 0 silently with no stdout.
6. [P] End-to-end: `claude --plugin-dir ./plugins/agent-team --print "What rules are loaded in your context? Reply with the names of any rule files you can see."` — Claude should mention `coding-standards` and `mcp-caching`.

**Files to Create/Modify:**

| File | Action | Description |
|------|--------|-------------|
| `plugins/agent-team/hooks/inject-rules.sh` | create | New SessionStart hook for rules injection + prereq check |

**Success Criteria:**
- [ ] Standalone runs of the script (no `CLAUDE_PLUGIN_ROOT`) exit 0 silently.
- [ ] Plugin runs of the script emit both rule files' content on stdout.
- [ ] Missing `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` triggers the stderr warning.
- [ ] End-to-end check: Claude session via `--plugin-dir` shows knowledge of the rule contents.

**Verify Before Proceeding:**
- [ ] Manual interactive smoke test: open a fresh `claude` interactive session via `claude --plugin-dir ./plugins/agent-team`, ask Claude to recite anything from `coding-standards.md`. If interactive `SessionStart` doesn't fire (issue #10373 reproes), record the failure and switch the hook event to `UserPromptSubmit` in `hooks/hooks.json` as the fallback.
- [ ] No regression in standalone mode: `cd` into a workspace with `.claude/` only (no plugin), confirm rules still auto-load (workspace-relative, not plugin-shipped).

---

## Phase 5: Sync Script + Smoke Tests

**Prerequisites:** Phases 0, 1, 2, 3, 4 complete.

**Scope:** Build a `scripts/sync-plugin.sh` that re-runs the migration steps (copy files, apply sed patterns, redo path rewrites) idempotently. Build `tests/smoke.sh` that invokes each `/agent-team:<command>` via `claude --print` and asserts non-empty success.

**User Stories:**
- US1: As a maintainer editing a skill in `.claude/skills/discuss/`, running `bash scripts/sync-plugin.sh` brings `plugins/agent-team/` back to a consistent state without manual intervention.
- US2: As a maintainer about to commit, running `bash tests/smoke.sh` executes each plugin command end-to-end and reports pass/fail per command.

**Functional Requirements:**
- [US1] `scripts/sync-plugin.sh` is idempotent — running it twice produces the same result.
- [US1] The sync script copies agents, skills, hooks, output-styles, rules-source from `.claude/` to `plugins/agent-team/` (with appropriate transforms).
- [US1] The sync script applies the namespace prefix sed pattern to skills.
- [US1] The sync script reapplies the hardcoded-path rewrites in `skills/skill/SKILL.md` and `agents/skill-author.md`.
- [US1] The sync script does NOT overwrite hand-edited plugin files unrelated to the source (e.g., it leaves `plugins/agent-team/.claude-plugin/plugin.json` and `plugins/agent-team/hooks/hooks.json` untouched).
- [US2] `tests/smoke.sh` invokes all 10 slash commands (skills with `disable-model-invocation: true`) and asserts exit 0.
- [US2] The smoke test produces a clear summary (e.g., `10/10 passed` or `8/10 passed: failed: skill, ticket`).

**Non-Goals (This Phase):** Documentation (Phase 6). Marketplace registration in Claude Code's user config.

**Dependencies:** None new.

**Implementation Guidance:**

**Slash-command list for smoke tests (10 user-invokable commands):**
```
ask, dev, discuss, issue, orient, primitives, skill, spec, ticket, to-dos
```

(`code-review`, `loop-patterns`, `team-orchestration`, `testing-patterns` are semantic skills that auto-activate; not directly invoked.)

**`scripts/sync-plugin.sh`:**

```bash
#!/usr/bin/env bash
# scripts/sync-plugin.sh
# Sync the plugin tree from the standalone .claude/ source.
# Idempotent: safe to run multiple times.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/.claude"
DST="$REPO_ROOT/plugins/agent-team"

SKILL_NAMES='ask|code-review|dev|discuss|issue|loop-patterns|orient|primitives|skill|spec|team-orchestration|testing-patterns|ticket|to-dos'

echo "Syncing $SRC -> $DST"

# 1. Agents (byte-identical, hooks: already stripped from source)
mkdir -p "$DST/agents"
cp -R "$SRC/agents/." "$DST/agents/"

# 2. Output styles (byte-identical)
mkdir -p "$DST/output-styles"
cp -R "$SRC/output-styles/." "$DST/output-styles/"

# 3. Rules source (byte-identical)
mkdir -p "$DST/rules-source"
cp -R "$SRC/rules/." "$DST/rules-source/"

# 4. Hooks (byte-identical, log-path env-fallback already in source)
mkdir -p "$DST/hooks"
# preserve hooks.json (plugin-only, not in source)
HOOKS_JSON_BACKUP=""
if [ -f "$DST/hooks/hooks.json" ]; then
  HOOKS_JSON_BACKUP="$(cat "$DST/hooks/hooks.json")"
fi
cp -R "$SRC/hooks/." "$DST/hooks/"
# restore hooks.json
if [ -n "$HOOKS_JSON_BACKUP" ]; then
  printf '%s\n' "$HOOKS_JSON_BACKUP" > "$DST/hooks/hooks.json"
fi
# preserve inject-rules.sh (plugin-only)
# (it's in $DST/hooks already and not in $SRC/hooks, so the cp -R won't overwrite it)
chmod +x "$DST/hooks/"*.sh

# 5. Skills (copy + namespace prefix sed + hardcoded path rewrites)
mkdir -p "$DST/skills"
# Clear destination first to avoid stale files when source removes a skill
rm -rf "$DST/skills/"*
cp -R "$SRC/skills/." "$DST/skills/"

# Apply namespace prefix to all .md files in plugin skills
find "$DST/skills" -name "*.md" -exec perl -i -pe \
  "s{(?<![:/\w-])/($SKILL_NAMES)\b(?!:)}{/agent-team:\$1}g" {} +

# Hardcoded path rewrites in skill/SKILL.md
perl -i -pe \
  "s{ls -la \.claude/skills/}{ls -la \"\$\{CLAUDE_PROJECT_DIR\}/.claude/skills/}g; \
   s{bash \.claude/skills/skill/scripts/validate-skill\.sh \.claude/skills/}{bash \"\$\{CLAUDE_PLUGIN_ROOT\}/skills/skill/scripts/validate-skill.sh\" \"\$\{CLAUDE_PROJECT_DIR\}/.claude/skills/}g" \
  "$DST/skills/skill/SKILL.md"

# Same rewrites in skill-author.md (already copied to $DST/agents/ in step 1)
perl -i -pe \
  "s{bash \.claude/skills/skill/scripts/validate-skill\.sh \.claude/skills/}{bash \"\$\{CLAUDE_PLUGIN_ROOT\}/skills/skill/scripts/validate-skill.sh\" \"\$\{CLAUDE_PROJECT_DIR\}/.claude/skills/}g" \
  "$DST/agents/skill-author.md"

# 6. Verification: no unprefixed slash-command refs in plugin skills
UNPREFIXED=$(grep -rE "(^|[^:/\w-])/($SKILL_NAMES)\b" "$DST/skills" | grep -v "/agent-team:" || true)
if [ -n "$UNPREFIXED" ]; then
  echo "WARNING: unprefixed slash-command references remain:" >&2
  echo "$UNPREFIXED" >&2
  exit 1
fi

echo "Sync complete."
```

**`tests/smoke.sh`:**

```bash
#!/usr/bin/env bash
# tests/smoke.sh
# End-to-end smoke test: invokes each plugin slash command, asserts exit 0.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/agent-team"

COMMANDS=(ask dev discuss issue orient primitives skill spec ticket to-dos)

PASS=0
FAIL=0
FAIL_LIST=()

for cmd in "${COMMANDS[@]}"; do
  printf "Testing /agent-team:%-20s ... " "$cmd"
  output=$(claude --plugin-dir "$PLUGIN_DIR" --print "/agent-team:$cmd --help" 2>&1)
  exit_code=$?
  if [ "$exit_code" -eq 0 ] && [ -n "$output" ]; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL (exit=$exit_code)"
    FAIL=$((FAIL + 1))
    FAIL_LIST+=("$cmd")
  fi
done

echo
echo "Result: $PASS/${#COMMANDS[@]} passed"
if [ "$FAIL" -gt 0 ]; then
  echo "Failed: ${FAIL_LIST[*]}"
  exit 1
fi
```

**Tasks:**
1. [US1] Create directory `scripts/`.
2. [US1] Write `scripts/sync-plugin.sh` per the script above.
3. [US1] `chmod +x scripts/sync-plugin.sh`.
4. [US1] Run the sync script once; confirm no errors and confirm plugin tree is unchanged (since we already populated it manually in Phases 1-3).
5. [US1] Run the sync script a second time (idempotency check); confirm no errors and identical result.
6. [US2] Create directory `tests/`.
7. [US2] Write `tests/smoke.sh` per the script above.
8. [US2] `chmod +x tests/smoke.sh`.
9. [US2] Run `bash tests/smoke.sh`; confirm 10/10 passed (or investigate any failures).

**Files to Create/Modify:**

| File | Action | Description |
|------|--------|-------------|
| `scripts/sync-plugin.sh` | create | Idempotent sync from `.claude/` to plugin tree |
| `tests/smoke.sh` | create | End-to-end command invocation tests |

**Success Criteria:**
- [ ] Sync script runs twice with identical output the second time (idempotent).
- [ ] Sync script preserves `plugins/agent-team/.claude-plugin/plugin.json` and `plugins/agent-team/hooks/hooks.json` (does not overwrite plugin-only files).
- [ ] Smoke test reports `10/10 passed`.
- [ ] After running sync, smoke test still passes (no regressions introduced by the sync).

**Verify Before Proceeding:**
- [ ] `git status` after running sync shows no changes (since plugin already synced from manual phases).
- [ ] No accidental destructive operations in sync script (test on a worktree or branch first).

---

## Phase 6: Documentation

**Prerequisites:** Phases 0-5 complete.

**Scope:** Write the plugin's `README.md` documenting install, dev loop, log location, prerequisite env var, and what doesn't auto-port. Update the top-level repo `README.md` to mention both install paths.

**User Stories:**
- US1: As a new user discovering this repo on GitHub, I can read the top-level README and understand how to install either the standalone `.claude/` or the plugin.
- US2: As someone who installed the plugin, I can read the plugin README and find: install command, dev loop, log location, prerequisites, and known limitations.
- US3: As a contributor wanting to hack on the plugin, the README explains the `--plugin-dir` workflow for live edits and the `scripts/sync-plugin.sh` workflow for syncing changes from standalone.

**Functional Requirements:**
- [US1] Top-level `README.md` has a "Two install paths" section with copy-pasteable commands for both.
- [US2] `plugins/agent-team/README.md` documents the install command, dev loop, log location (`~/.claude/plugins/data/agent-team-mike-diff/logs/`), prerequisite env var, and what doesn't auto-port.
- [US3] Both READMEs link to each other and to relevant Claude Code documentation.

**Non-Goals (This Phase):** Code changes. Bumping version (this comes with the merge of all phases).

**Dependencies:** None new.

**Implementation Guidance:**

**`plugins/agent-team/README.md` outline:**

```markdown
# agent-team — Claude Code Plugin

Coordinated multi-agent workflow with skills, hooks, and structured output gates.
Plugin version of the standalone `.claude/` config.

## Install

\`\`\`bash
/plugin marketplace add mike-diff/ai-coding-configs
/plugin install agent-team@mike-diff
\`\`\`

After install, all commands are namespaced: `/agent-team:discuss`, `/agent-team:dev`, etc.

## Prerequisites

- Claude Code 2.1.108 or later (verify with `claude --version`).
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set in your **user-level** `~/.claude/settings.json`:
  \`\`\`json
  { "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
  \`\`\`
  Without this, multi-agent workflows silently fail. The plugin's SessionStart hook will warn you if it's missing.

## What This Plugin Provides

- 14 skills: see [list]
- 5 specialized agents: explorer, implementer, qa, reviewer, skill-author
- 13 hooks across 11 lifecycle events
- 1 output style: teaching
- 2 rules: coding-standards, mcp-caching (auto-injected via SessionStart hook)

## What This Plugin Does NOT Provide

These shipped with the standalone `.claude/` but cannot ship via the plugin schema:

- **`statusline.sh`** — plugin schema doesn't accept arbitrary statuslines. To get the same statusline, copy `.claude/statusline.sh` from the source repo into your project and configure it manually in `.claude/settings.json`.
- **`env.ENABLE_PROMPT_CACHING_1H`** — plugin `settings.json` doesn't accept env vars. Set this in your user-level `~/.claude/settings.json` if desired.

## Logs

Plugin hook logs are written to `~/.claude/plugins/data/agent-team-mike-diff/logs/`:
- `hooks.log` — most events
- `tasks.log` — task-related events
- `permission-denied.log` — denied tool calls
- `stop-failures.log` — API errors

The directory is created automatically on first run.

## Hacking on This Plugin

Clone the source repo, then point Claude Code at your local copy:

\`\`\`bash
git clone https://github.com/mike-diff/ai-coding-configs.git
cd ai-coding-configs
claude --plugin-dir ./plugins/agent-team
\`\`\`

Live edits are picked up via `/reload-plugins` (no restart needed).

To sync changes from the standalone `.claude/` into the plugin:

\`\`\`bash
bash scripts/sync-plugin.sh
\`\`\`

To run the smoke test:

\`\`\`bash
bash tests/smoke.sh
\`\`\`

## Known Limitations

- **SessionStart hook on brand-new sessions** ([issue #10373](https://github.com/anthropics/claude-code/issues/10373)): some CC versions only fire SessionStart on `/clear`, `/compact`, or resume. If rules don't appear in your context, switch the `inject-rules.sh` hook to `UserPromptSubmit` in `hooks/hooks.json` (one-line change).
- **Per-agent Stop hooks unavailable**: plugin agents cannot declare `hooks:` frontmatter. Structured output is enforced via inlined assertions and the project-level `TeammateIdle` hook in `hooks/hooks.json`.

## See Also

- [Top-level repo README](../../README.md) — both install paths
- [Claude Code plugin docs](https://code.claude.com/docs/en/plugins)
```

**Top-level `README.md` update** — add a new section near the top:

```markdown
## Install

Two paths, pick one:

### Option A — Plugin (recommended for sharing)

\`\`\`bash
/plugin marketplace add mike-diff/ai-coding-configs
/plugin install agent-team@mike-diff
\`\`\`

Commands surface as `/agent-team:discuss`, `/agent-team:dev`, etc.
See [plugin README](./plugins/agent-team/README.md) for details.

### Option B — Standalone (drop-in, unprefixed commands)

\`\`\`bash
git clone https://github.com/mike-diff/ai-coding-configs.git
cp -r ai-coding-configs/.claude/ /path/to/your/project/
\`\`\`

Commands surface as `/discuss`, `/dev`, etc.
See [.claude/README.md](.claude/README.md) for details.
```

**Tasks:**
1. [US2] Create `plugins/agent-team/README.md` per the outline above.
2. [US1] Edit top-level `README.md`: add the "Install" section.
3. [US3] Cross-link both READMEs.
4. [P] Review both READMEs for accuracy: install commands, log paths, version numbers, file paths.

**Files to Create/Modify:**

| File | Action | Description |
|------|--------|-------------|
| `plugins/agent-team/README.md` | create | Plugin install/usage/limitations docs |
| `README.md` (top-level) | modify | Add "Install" section with both paths |

**Success Criteria:**
- [ ] Plugin README install commands work copy-pasted (test on a fresh shell).
- [ ] All file paths in READMEs resolve (test with markdown link checker or manual click-through on GitHub).
- [ ] Top-level README clearly differentiates the two install options.

**Verify Before Proceeding:**
- [ ] All commands in READMEs match what was implemented in earlier phases.
- [ ] Version numbers (0.1.0) match `plugin.json` and `marketplace.json`.

---

## Phase Ordering Notes

- **Phases 0, 1, 2** can run in parallel (each touches independent files); recommend sequential for sanity-checking.
- **Phase 3** depends on Phase 0 (plugin manifest must validate); does NOT depend on Phase 1 or 2 strictly.
- **Phase 4** depends on Phases 0, 1, 2.
- **Phase 5** depends on all prior phases (the sync script must reproduce all transforms; smoke test must hit all commands).
- **Phase 6** is documentation, runs last.

Each phase is independently verifiable. A `/dev "Implement Phase N" @docs/specs/spec-plugin-conversion.md` invocation has 100% of the context needed without reading other phases.
