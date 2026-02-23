#!/bin/bash
set -euo pipefail

# afterFileEdit hook: Auto-format files after agent edits.
# Detects the project's formatter and runs it on the edited file.
# Informational only - no output JSON required.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // empty')

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Find project root (where hooks.json lives or git root)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Detect and run the appropriate formatter
case "$EXT" in
  ts|tsx|js|jsx|mjs|cjs|json|css|scss|html|md|yaml|yml)
    # Prefer prettier, fall back to eslint --fix for js/ts
    if [[ -f "$PROJECT_ROOT/node_modules/.bin/prettier" ]]; then
      "$PROJECT_ROOT/node_modules/.bin/prettier" --write "$FILE_PATH" 2>/dev/null || true
    elif command -v prettier &>/dev/null; then
      prettier --write "$FILE_PATH" 2>/dev/null || true
    elif [[ "$EXT" =~ ^(ts|tsx|js|jsx)$ ]] && [[ -f "$PROJECT_ROOT/node_modules/.bin/eslint" ]]; then
      "$PROJECT_ROOT/node_modules/.bin/eslint" --fix "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  py)
    # Prefer ruff, fall back to black
    if command -v ruff &>/dev/null; then
      ruff format "$FILE_PATH" 2>/dev/null || true
      ruff check --fix "$FILE_PATH" 2>/dev/null || true
    elif command -v black &>/dev/null; then
      black --quiet "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  rs)
    if command -v rustfmt &>/dev/null; then
      rustfmt "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  go)
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
