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
