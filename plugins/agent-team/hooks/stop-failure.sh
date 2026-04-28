#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/stop-failures.log"
INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
PM=$(echo "$INPUT" | jq -r '.permission_mode // "?"' 2>/dev/null || echo '?')
echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] stop-failure permission_mode=$PM raw=$INPUT" >> "$LOG"
exit 0
