#!/usr/bin/env bash
set -euo pipefail

# PreToolUse Hook (matcher: Bash)
# Blocks destructive shell commands before execution.
# Exit 0 = allow the command
# Exit 2 = block the command (stderr fed back to Claude)
#
# Input: JSON via stdin with tool_input.command

# Debug logging
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hooks.log"

log() {
  echo "[$(date '+%H:%M:%S')] [block-dangerous] $1" >> "$LOG_FILE"
}

# Read JSON input from stdin
INPUT="$(cat /dev/stdin 2>/dev/null || echo "")"
if [[ -z "$INPUT" ]]; then
  exit 0
fi

# Extract the command from tool input
COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
if [[ -z "$COMMAND" ]]; then
  exit 0
fi

log "CHECK: $COMMAND"

# --- Destructive patterns ---

# rm -rf on root-like or broad paths
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive.*--force|-[a-zA-Z]*f[a-zA-Z]*r)\s+(/|~|\.\.|\.(/\.\.)?)(\s|$)'; then
  log "BLOCKED: recursive force-delete on broad path"
  echo "Blocked: Recursive force-delete on a broad path. Use a more specific path or remove files individually." >&2
  exit 2
fi

# git push --force to main/master
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force.*\s+(main|master)(\s|$)' || \
   echo "$COMMAND" | grep -qE 'git\s+push\s+.*-f\s+.*\s+(main|master)(\s|$)'; then
  log "BLOCKED: force push to main/master"
  echo "Blocked: Force push to main/master is not allowed. Use a feature branch instead." >&2
  exit 2
fi

# git reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  log "BLOCKED: git reset --hard"
  echo "Blocked: Hard reset discards uncommitted changes. Use 'git stash' or commit your changes first." >&2
  exit 2
fi

# SQL destructive operations
if echo "$COMMAND" | grep -qiE '(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE)'; then
  log "BLOCKED: destructive SQL (DROP/TRUNCATE)"
  echo "Blocked: Destructive SQL operation (DROP/TRUNCATE). Verify the command manually before running." >&2
  exit 2
fi

# DELETE without WHERE clause
if echo "$COMMAND" | grep -qiE 'delete\s+from\s+\w+\s*;?\s*$'; then
  log "BLOCKED: DELETE without WHERE"
  echo "Blocked: DELETE without WHERE clause. Add a WHERE condition to avoid deleting all rows." >&2
  exit 2
fi

log "ALLOWED"
exit 0
