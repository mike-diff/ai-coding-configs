#!/usr/bin/env bash
set -euo pipefail

# preCompact hook: Notify the user when context compaction is about to occur.
# Surfaces the context usage percentage so it's visible in the chat.

INPUT=$(cat)
USAGE=$(echo "$INPUT" | jq -r '.context_usage_percent // "unknown"')
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"')

if [[ "$TRIGGER" == "manual" ]]; then
  echo "{\"user_message\": \"Compacting context manually. Session state will be saved on stop.\"}"
else
  echo "{\"user_message\": \"Context at ${USAGE}% — compacting automatically. Session state will be saved on stop.\"}"
fi

exit 0
