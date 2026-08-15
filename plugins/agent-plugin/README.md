# agent-team (Agent Plugin)

This directory is an [Agent Plugins](https://agent-plugins.org) open-standard
plugin: portable `skills/` invocable in Cursor and any other runtime that
implements the standard. It is **generated** — `scripts/sync-plugin.sh` mirrors
`.claude/skills/` here verbatim (no command namespacing; commands surface as
`/discuss`, `/spec`, `/dev`, …). Only `plugin.json` and this README are
hand-maintained. Never edit `skills/` directly.

## Install (Cursor, local)

```bash
mkdir -p ~/.cursor/plugins/local
ln -s "$(pwd)/plugins/agent-plugin" ~/.cursor/plugins/local/agent-team
```

Restart Cursor (or run **Developer: Reload Window**), then check Customize →
Skills. Commands are also invocable directly as `/discuss`, `/spec`, `/dev`.

The command skills carry `disable-model-invocation: true`, so they stay
user-invoked rather than auto-triggering from ordinary prompts.

## Differences from the Claude Code plugin (`plugins/agent-team`)

| | `plugins/agent-team` | `plugins/agent-plugin` (this) |
|---|---|---|
| Format | Claude Code plugin (`.claude-plugin/plugin.json`) | Agent Plugins open standard (root `plugin.json`) |
| Commands | `/agent-team:discuss`, … (namespaced) | `/discuss`, … (portable names) |
| Path rewrites | `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PROJECT_DIR}` | none (plain `.claude/skills/…` references are not applicable; skills use relative paths) |
| Extra components | hooks, rules-source, agents | skills only (the standard packages skills + MCP) |

Cursor-specific surfaces (rules, subagents, hooks) live in `.cursor/` in the
repo root, not here — the standard deliberately does not carry them.

## Publishing

Submit for review at [cursor.com/marketplace/publish](https://cursor.com/marketplace/publish)
(plugins must be open source — this repo is MIT). Bump `version` here and in
`plugins/agent-team/.claude-plugin/plugin.json` together.
