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
LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hooks.log"

log() {
  echo "[$(date '+%H:%M:%S')] [post-edit-lint] $1" >> "$LOG_FILE"
}

# Per-call noise (SKIP/FIRED lines) only when debugging; blocks and lint
# findings always log. Set CLAUDE_HOOK_DEBUG=1 to see every invocation.
debug() {
  [[ "${CLAUDE_HOOK_DEBUG:-0}" == "1" ]] || return 0
  log "$1"
}

# Read the JSON input from stdin
INPUT="$(cat)"
if [[ -z "$INPUT" ]]; then
  debug "SKIP: empty input"
  exit 0
fi

# Extract the file path from tool input
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
if [[ -z "$FILE_PATH" ]]; then
  debug "SKIP: no file_path in input"
  exit 0
fi

debug "FIRED: file=$FILE_PATH"

# Skip non-code files
case "$FILE_PATH" in
  *.md|*.txt|*.json|*.yaml|*.yml|*.toml|*.lock|*.log|*.csv)
    debug "SKIP: non-code file ($FILE_PATH)"
    exit 0
    ;;
esac

# Auto-detect lint command from project config
LINT_CMD=""

if [[ -f "package.json" ]]; then
  # Invoke the eslint binary directly on the edited file only. Routing through
  # `npm run lint -- <args>` appends args to an arbitrary script: flags land on
  # node itself (`node: bad option`) and `eslint .`-style scripts still lint
  # the whole project. With no local or global eslint, skip — the verify gate
  # runs the project's own lint script in full at phase end.
  PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  if [[ -x "$PROJECT_ROOT/node_modules/.bin/eslint" ]]; then
    LINT_CMD="\"$PROJECT_ROOT/node_modules/.bin/eslint\" --no-error-on-unmatched-pattern \"$FILE_PATH\""
  elif command -v eslint >/dev/null 2>&1; then
    LINT_CMD="eslint --no-error-on-unmatched-pattern \"$FILE_PATH\""
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

# If lint found issues, surface them to Claude. Prefer hookSpecificOutput.additionalContext
# (reliably injected into context) over stderr; fall back to stderr if jq is unavailable.
if [[ -n "$LINT_OUTPUT" ]]; then
  log "LINT: issues found for $FILE_PATH"
  CTX="Lint issues after editing ${FILE_PATH}:"$'\n'"${LINT_OUTPUT}"
  if command -v jq >/dev/null 2>&1; then
    jq -nc --arg ctx "$CTX" \
      '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
  else
    echo "$CTX" >&2
  fi
fi

exit 0
