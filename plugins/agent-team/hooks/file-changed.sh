#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/hooks.log"
INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
FP=$(echo "$INPUT" | jq -r '.file_path // "?"' 2>/dev/null || echo '?')
CT=$(echo "$INPUT" | jq -r '.change_type // "?"' 2>/dev/null || echo '?')
echo "[$(date '+%H:%M:%S')] [file-changed] $CT $FP" >> "$LOG"
exit 0
