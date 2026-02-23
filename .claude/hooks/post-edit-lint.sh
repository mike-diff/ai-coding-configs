#!/usr/bin/env bash
set -euo pipefail

# PostToolUse Hook (matcher: Write|Edit)
# Runs after any file write or edit operation.
# Detects the project's lint command and runs it on the modified file.
# Exit 0 = success (stdout shown in verbose mode)
# Stderr on exit 0 = shown to Claude as context
#
# This hook provides fast feedback on lint errors immediately after
# a file is modified, rather than waiting for the QA teammate.

# Debug logging - writes to .claude/.logs/hooks.log
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hooks.log"

log() {
  echo "[$(date '+%H:%M:%S')] [post-edit-lint] $1" >> "$LOG_FILE"
}

# Read the JSON input from stdin
INPUT="$(cat /dev/stdin 2>/dev/null || echo "")"
if [[ -z "$INPUT" ]]; then
  log "SKIP: empty input"
  exit 0
fi

# Extract the file path from tool input
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
if [[ -z "$FILE_PATH" ]]; then
  log "SKIP: no file_path in input"
  exit 0
fi

log "FIRED: file=$FILE_PATH"

# Skip non-code files
case "$FILE_PATH" in
  *.md|*.txt|*.json|*.yaml|*.yml|*.toml|*.lock|*.log|*.csv)
    log "SKIP: non-code file ($FILE_PATH)"
    exit 0
    ;;
esac

# Auto-detect lint command from project config
LINT_CMD=""

if [[ -f "package.json" ]]; then
  # Check for common Node.js lint scripts
  if jq -e '.scripts.lint' package.json >/dev/null 2>&1; then
    LINT_CMD="npm run lint -- --no-error-on-unmatched-pattern"
  elif jq -e '.scripts.eslint' package.json >/dev/null 2>&1; then
    LINT_CMD="npm run eslint"
  fi
elif [[ -f "pyproject.toml" ]]; then
  # Check for Python linters
  if command -v ruff >/dev/null 2>&1; then
    LINT_CMD="ruff check \"$FILE_PATH\""
  elif command -v flake8 >/dev/null 2>&1; then
    LINT_CMD="flake8 \"$FILE_PATH\""
  fi
elif [[ -f "Cargo.toml" ]]; then
  LINT_CMD="cargo clippy --quiet 2>&1 | head -20"
elif [[ -f "go.mod" ]]; then
  LINT_CMD="go vet ./... 2>&1 | head -20"
fi

# If no lint command found, skip silently
if [[ -z "$LINT_CMD" ]]; then
  exit 0
fi

# Run lint and capture output (don't fail the hook on lint errors)
LINT_OUTPUT="$(eval "$LINT_CMD" 2>&1)" || true

# If lint found issues, show them to Claude via stderr
if [[ -n "$LINT_OUTPUT" ]]; then
  echo "Lint issues after editing $FILE_PATH:" >&2
  echo "$LINT_OUTPUT" >&2
fi

exit 0
