# agent-team — Claude Code Plugin

Workflow commands, specialized subagents, safety hooks, and reusable skills.
Plugin version of the standalone `.claude/` config at `mike-diff/ai-coding-configs`.

## Install

```bash
/plugin marketplace add mike-diff/ai-coding-configs
/plugin install agent-team@mike-diff
```

After install, all commands are namespaced: `/agent-team:discuss`, `/agent-team:dev`, `/agent-team:spec`, etc.

## Prerequisites

- Claude Code 2.1.178 or later (verify with `claude --version`). Subagent delegation is native — no env flag needed.

## What This Plugin Provides

- **15 skills** — `ask`, `dev`, `discuss`, `issue`, `loop-patterns`, `orient`, `primitives`, `review-patterns`, `skill`, `slop-check`, `spec`, `team-orchestration`, `testing-patterns`, `ticket`, `to-dos`
- **5 specialized agents** — `explorer`, `implementer`, `qa`, `reviewer`, `skill-author`
- **11 hooks** across 9 lifecycle events (`SessionStart`, `PreToolUse`, `PostToolUse`, `PermissionDenied`, `PreCompact`, `CwdChanged`, `TaskCreated`, `StopFailure`)
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
- **Structured output is prompt-enforced**: subagents return `<*-result>` blocks per their agent prompts; there is no hook-level gate (the teams-era `TeammateIdle`/`TaskCompleted` hook events no longer exist in Claude Code).

## See Also

- [Top-level repo README](../../README.md) — both install paths
- [Claude Code plugin docs](https://code.claude.com/docs/en/plugins)
