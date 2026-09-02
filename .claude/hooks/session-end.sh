#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/hooks.log"
INPUT="$(cat)"
SESSION=$(echo "$INPUT" | jq -r '.session_id // "?"' 2>/dev/null || echo '?')
REASON=$(echo "$INPUT" | jq -r '.reason // "?"' 2>/dev/null || echo '?')
echo "[$(date '+%H:%M:%S')] [session-end] session=$SESSION reason=$REASON" >> "$LOG"
exit 0
