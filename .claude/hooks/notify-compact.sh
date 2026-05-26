#!/usr/bin/env bash
set -euo pipefail

# PreCompact Hook
# Notifies the user when context compaction is about to occur.
# Surfaces the context usage percentage so it's visible in the session.

LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/hooks.log"
ts() { date '+%H:%M:%S'; }
log() { echo "[$(ts)] [notify-compact] $1" >> "$LOG"; }

INPUT=$(cat)
USAGE=$(echo "$INPUT" | jq -r '.context_usage_percent // "unknown"' 2>/dev/null)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"' 2>/dev/null)

if [[ "$TRIGGER" == "manual" ]]; then
  MSG="Compacting context manually. Session state will be saved on next stop."
else
  MSG="Context at ${USAGE}% — compacting automatically. Session state will be saved on next stop."
fi

# Desktop/terminal notification (OSC 777; requires Claude Code v2.1.141+).
# Hooks run without a controlling terminal, so the escape sequence is returned in
# `terminalSequence` and Claude Code emits it for us.
SEQ=$(printf '\033]777;notify;%s;%s\007' "Claude Code" "$MSG")
if command -v jq >/dev/null 2>&1; then
  jq -nc --arg msg "$MSG" --arg seq "$SEQ" '{user_message: $msg, terminalSequence: $seq}'
else
  printf '{"user_message": "%s"}\n' "$MSG"
fi

# Added: survivor summary
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -d "$CLAUDE_PLUGIN_ROOT/rules-source" ]; then
  RULES_DIR="$CLAUDE_PLUGIN_ROOT/rules-source"
else
  RULES_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/rules"
fi
if [[ -d "$RULES_DIR" ]]; then
  RULE_LIST=$(find "$RULES_DIR" -maxdepth 1 -name '*.md' -printf '%f ' 2>/dev/null || echo '')
  log "SURVIVORS rules: $RULE_LIST"
fi

LOADED_SKILLS=$(echo "${INPUT:-{}}" | jq -r '.loaded_skills // [] | join(",")' 2>/dev/null || echo '')
[[ -n "$LOADED_SKILLS" ]] && log "SURVIVORS skills-at-compact: $LOADED_SKILLS"

exit 0
