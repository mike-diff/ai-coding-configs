#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/tasks.log"
INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
TID=$(echo "$INPUT" | jq -r '.task_id // "?"' 2>/dev/null || echo '?')
SUB=$(echo "$INPUT" | jq -r '.task_subject // "?"' 2>/dev/null || echo '?')
TM=$(echo "$INPUT" | jq -r '.teammate_name // "?"' 2>/dev/null || echo '?')
echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] task=$TID teammate=$TM subject=\"$SUB\"" >> "$LOG"
exit 0
