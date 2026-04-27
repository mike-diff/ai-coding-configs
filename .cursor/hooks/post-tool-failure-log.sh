#!/usr/bin/env bash
set -euo pipefail

# postToolUseFailure hook: Log failed tool executions for debugging and triage.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
ERROR=$(echo "$INPUT" | jq -r '.error // "unknown"')
CONVERSATION_ID=$(echo "$INPUT" | jq -r '.conversation_id // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LOG_DIR="$PROJECT_ROOT/.cursor/.logs"
mkdir -p "$LOG_DIR"

echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"postToolUseFailure\",\"tool\":\"$TOOL_NAME\",\"error\":\"$ERROR\",\"conversation_id\":\"$CONVERSATION_ID\"}" >> "$LOG_DIR/hooks.log"

exit 0
