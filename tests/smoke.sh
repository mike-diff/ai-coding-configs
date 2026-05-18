#!/usr/bin/env bash
# tests/smoke.sh
# End-to-end smoke test: invokes each plugin slash command, asserts exit 0.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/agent-team"

COMMANDS=(ask dev discuss issue orient primitives skill slop-check spec ticket to-dos)
COMMAND_TIMEOUT_SECONDS=${COMMAND_TIMEOUT_SECONDS:-30}

PASS=0
FAIL=0
FAIL_LIST=()

run_with_timeout() {
  local cmd="$1"
  python3 - "$COMMAND_TIMEOUT_SECONDS" "$PLUGIN_DIR" "$cmd" <<'PY'
import subprocess
import sys

timeout_seconds = int(sys.argv[1])
plugin_dir = sys.argv[2]
command_name = sys.argv[3]

try:
    proc = subprocess.run(
        ["claude", "--plugin-dir", plugin_dir, "--print", f"/agent-team:{command_name} --help"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=timeout_seconds,
    )
    sys.stdout.write(proc.stdout)
    raise SystemExit(proc.returncode)
except subprocess.TimeoutExpired as exc:
    partial = exc.stdout or ""
    if isinstance(partial, bytes):
        partial = partial.decode("utf-8", errors="replace")
    sys.stdout.write(partial)
    sys.stdout.write(f"\nTIMEOUT after {timeout_seconds}s\n")
    raise SystemExit(124)
PY
}

for cmd in "${COMMANDS[@]}"; do
  printf "Testing /agent-team:%-20s ... " "$cmd"
  output=$(run_with_timeout "$cmd" 2>&1)
  exit_code=$?
  if [ "$exit_code" -eq 0 ] && [ -n "$output" ]; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL (exit=$exit_code)"
    echo "--- output for /agent-team:$cmd ---"
    printf '%s\n' "$output" | sed -n '1,80p'
    echo "--- end output ---"
    FAIL=$((FAIL + 1))
    FAIL_LIST+=("$cmd")
  fi
done

echo
echo "Result: $PASS/${#COMMANDS[@]} passed"
if [ "$FAIL" -gt 0 ]; then
  echo "Failed: ${FAIL_LIST[*]}"
  exit 1
fi
