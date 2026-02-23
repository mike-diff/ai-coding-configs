#!/bin/bash
set -euo pipefail

# stop hook: Persist session state when the agent loop ends.
# Captures git changes, status, and timestamp for recovery after compaction.

INPUT=$(cat)
STATUS=$(echo "$INPUT" | jq -r '.status // "unknown"')
CONVERSATION_ID=$(echo "$INPUT" | jq -r '.conversation_id // "unknown"')

# Find project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SESSION_DIR="$PROJECT_ROOT/.context/session"

mkdir -p "$SESSION_DIR"

# Capture git state
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
GIT_STATUS=$(git status --short 2>/dev/null || echo "no git info")
GIT_DIFF_NAMES=$(git diff --name-only 2>/dev/null || echo "none")
GIT_DIFF_STAGED=$(git diff --cached --name-only 2>/dev/null || echo "none")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$SESSION_DIR/dev-state.md" << EOF
# Dev Session State
Updated: $TIMESTAMP
Conversation: $CONVERSATION_ID
Status: $STATUS
Branch: $BRANCH

## Git Status
\`\`\`
$GIT_STATUS
\`\`\`

## Modified Files (unstaged)
\`\`\`
$GIT_DIFF_NAMES
\`\`\`

## Staged Files
\`\`\`
$GIT_DIFF_STAGED
\`\`\`

## Recovery Instructions
If resuming after compaction:
1. Read this file to restore context
2. Check git status and diff for current state
3. Continue from where the previous session left off
EOF

# Check for outstanding lint errors accumulated by post-edit-lint.sh.
# If any exist, inject them as a followup message so the agent corrects
# them before the session fully closes.
ERRORS_FILE="$PROJECT_ROOT/.context/lint-errors.md"
if [[ -f "$ERRORS_FILE" ]] && [[ -s "$ERRORS_FILE" ]]; then
  ERRORS_CONTENT=$(cat "$ERRORS_FILE")
  rm -f "$ERRORS_FILE"
  FOLLOWUP="Lint errors were detected in files edited this session. Please fix them:\n\n$ERRORS_CONTENT"
  jq -n --arg msg "$FOLLOWUP" '{followup_message: $msg}'
else
  echo '{}'
fi

exit 0
