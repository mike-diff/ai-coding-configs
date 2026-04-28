#!/usr/bin/env bash
set -euo pipefail

# Stop / SubagentStop / TeammateIdle Hook
# Used in two contexts:
#   1. Agent frontmatter (Stop) - fires as SubagentStop when agent runs as subagent
#   2. settings.json (TeammateIdle) - fires when a teammate goes idle mid-run
#
# Both paths call this same script. The event name differs but the check is identical:
# did the teammate produce a structured result block before stopping?
#
# Exit 0 = allow stop/idle
# Exit 2 = send feedback and keep teammate working (stderr shown to Claude)
#
# Input: JSON via stdin with session context

# Debug logging - writes to .claude/.logs/hooks.log
LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hooks.log"

log() {
  echo "[$(date '+%H:%M:%S')] [teammate-idle] $1" >> "$LOG_FILE"
}

# Read JSON input from stdin
INPUT="$(cat /dev/stdin 2>/dev/null || echo "")"
if [[ -z "$INPUT" ]]; then
  log "SKIP: empty input"
  exit 0
fi

# Extract event info for logging
EVENT="$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"' 2>/dev/null)"
TEAMMATE="$(echo "$INPUT" | jq -r '.teammate_name // .agent_type // "unknown"' 2>/dev/null)"
log "FIRED: event=$EVENT teammate=$TEAMMATE"

# Primary: check last_assistant_message (documented field for Stop/SubagentStop)
LAST_MSG="$(echo "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)"

if [[ -n "$LAST_MSG" ]]; then
  log "CHECKING: last_assistant_message (length=${#LAST_MSG})"
  if echo "$LAST_MSG" | grep -qE '<(explorer|implementer|reviewer|qa|scout|research|challenge|blindspot|dependency)-result>'; then
    log "RESULT: found result block in last_assistant_message - allowing stop"
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
      log "RESULT: found result block in transcript - allowing stop"
      exit 0
    fi
    log "RESULT: NO result block found in transcript"
  else
    log "TRANSCRIPT: not available (path='${TRANSCRIPT:-<empty>}')"
  fi
fi

# No result block found - send feedback to keep working
log "ACTION: exit 2 - blocking stop, requesting result block"
echo "Missing structured result block. Please return your findings in the appropriate <*-result> block format (explorer-result, implementer-result, reviewer-result, qa-result, scout-result, research-result, challenge-result, blindspot-result, or dependency-result) before finishing." >&2
exit 2
