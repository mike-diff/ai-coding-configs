#!/usr/bin/env bash
# plugins/agent-team/hooks/inject-rules.sh
# SessionStart hook: emits plugin-shipped rules to stdout (becomes context per docs).

set -euo pipefail

# Standalone context: rules are auto-loaded from .claude/rules/, skip injection.
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  exit 0
fi

RULES_DIR="$CLAUDE_PLUGIN_ROOT/rules-source"

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
