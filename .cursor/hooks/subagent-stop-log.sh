#!/usr/bin/env bash
set -euo pipefail

# subagentStop hook: Log subagent completion status for multi-agent observability.

INPUT=$(cat)
AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // "unknown"')
STATUS=$(echo "$INPUT" | jq -r '.status // "unknown"')
CONVERSATION_ID=$(echo "$INPUT" | jq -r '.conversation_id // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LOG_DIR="$PROJECT_ROOT/.cursor/.logs"
mkdir -p "$LOG_DIR"

echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"subagentStop\",\"agent\":\"$AGENT_NAME\",\"status\":\"$STATUS\",\"conversation_id\":\"$CONVERSATION_ID\"}" >> "$LOG_DIR/hooks.log"

exit 0
