#!/usr/bin/env bash
# tests/smoke.sh
# End-to-end smoke test: invokes each plugin slash command, asserts exit 0.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/agent-team"

COMMANDS=(ask dev discuss issue orient primitives skill spec ticket to-dos)

PASS=0
FAIL=0
FAIL_LIST=()

for cmd in "${COMMANDS[@]}"; do
  printf "Testing /agent-team:%-20s ... " "$cmd"
  output=$(claude --plugin-dir "$PLUGIN_DIR" --print "/agent-team:$cmd --help" 2>&1)
  exit_code=$?
  if [ "$exit_code" -eq 0 ] && [ -n "$output" ]; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL (exit=$exit_code)"
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
