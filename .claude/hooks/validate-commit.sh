#!/usr/bin/env bash
set -euo pipefail

# PreToolUse Hook (matcher: Bash)
# Validates git commit messages match conventional commits format.
# Enforces: type(scope): description
# Exit 0 = allow the command
# Exit 2 = block the command (stderr fed back to Claude)
#
# Input: JSON via stdin with tool_input.command

# Debug logging
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hooks.log"

log() {
  echo "[$(date '+%H:%M:%S')] [validate-commit] $1" >> "$LOG_FILE"
}

# Read JSON input from stdin
INPUT="$(cat /dev/stdin 2>/dev/null || echo "")"
if [[ -z "$INPUT" ]]; then
  exit 0
fi

# Extract the command from tool input
COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Only check git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Only validate commands that include a message flag
if ! echo "$COMMAND" | grep -qE '(-m|--message)'; then
  # Interactive commit or amend without message change - allow
  exit 0
fi

log "CHECK: $COMMAND"

# Extract the commit message from -m "message" or -m 'message'
# Handle: git commit -m "msg", git commit -am "msg", heredoc patterns
MSG=""

# Try double quotes first
MSG="$(echo "$COMMAND" | grep -oE '(-m|--message)\s+"[^"]*"' | head -1 | sed 's/^[^"]*"//' | sed 's/"$//' 2>/dev/null)" || true

# Try single quotes
if [[ -z "$MSG" ]]; then
  MSG="$(echo "$COMMAND" | grep -oE "(-m|--message)\s+'[^']*'" | head -1 | sed "s/^[^']*'//" | sed "s/'$//" 2>/dev/null)" || true
fi

# If using heredoc or we can't parse the message, allow through
if [[ -z "$MSG" ]]; then
  log "SKIP: could not parse commit message (heredoc or complex format)"
  exit 0
fi

# Conventional commits pattern: type(scope): description or type: description
# Types: feat, fix, refactor, docs, test, chore, style, perf, ci, revert
PATTERN='^(feat|fix|refactor|docs|test|chore|style|perf|ci|revert)(\([a-zA-Z0-9_-]+\))?!?: .+'

if echo "$MSG" | grep -qE "$PATTERN"; then
  log "ALLOWED: valid commit message"
  exit 0
fi

log "BLOCKED: invalid commit message '$MSG'"
echo "Commit blocked: message must match 'type(scope): description'. Valid types: feat, fix, refactor, docs, test, chore, style, perf, ci, revert. Example: 'feat(auth): add JWT token refresh'. Please fix the commit message and retry." >&2
exit 2
