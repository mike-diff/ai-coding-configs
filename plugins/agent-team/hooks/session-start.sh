#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/hooks.log"
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  HOOKS_DIR="$CLAUDE_PLUGIN_ROOT/hooks"
  SKIP_EXEC_CHECK=1
else
  HOOKS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks"
  SKIP_EXEC_CHECK=0
fi

ts() { date '+%H:%M:%S'; }
log() { echo "[$(ts)] [session-start] $1" >> "$LOG"; }

INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
SID=$(echo "$INPUT" | jq -r '.session_id // "?"')
SRC=$(echo "$INPUT" | jq -r '.source // "?"')
MDL=$(echo "$INPUT" | jq -r '.model // "?"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "?"')

log "START sid=$SID source=$SRC model=$MDL cwd=$CWD"

if [ "$SKIP_EXEC_CHECK" = "0" ]; then
  # Validate required hook scripts are executable
  REQUIRED=(block-dangerous.sh validate-commit.sh redact-secrets.sh post-edit-lint.sh teammate-idle.sh task-completed.sh notify-compact.sh)
  MISSING=0
  for h in "${REQUIRED[@]}"; do
    if [[ ! -x "$HOOKS_DIR/$h" ]]; then
      log "WARN: $h not executable or missing"
      MISSING=$((MISSING+1))
    fi
  done
  if [[ $MISSING -eq 0 ]]; then
    log "OK: hook inventory complete"
  else
    log "WARN: $MISSING hook(s) have issues — run chmod +x .claude/hooks/*.sh"
  fi
fi

exit 0
