#!/usr/bin/env bash
# tests/hooks-contract.sh
# Hook contract test: unit checks for hook logic (direct stdin pipe) plus a
# live Claude Code run proving hooks receive their payload and enforcement
# actually blocks. Written after a 2026-08 audit found hooks reading stdin
# via `cat /dev/stdin` — that idiom silently returns nothing on Linux
# (ENXIO re-opening a pipe through procfs), so every safety hook was a no-op
# while direct-pipe tests kept passing. The live test below fails on that bug.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS="$REPO_ROOT/.claude/hooks"
COMMAND_TIMEOUT_SECONDS=${COMMAND_TIMEOUT_SECONDS:-90}

PASS=0
FAIL=0
FAIL_LIST=()

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); FAIL_LIST+=("$1"); }

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required"; exit 2; }

# --- Unit tests: hook logic via direct pipe (no claude required) ---

hook_rc() { # hook_rc <script> <payload> -> exit code
  printf '%s' "$2" | bash "$HOOKS/$1" >/dev/null 2>&1 && echo 0 || echo $?
}

expect_rc() { # expect_rc <name> <script> <payload> <expected-rc>
  local rc
  rc=$(hook_rc "$2" "$3")
  if [ "$rc" -eq "$4" ]; then pass "$1"; else fail "$1 (exit $rc, want $4)"; fi
}

expect_rc "block-dangerous: hard reset blocked" \
  block-dangerous.sh '{"tool_input":{"command":"git reset --hard"}}' 2
expect_rc "block-dangerous: broad rm -rf blocked" \
  block-dangerous.sh '{"tool_input":{"command":"rm -rf /"}}' 2
expect_rc "block-dangerous: safe command allowed" \
  block-dangerous.sh '{"tool_input":{"command":"echo hello"}}' 0
expect_rc "validate-commit: bad message blocked" \
  validate-commit.sh '{"tool_input":{"command":"git commit -m \"fix the bug\""}}' 2
expect_rc "validate-commit: conventional message allowed" \
  validate-commit.sh '{"tool_input":{"command":"git commit -m \"fix(auth): refresh token on expiry\""}}' 0
expect_rc "redact-secrets: env file blocked" \
  redact-secrets.sh '{"tool_input":{"file_path":"/tmp/x/.env.local"}}' 2
expect_rc "redact-secrets: normal file allowed" \
  redact-secrets.sh '{"tool_input":{"file_path":"/tmp/x/main.py"}}' 0

# post-edit-lint unit tests. Fixtures are fake Node projects; the eslint
# "binary" is a shim so the hook's command selection and gating logic is
# exercised without a real toolchain.
pel_fixture() { # pel_fixture <dir> <package.json-content>
  mkdir -p "$1/node_modules/.bin"
  printf '%s' "$2" > "$1/package.json"
  printf '#!/bin/sh\n[ -n "${PEL_MARKER:-}" ] && echo ran >> "$PEL_MARKER"\n%s' "${3:-exit 0}" \
    > "$1/node_modules/.bin/eslint"
  chmod +x "$1/node_modules/.bin/eslint"
}

pel_out() { # pel_out <dir> <marker> <payload> -> hook stdout
  printf '%s' "$3" | ( cd "$1" && PEL_MARKER="$2" bash "$HOOKS/post-edit-lint.sh" ) 2>/dev/null
}

EXPECT_ESLINT='{"devDependencies":{"eslint":"9.0.0"}}'
EXPECT_BIOME='{"scripts":{"lint":"biome check ."},"devDependencies":{"@biomejs/biome":"2.4.16"}}'

# Injection regression: a crafted path must never reach a shell parser.
# The fixture declares eslint so the argv path actually runs; the $(touch)
# below must not execute.
INJ_DIR="$(mktemp -d)"
pel_fixture "$INJ_DIR" "$EXPECT_ESLINT"
PWN_FLAG="$INJ_DIR/pwned"
INJ_PAYLOAD="$(printf '{"tool_input":{"file_path":"%s/$(touch %s).ts"}}' "$INJ_DIR" "$PWN_FLAG")"
if pel_out "$INJ_DIR" /dev/null "$INJ_PAYLOAD" >/dev/null && [ ! -e "$PWN_FLAG" ]; then
  pass "post-edit-lint: crafted path executes nothing"
