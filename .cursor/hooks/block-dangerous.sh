#!/bin/bash
set -euo pipefail

# beforeShellExecution hook: Block destructive commands.
# Matcher pre-filters to: rm -rf, git push --force, git reset --hard, DROP, TRUNCATE, delete from
# This script provides the deny decision with a helpful message.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.command // empty')

if [[ -z "$COMMAND" ]]; then
  echo '{"permission": "allow"}'
  exit 0
fi

# Check for destructive patterns
BLOCKED=""
REASON=""

# rm -rf on root-like or broad paths
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive.*--force|-[a-zA-Z]*f[a-zA-Z]*r)\s+(/|~|\.\.|\.(/\.\.)?)(\s|$)'; then
  BLOCKED="true"
  REASON="Recursive force-delete on a broad path is blocked for safety."
fi

# git push --force to main/master
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force.*\s+(main|master)(\s|$)' || \
   echo "$COMMAND" | grep -qE 'git\s+push\s+.*-f\s+.*\s+(main|master)(\s|$)'; then
  BLOCKED="true"
  REASON="Force push to main/master is blocked. Use a feature branch instead."
fi

# git reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  BLOCKED="true"
  REASON="Hard reset discards uncommitted changes. Use 'git stash' or commit first."
fi

# SQL destructive operations without WHERE
if echo "$COMMAND" | grep -qiE '(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE)'; then
  BLOCKED="true"
  REASON="Destructive SQL operation (DROP/TRUNCATE) blocked. Verify manually."
fi

if echo "$COMMAND" | grep -qiE 'delete\s+from\s+\w+\s*;?\s*$'; then
  BLOCKED="true"
  REASON="DELETE without WHERE clause blocked. Add a WHERE condition."
fi

if [[ -n "$BLOCKED" ]]; then
  echo "{\"permission\": \"deny\", \"user_message\": \"Blocked: $REASON\", \"agent_message\": \"This command was blocked by a safety hook. $REASON Please use a safer alternative.\"}"
  exit 2
fi

echo '{"permission": "allow"}'
exit 0
