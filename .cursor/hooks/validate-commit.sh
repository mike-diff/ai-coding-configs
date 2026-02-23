#!/bin/bash
set -euo pipefail

# beforeShellExecution hook: Validate git commit messages match conventional commits format.
# Matcher pre-filters to: git commit
# Enforces: type(scope): description

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.command // empty')

if [[ -z "$COMMAND" ]]; then
  echo '{"permission": "allow"}'
  exit 0
fi

# Only validate commands that include a message flag
if ! echo "$COMMAND" | grep -qE 'git\s+commit.*(-m|--message)'; then
  echo '{"permission": "allow"}'
  exit 0
fi

# Extract the commit message from -m "message" or -m 'message'
# Handle: git commit -m "msg", git commit -am "msg", git commit -m "msg" -m "body"
MSG=$(echo "$COMMAND" | grep -oE '(-m|--message)\s+("([^"]*)"' | head -1 | sed 's/^(-m|--message)\s+"//' | sed 's/"$//')

# Fallback: try single quotes
if [[ -z "$MSG" ]]; then
  MSG=$(echo "$COMMAND" | grep -oP "(-m|--message)\s+'([^']*)'" | head -1 | sed "s/^(-m|--message)\s+'//" | sed "s/'$//")
fi

# If using heredoc or we can't parse the message, allow it through
if [[ -z "$MSG" ]]; then
  echo '{"permission": "allow"}'
  exit 0
fi

# Conventional commits pattern: type(scope): description or type: description
# Types: feat, fix, refactor, docs, test, chore, style, perf, ci, revert
PATTERN='^(feat|fix|refactor|docs|test|chore|style|perf|ci|revert)(\([a-zA-Z0-9_-]+\))?!?: .+'

if echo "$MSG" | grep -qE "$PATTERN"; then
  echo '{"permission": "allow"}'
  exit 0
fi

echo "{\"permission\": \"deny\", \"user_message\": \"Commit message does not follow conventional commits format.\", \"agent_message\": \"Commit blocked: message must match 'type(scope): description'. Valid types: feat, fix, refactor, docs, test, chore, style, perf, ci, revert. Example: 'feat(auth): add JWT token refresh'. Please fix the commit message and retry.\"}"
exit 2
