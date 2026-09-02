#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/hooks.log"
INPUT="$(cat)"
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "?"' 2>/dev/null || echo '?')
ERR=$(echo "$INPUT" | jq -r '.error // .tool_response.error // "?"' 2>/dev/null | head -c 200 || echo '?')
echo "[$(date '+%H:%M:%S')] [tool-failure] $TOOL: $ERR" >> "$LOG"
exit 0