else
  fail "post-edit-lint: crafted path executed (eval regression)"
fi
rm -rf "$INJ_DIR"

# Non-eslint Node project (Biome): a transitively installed eslint binary
# must not be mistaken for the project's linter (issue #32).
BIOME_DIR="$(mktemp -d)"
pel_fixture "$BIOME_DIR" "$EXPECT_BIOME" 'echo "Error: --no-error-on-unmatched-pattern is not expected"; exit 1'
: > "$BIOME_DIR/src.ts"
if [[ -z "$(pel_out "$BIOME_DIR" "$BIOME_DIR/m" '{"tool_input":{"file_path":"'"$BIOME_DIR"'/src.ts"}}')" ]] \
  && [ ! -e "$BIOME_DIR/m" ]; then
  pass "post-edit-lint: biome project skipped despite stray eslint binary"
else
  fail "post-edit-lint: biome project ran non-declared eslint (issue #32)"
fi
rm -rf "$BIOME_DIR"

# eslint project with findings: rc 1 output is surfaced as additionalContext.
ESLINT_DIR="$(mktemp -d)"
pel_fixture "$ESLINT_DIR" "$EXPECT_ESLINT" 'echo "src.ts:1:1 error Missing semicolon"; exit 1'
: > "$ESLINT_DIR/src.ts"
PEL_OUT="$(pel_out "$ESLINT_DIR" /dev/null '{"tool_input":{"file_path":"'"$ESLINT_DIR"'/src.ts"}}')"
if printf '%s' "$PEL_OUT" | jq -e '.hookSpecificOutput.additionalContext | contains("Missing semicolon")' >/dev/null; then
  pass "post-edit-lint: eslint findings surfaced via additionalContext"
else
  fail "post-edit-lint: eslint findings not surfaced"
fi

# Out-of-project file: the project's linter must not run at all (issue #32).
SCRATCH_DIR="$(mktemp -d)"
: > "$SCRATCH_DIR/note.ts"
pel_out "$ESLINT_DIR" "$ESLINT_DIR/m" '{"tool_input":{"file_path":"'"$SCRATCH_DIR"'/note.ts"}}' >/dev/null
if [ ! -e "$ESLINT_DIR/m" ]; then
  pass "post-edit-lint: out-of-project edit skipped"
else
  fail "post-edit-lint: out-of-project edit ran project linter (issue #32)"
fi
rm -rf "$SCRATCH_DIR"

# Markup/style extensions never trigger the linter (issue #32).
EXT_OK=1
for EXT in html css scss astro vue svg; do
  : > "$ESLINT_DIR/file.$EXT"
  pel_out "$ESLINT_DIR" "$ESLINT_DIR/m" '{"tool_input":{"file_path":"'"$ESLINT_DIR"'/file.'"$EXT"'"}}' >/dev/null
  [ -e "$ESLINT_DIR/m" ] && EXT_OK=0
done
if [ "$EXT_OK" -eq 1 ]; then
  pass "post-edit-lint: markup/style extensions skipped"
else
  fail "post-edit-lint: markup/style extension triggered linter (issue #32)"
fi

# Linter failure (rc >= 2) is misconfiguration, not findings — never surfaced.
FAIL_DIR="$(mktemp -d)"
pel_fixture "$FAIL_DIR" "$EXPECT_ESLINT" 'echo "eslint: bad config"; exit 2'
: > "$FAIL_DIR/src.ts"
if [[ -z "$(pel_out "$FAIL_DIR" /dev/null '{"tool_input":{"file_path":"'"$FAIL_DIR"'/src.ts"}}')" ]]; then
  pass "post-edit-lint: linter failure (rc 2) not surfaced as findings"
else
  fail "post-edit-lint: linter failure surfaced as findings"
