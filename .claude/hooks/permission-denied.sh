#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/permission-denied.log"

INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "?"' 2>/dev/null || echo '?')
REASON=$(echo "$INPUT" | jq -r '.reason // "?"' 2>/dev/null || echo '?')

echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] tool=$TOOL reason=$REASON" >> "$LOG"
exit 0
