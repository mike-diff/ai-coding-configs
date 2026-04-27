#!/usr/bin/env bash
set -euo pipefail

# sessionEnd hook: Log session completion state for auditability.
# Writes a structured log entry when a session ends normally.

INPUT=$(cat)
STATUS=$(echo "$INPUT" | jq -r '.status // "unknown"')
CONVERSATION_ID=$(echo "$INPUT" | jq -r '.conversation_id // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LOG_DIR="$PROJECT_ROOT/.cursor/.logs"
mkdir -p "$LOG_DIR"

echo "{\"timestamp\":\"$TIMESTAMP\",\"event\":\"sessionEnd\",\"conversation_id\":\"$CONVERSATION_ID\",\"status\":\"$STATUS\"}" >> "$LOG_DIR/hooks.log"

exit 0
