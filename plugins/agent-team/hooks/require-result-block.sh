#!/usr/bin/env bash
set -euo pipefail

# Require Structured Result Block
# Shared gate for the TeammateIdle and TaskCompleted events. A teammate may only
# go idle / a task may only be marked complete once a structured <*-result> block
# has been produced.
#
# Usage: require-result-block.sh <context>
#   context = "idle" (TeammateIdle) | "completion" (TaskCompleted)
#   The context only affects log prefix and feedback wording; the check is identical.
#
# Exit 0 = allow (result block present, or no input to check)
# Exit 2 = block and send feedback on stderr (shown to Claude)
#
# Input: JSON via stdin with session/task context.

CONTEXT="${1:-idle}"
case "$CONTEXT" in
  completion) VERB="mark this task complete"; ACT="completion" ;;
  *)          VERB="finish"; ACT="stop" ;;
esac

RESULT_RE='<(explorer|implementer|reviewer|qa|scout|research|challenge|blindspot|dependency)-result>'

LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hooks.log"
log() { echo "[$(date '+%H:%M:%S')] [require-result:$CONTEXT] $1" >> "$LOG_FILE"; }

INPUT="$(cat /dev/stdin 2>/dev/null || echo "")"
if [[ -z "$INPUT" ]]; then
  log "SKIP: empty input"
  exit 0
fi

EVENT="$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"' 2>/dev/null)"
TEAMMATE="$(echo "$INPUT" | jq -r '.teammate_name // .agent_type // "unknown"' 2>/dev/null)"
log "FIRED: event=$EVENT teammate=$TEAMMATE"

# Primary: last_assistant_message (documented field for Stop/SubagentStop)
LAST_MSG="$(echo "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)"
if [[ -n "$LAST_MSG" ]]; then
  if echo "$LAST_MSG" | grep -qE "$RESULT_RE"; then
    log "OK: result block in last_assistant_message — allowing $ACT"
    exit 0
  fi
  log "NO result block in last_assistant_message"
else
  # Fallback: transcript_path (available on some event types)
  TRANSCRIPT="$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)"
  if [[ -n "$TRANSCRIPT" ]] && [[ -f "$TRANSCRIPT" ]]; then
    if grep -qE "$RESULT_RE" "$TRANSCRIPT" 2>/dev/null; then
      log "OK: result block in transcript — allowing $ACT"
      exit 0
    fi
    log "NO result block in transcript"
  else
    log "TRANSCRIPT not available (path='${TRANSCRIPT:-<empty>}')"
  fi
fi

log "BLOCK: exit 2 — requesting result block before $ACT"
echo "Missing structured result block. Return your findings in the appropriate <*-result> block (explorer-result, implementer-result, reviewer-result, qa-result, scout-result, research-result, challenge-result, blindspot-result, or dependency-result) before you $VERB." >&2
exit 2
