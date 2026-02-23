#!/usr/bin/env bash
set -euo pipefail

# afterFileEdit hook: Run linting after agent file edits.
# Auto-fixes where possible. Accumulates unfixable errors in
# .context/lint-errors.md — the stop hook (persist-session.sh)
# reads this file and injects errors as a followup message so the
# agent can correct them before the session closes.
#
# Note: Cursor's afterFileEdit hook has no output schema for feeding
# errors back to the agent inline (unlike Claude Code's PostToolUse).
# The stop-hook followup pattern is the Cursor-native equivalent.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // empty')

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
ERRORS_FILE="$PROJECT_ROOT/.context/lint-errors.md"
mkdir -p "$PROJECT_ROOT/.context"

# Clear stale errors file if older than 24 hours (session bleed guard)
if [[ -f "$ERRORS_FILE" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    FILE_AGE=$(( $(date +%s) - $(stat -f %m "$ERRORS_FILE") ))
  else
    FILE_AGE=$(( $(date +%s) - $(stat -c %Y "$ERRORS_FILE") ))
  fi
  if [[ "$FILE_AGE" -gt 86400 ]]; then
    rm -f "$ERRORS_FILE"
  fi
fi

ERRORS=""

case "$EXT" in
  ts|tsx|js|jsx|mjs|cjs)
    ESLINT=""
    if [[ -f "$PROJECT_ROOT/node_modules/.bin/eslint" ]]; then
      ESLINT="$PROJECT_ROOT/node_modules/.bin/eslint"
    elif command -v eslint &>/dev/null; then
      ESLINT="eslint"
    fi

    if [[ -n "$ESLINT" ]]; then
      # Auto-fix first
      "$ESLINT" --fix "$FILE_PATH" 2>/dev/null || true
      # Collect any remaining errors (warnings are not errors)
      ESLINT_OUT=$("$ESLINT" --format compact "$FILE_PATH" 2>&1 || true)
      if echo "$ESLINT_OUT" | grep -qE '[[:space:]]error[[:space:]]'; then
        ERRORS="$ESLINT_OUT"
      fi
    fi
    ;;

  py)
    if command -v ruff &>/dev/null; then
      # Auto-fix first
      ruff check --fix "$FILE_PATH" 2>/dev/null || true
      # Collect any remaining errors
      RUFF_OUT=$(ruff check "$FILE_PATH" 2>&1 || true)
      if [[ -n "$RUFF_OUT" ]]; then
        ERRORS="$RUFF_OUT"
      fi
    elif command -v flake8 &>/dev/null; then
      FLAKE_OUT=$(flake8 "$FILE_PATH" 2>&1 || true)
      if [[ -n "$FLAKE_OUT" ]]; then
        ERRORS="$FLAKE_OUT"
      fi
    fi
    ;;
esac

if [[ -n "$ERRORS" ]]; then
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  {
    echo ""
    echo "## $(basename "$FILE_PATH") — $TIMESTAMP"
    echo '```'
    echo "$ERRORS"
    echo '```'
  } >> "$ERRORS_FILE"
else
  # If this file previously had errors logged, remove its section.
  # Simpler: if the errors file is now empty after removing this file's
  # entries, delete it entirely so persist-session doesn't fire.
  if [[ -f "$ERRORS_FILE" ]]; then
    BASENAME=$(basename "$FILE_PATH")
    # Remove the section for this file using Python (safe multi-line delete)
    python3 - "$ERRORS_FILE" "$BASENAME" <<'PYEOF' 2>/dev/null || true
import sys, re
path, fname = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()
# Remove section block starting with ## <fname> — <timestamp>
cleaned = re.sub(
    r'\n## ' + re.escape(fname) + r' — [^\n]+\n```[\s\S]*?```\n?',
    '',
    content
)
if cleaned.strip():
    with open(path, 'w') as f:
        f.write(cleaned)
else:
    import os; os.remove(path)
PYEOF
  fi
fi

exit 0
