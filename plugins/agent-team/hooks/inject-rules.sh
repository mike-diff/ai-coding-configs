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
