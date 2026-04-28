# agent-team — Claude Code Plugin

Coordinated multi-agent workflow with skills, hooks, and structured output gates.
Plugin version of the standalone `.claude/` config at `mike-diff/ai-coding-configs`.

## Install

```bash
/plugin marketplace add mike-diff/ai-coding-configs
/plugin install agent-team@mike-diff
```

After install, all commands are namespaced: `/agent-team:discuss`, `/agent-team:dev`, `/agent-team:spec`, etc.

## Prerequisites

- Claude Code 2.1.108 or later (verify with `claude --version`).
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set in your **user-level** `~/.claude/settings.json`:

  ```json
  { "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
  ```

  Without this, multi-agent workflows silently fail. The plugin's SessionStart hook will warn you if it's missing.

## What This Plugin Provides

- **14 skills** — `ask`, `code-review`, `dev`, `discuss`, `issue`, `loop-patterns`, `orient`, `primitives`, `skill`, `spec`, `team-orchestration`, `testing-patterns`, `ticket`, `to-dos`
- **5 specialized agents** — `explorer`, `implementer`, `qa`, `reviewer`, `skill-author`
- **13 hooks** across 11 lifecycle events (`SessionStart`, `PreToolUse`, `PostToolUse`, `PermissionDenied`, `TeammateIdle`, `TaskCompleted`, `PreCompact`, `FileChanged`, `CwdChanged`, `TaskCreated`, `StopFailure`)
- **1 output style** — `teaching`
- **2 rules** — `coding-standards`, `mcp-caching` (auto-injected via SessionStart hook)

## What This Plugin Does NOT Provide

These shipped with the standalone `.claude/` but cannot ship via the plugin schema:

- **`statusline.sh`** — plugin schema doesn't accept arbitrary statuslines (only `subagentStatusLine`, different shape). To get the same statusline, copy `.claude/statusline.sh` from the source repo into your project and configure it manually in `.claude/settings.json`.
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

```bash
git clone https://github.com/mike-diff/ai-coding-configs.git
cd ai-coding-configs
claude --plugin-dir ./plugins/agent-team
```

Live edits are picked up via `/reload-plugins` (no restart needed).

To sync changes from the standalone `.claude/` into the plugin:

```bash
bash scripts/sync-plugin.sh
```

To run the smoke test:

```bash
bash tests/smoke.sh
```

## Known Limitations

- **SessionStart hook on brand-new sessions** ([issue #10373](https://github.com/anthropics/claude-code/issues/10373)): some Claude Code versions only fire SessionStart on `/clear`, `/compact`, or resume. If rules don't appear in your context, switch the `inject-rules.sh` hook to `UserPromptSubmit` in `hooks/hooks.json` (one-line change).
- **Per-agent Stop hooks unavailable**: plugin agents cannot declare `hooks:` frontmatter (security restriction). Structured output is enforced via inlined `<output_gate>` assertions in each agent prompt and the project-level `TeammateIdle` hook in `hooks/hooks.json`.

## See Also

- [Top-level repo README](../../README.md) — both install paths
- [Claude Code plugin docs](https://code.claude.com/docs/en/plugins)