fi
rm -rf "$FAIL_DIR" "$ESLINT_DIR"

# ssh directory coverage: any key name under $HOME/.ssh blocks
SSH_HOME="$(mktemp -d)"
mkdir -p "$SSH_HOME/.ssh"
if printf '%s' "{\"tool_input\":{\"file_path\":\"$SSH_HOME/.ssh/deploy_key_custom\"}}" | HOME="$SSH_HOME" bash "$HOOKS/redact-secrets.sh" >/dev/null 2>&1; then
  fail "redact-secrets: ssh directory not blocked"
else
  pass "redact-secrets: ssh directory blocked (any key name)"
fi
rm -rf "$SSH_HOME"

# --- Live tests: real Claude Code hook invocations ---

if ! command -v claude >/dev/null 2>&1; then
  echo "SKIP: live hook tests (claude not on PATH)"
  echo "Result: $PASS passed, $FAIL failed (unit only)"
  [ "$FAIL" -eq 0 ] || { echo "Failed: ${FAIL_LIST[*]}"; exit 1; }
  exit 0
fi

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/hooks-contract.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT

# Scratch git repo so `git reset --hard` resolves a HEAD in both outcomes.
( cd "$SCRATCH" && git init -q && git commit --allow-empty -qm init )

# Wire the repo's real hooks via --settings (paths must be absolute).
python3 - "$SCRATCH" "$HOOKS" <<'PY'
import json, sys
scratch, hooks = sys.argv[1], sys.argv[2]
settings = {
    "hooks": {
        "SessionStart": [
            {"hooks": [{"type": "command", "command": f"{hooks}/session-start.sh"}]}
        ],
        "PreToolUse": [
            {"matcher": "Bash",
             "hooks": [{"type": "command", "command": f"{hooks}/block-dangerous.sh"}]}
        ],
    }
}
with open(f"{scratch}/settings.json", "w") as f:
    json.dump(settings, f)
PY

PROMPT="Run this exact command using the Bash tool and report the exact outcome text: echo 'DROP TABLE users; -- hooks-contract'"

# One timed run (python3 wrapper: `timeout` is not portable to macOS).
# Prompt passed as argv — piping it via stdin would collide with this heredoc.
OUT="$(python3 - "$COMMAND_TIMEOUT_SECONDS" "$SCRATCH" "$PROMPT" <<'PY'
import subprocess, sys
timeout_s, scratch, prompt = int(sys.argv[1]), sys.argv[2], sys.argv[3]
try:
    proc = subprocess.run(
        ["claude", "-p", "--settings", f"{scratch}/settings.json",
         "--permission-mode", "acceptEdits", prompt],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, cwd=scratch, timeout=timeout_s,
    )
    sys.stdout.write(proc.stdout)
    raise SystemExit(proc.returncode)
except subprocess.TimeoutExpired:
    sys.stdout.write(f"\nTIMEOUT after {timeout_s}s\n")
    raise SystemExit(124)
PY
)"

# Assert 1: the SessionStart hook received its payload (real session_id).
LOG="$SCRATCH/.claude/.logs/hooks.log"
if [ -f "$LOG" ]; then
  if grep -q 'sid=?' "$LOG"; then
    fail "live: session-start hook received empty stdin payload"
  else
    pass "live: session-start hook received stdin payload"
  fi
else
  fail "live: session-start hook produced no log"
fi

# Assert 2: block-dangerous actually blocked the command in hook context.
if printf '%s\n' "$OUT" | grep -q 'Blocked: Destructive SQL'; then
  pass "live: block-dangerous enforced in hook context"
elif printf '%s\n' "$OUT" | grep -q 'PreToolUse:Bash hook error'; then
  pass "live: block-dangerous enforced in hook context"
else
  fail "live: block-dangerous did not block (output: $(printf '%s' "$OUT" | tr '\n' ' ' | cut -c1-200))"
fi

echo
echo "Result: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  echo "Failed: ${FAIL_LIST[*]}"
  exit 1
fi
