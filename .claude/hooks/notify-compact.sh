#!/usr/bin/env bash
set -euo pipefail

# PreCompact Hook
# Notifies the user when context compaction is about to occur.
# Surfaces the context usage percentage so it's visible in the session.

INPUT=$(cat)
USAGE=$(echo "$INPUT" | jq -r '.context_usage_percent // "unknown"' 2>/dev/null)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"' 2>/dev/null)

if [[ "$TRIGGER" == "manual" ]]; then
  echo '{"user_message": "Compacting context manually. Session state will be saved on next stop."}'
else
  echo "{\"user_message\": \"Context at ${USAGE}% — compacting automatically. Session state will be saved on next stop.\"}"
fi

exit 0
