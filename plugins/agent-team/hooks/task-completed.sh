#!/usr/bin/env bash
set -euo pipefail

# TaskCompleted Hook
# Runs when a task is being marked complete in the shared task list.
# Exit 0 = allow completion
# Exit 2 = prevent completion (stderr fed back as feedback)
#
# Validates that the task output contains a structured result block.
# Configured in settings.json under hooks.TaskCompleted.
#
# Input: JSON via stdin with task context

# Debug logging - writes to .claude/.logs/hooks.log
LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hooks.log"

log() {
  echo "[$(date '+%H:%M:%S')] [task-completed] $1" >> "$LOG_FILE"
}

# Read JSON input from stdin
INPUT="$(cat /dev/stdin 2>/dev/null || echo "")"
if [[ -z "$INPUT" ]]; then
  log "SKIP: empty input"
  exit 0
fi

# Extract event info for logging
TASK_ID="$(echo "$INPUT" | jq -r '.task_id // "unknown"' 2>/dev/null)"
TASK_SUBJECT="$(echo "$INPUT" | jq -r '.task_subject // "unknown"' 2>/dev/null)"
TEAMMATE="$(echo "$INPUT" | jq -r '.teammate_name // "unknown"' 2>/dev/null)"
log "FIRED: task_id=$TASK_ID subject='$TASK_SUBJECT' teammate=$TEAMMATE"

# Primary: check last_assistant_message (documented field for Stop/SubagentStop)
LAST_MSG="$(echo "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)"

if [[ -n "$LAST_MSG" ]]; then
  log "CHECKING: last_assistant_message (length=${#LAST_MSG})"
  if echo "$LAST_MSG" | grep -qE '<(explorer|implementer|reviewer|qa|scout|research|challenge|blindspot|dependency)-result>'; then
    log "RESULT: found result block in last_assistant_message - allowing completion"
    exit 0
  fi
  log "RESULT: NO result block in last_assistant_message"
else
  log "CHECKING: last_assistant_message not present, trying transcript_path"

  # Fallback: transcript_path (may be available on some event types)
  TRANSCRIPT="$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)"
  if [[ -n "$TRANSCRIPT" ]] && [[ -f "$TRANSCRIPT" ]]; then
    log "TRANSCRIPT: $TRANSCRIPT (exists, checking for result blocks)"
    if grep -qE '<(explorer|implementer|reviewer|qa|scout|research|challenge|blindspot|dependency)-result>' "$TRANSCRIPT" 2>/dev/null; then
      log "RESULT: found result block in transcript - allowing completion"
      exit 0
    fi
    log "RESULT: NO result block found in transcript"
  else
    log "TRANSCRIPT: not available (path='${TRANSCRIPT:-<empty>}')"
  fi
fi

# No result block found - prevent completion
log "ACTION: exit 2 - blocking completion, requesting result block"
echo "Task output is missing a structured result block. Please include the appropriate <*-result> block (explorer-result, implementer-result, reviewer-result, qa-result, scout-result, research-result, challenge-result, blindspot-result, or dependency-result) before marking this task complete." >&2
exit 2
