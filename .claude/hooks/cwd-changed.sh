#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/hooks.log"
INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
NEW=$(echo "$INPUT" | jq -r '.cwd // "?"' 2>/dev/null || echo '?')
echo "[$(date '+%H:%M:%S')] [cwd-changed] -> $NEW" >> "$LOG"
exit 0
