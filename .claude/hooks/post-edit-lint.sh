#!/usr/bin/env bash
set -euo pipefail

# PostToolUse Hook (matcher: Write|Edit)
# Runs after any file write or edit operation.
# Opt-in fast feedback: lints the edited file only when the project declared
# AND configured a linter this hook can invoke on that file type (eslint,
# ruff, flake8; go vet runs whole-project on relevant types).
# Everything else stays silent — the verify gate runs the project's own lint
# script in full at phase end.

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
# Skip edits outside the project dir — a scratchpad or sibling-repo write
# must not trigger this project's linter. Hooks run with CWD = project dir;
# CLAUDE_PROJECT_DIR carries it when the runtime sets it.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
case "$FILE_PATH" in
  /*) ABS_PATH="$FILE_PATH" ;;
  *) ABS_PATH="$PROJECT_DIR/$FILE_PATH" ;;
esac
ABS_PATH="$(realpath -m "$ABS_PATH" 2>/dev/null || printf '%s' "$ABS_PATH")"
PROJECT_DIR="$(realpath -m "$PROJECT_DIR" 2>/dev/null || printf '%s' "$PROJECT_DIR")"
case "$ABS_PATH" in
  "$PROJECT_DIR"/*) ;;
  *)
    debug "SKIP: outside project ($FILE_PATH)"
    exit 0
    ;;
esac

# Auto-detect lint command from project config. Commands are built as argv
# arrays and executed directly — never eval'd. FILE_PATH comes from tool-call
# JSON, so a crafted path (e.g. containing $(...) or backticks) must never
# reach a shell parser.
#
# Selection is a per-linter allowlist: lintability is stack-relative, so the
# only sound test is "the project opted into a linter this hook drives,
# and the edited file is in that linter's domain". Finer arbitration belongs
# to the linter's own config — eslint warns and exits 0 on a file its config
# doesn't cover, which surfaces nothing here (only rc 1 does).
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Sets ESLINT_CONFIG to flat|legacy for an eslint config the linter itself
# would discover — with a package.json declaration, the strongest signal that
# eslint is this project's chosen linter rather than a transitive leftover.
find_eslint_config() {
  local d f
  for d in "$PWD" "$PROJECT_ROOT"; do
    for f in eslint.config.js eslint.config.mjs eslint.config.cjs \
             eslint.config.ts eslint.config.mts eslint.config.cts; do
      [[ -f "$d/$f" ]] && { ESLINT_CONFIG=flat; return 0; }
    done
    for f in .eslintrc .eslintrc.js .eslintrc.cjs .eslintrc.json \
             .eslintrc.yaml .eslintrc.yml; do
      [[ -f "$d/$f" ]] && { ESLINT_CONFIG=legacy; return 0; }
    done
  done
  return 1
}

set_eslint_cmd() {
  if [[ -x "$PROJECT_ROOT/node_modules/.bin/eslint" ]]; then
    LINT_CMD=("$PROJECT_ROOT/node_modules/.bin/eslint" --no-error-on-unmatched-pattern "$FILE_PATH")
  fi
}

declare -a LINT_CMD=()
declare -a LINT_TAIL=()

if [[ -f "package.json" ]] \
  && jq -e '(.devDependencies.eslint // .dependencies.eslint) != null' package.json >/dev/null 2>&1 \
  && find_eslint_config; then
  # Invoke the project's own eslint binary directly on the edited file only —
  # never a global one, which may be a different major and misread the
  # project's config. Routing through `npm run lint -- <args>` appends args
  # to an arbitrary script: flags land on node itself (`node: bad option`)
  # and `eslint .`-style scripts still lint the whole project.
  case "$FILE_PATH" in
    *.js|*.mjs|*.cjs|*.jsx|*.ts|*.tsx)
      set_eslint_cmd
      ;;
    *.vue|*.svelte|*.astro)
      # Single-file components only under flat config: an uncovered file
      # there warns and exits 0, but a legacy config parse-errors it —
      # rc 1, a false finding.
      if [[ "$ESLINT_CONFIG" == flat ]]; then
        set_eslint_cmd
      fi
      ;;
  esac
elif [[ -f "pyproject.toml" ]]; then
  # Only when the project opted in: a PATH-installed linter in a project that
  # never configured it reports defaults nobody signed up for.
  case "$FILE_PATH" in
    *.py)
      if command -v ruff >/dev/null 2>&1 \
        && { [[ -f ruff.toml || -f .ruff.toml ]] || grep -q '\[tool.ruff\]' pyproject.toml; }; then
        LINT_CMD=(ruff check "$FILE_PATH")
      elif command -v flake8 >/dev/null 2>&1 \
        && { [[ -f .flake8 ]] || grep -q '\[flake8\]' setup.cfg tox.ini 2>/dev/null; }; then
        LINT_CMD=(flake8 "$FILE_PATH")
      fi
      ;;
  esac
elif [[ -f "go.mod" ]]; then
  case "$FILE_PATH" in
    *.go|go.mod|*/go.mod|go.sum|*/go.sum)
      LINT_CMD=(go vet ./...)
      LINT_TAIL=(head -20)
      ;;
  esac
fi

# If no lint command found, skip silently
if [[ ${#LINT_CMD[@]} -eq 0 ]]; then
  exit 0
fi

# Run lint. Distinguish findings from tool failure: eslint/ruff/flake8 exit 1
# when they found issues and 2+ on config or fatal errors, so only rc 1 is
# surfaced as lint findings — a broken linter is not lint output.
LINT_RC=0
if [[ ${#LINT_TAIL[@]} -gt 0 ]]; then
  LINT_OUTPUT="$("${LINT_CMD[@]}" 2>&1 | "${LINT_TAIL[@]}")" || LINT_RC=${PIPESTATUS[0]}
else
  LINT_OUTPUT="$("${LINT_CMD[@]}" 2>&1)" || LINT_RC=$?
fi

# If lint found issues, surface them to Claude. Prefer hookSpecificOutput.additionalContext
# (reliably injected into context) over stderr; fall back to stderr if jq is unavailable.
if [[ -n "$LINT_OUTPUT" && "$LINT_RC" -eq 1 ]]; then
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
