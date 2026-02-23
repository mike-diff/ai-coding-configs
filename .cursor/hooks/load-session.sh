#!/bin/bash
set -euo pipefail

# sessionStart hook: Inject existing session state into new conversations.
# If a previous session's state file exists, returns it as context.

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STATE_FILE="$PROJECT_ROOT/.context/session/dev-state.md"
ERRORS_FILE="$PROJECT_ROOT/.context/lint-errors.md"

# Read stdin (required even if we don't use all fields)
cat > /dev/null

# Clear any lint errors from a previous session at startup
rm -f "$ERRORS_FILE"

if [[ -f "$STATE_FILE" ]]; then
  # Check if state file is recent (less than 24 hours old)
  if [[ "$(uname)" == "Darwin" ]]; then
    FILE_AGE=$(( $(date +%s) - $(stat -f %m "$STATE_FILE") ))
  else
    FILE_AGE=$(( $(date +%s) - $(stat -c %Y "$STATE_FILE") ))
  fi

  # Only inject if less than 24 hours old (86400 seconds)
  if [[ "$FILE_AGE" -lt 86400 ]]; then
    STATE_CONTENT=$(cat "$STATE_FILE")
    PAYLOAD=$(jq -n --arg ctx "Previous session state found. Review and continue if relevant:\n\n$STATE_CONTENT" \
      '{additional_context: $ctx}')
    echo "$PAYLOAD"
    exit 0
  fi
fi

# No state to inject
echo '{}'
exit 0
