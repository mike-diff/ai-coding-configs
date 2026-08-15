#!/usr/bin/env bash
# check-emission.sh — Assert a candidate goal-or-loop emission obeys the hard rules.
#
# Reads a markdown emission (a rationale, one or more fenced ``` blocks, and a
# stewardship note) and checks:
#   1. Every fenced block contains ONLY the literal command (no comment/prose line,
#      no leading text before /goal or /loop).
#   2. /loop blocks have the interval (or the prompt) as the FIRST token — never a
#      comment, because /loop parses the first whitespace token to pick its mode.
#   3. A stop/status affordance appears OUTSIDE the fence.
#   4. /goal blocks include an "or stop after N turns" safety valve.
#   5. /loop self-paced blocks include a stop / omit-wakeup condition.
#   6. No "the X we discussed" placeholder leaks (block must be self-contained).
#
# Usage:
#   scripts/check-emission.sh <file>          # check a file
#   scripts/check-emission.sh -               # check stdin
#   cmd | scripts/check-emission.sh           # check stdin (piped)

set -euo pipefail

SRC="${1:--}"
if [[ "$SRC" == "-" ]]; then
  CONTENT="$(cat)"
elif [[ -f "$SRC" ]]; then
  CONTENT="$(cat "$SRC")"
else
  echo "ERROR: file not found: $SRC" >&2
  echo "Usage: $0 <file>|-   (or pipe the emission on stdin)" >&2
  exit 1
fi

ERRORS=0
fail() { echo "  FAIL: $1"; ERRORS=$((ERRORS + 1)); }
pass() { echo "  ok:   $1"; }

# Split into "inside fence" and "outside fence" using ``` toggles.
INSIDE="$(printf '%s\n' "$CONTENT" | awk '/^```/{f=!f; next} f')"
OUTSIDE="$(printf '%s\n' "$CONTENT" | awk '/^```/{f=!f; next} !f')"

if [[ -z "${INSIDE//[$'\n']/}" ]]; then
  fail "no fenced command block found"
  echo ""
  echo "RESULT: $ERRORS error(s)"
  exit 1
fi

echo "Checking fenced block(s)"

HAS_CMD=0
# Walk each non-blank line inside fences.
while IFS= read -r line; do
  [[ -z "${line//[[:space:]]/}" ]] && continue
  trimmed="$(printf '%s' "$line" | sed 's/^[[:space:]]*//')"

  # Rule 1: every content line in a fence must be a literal command.
  if [[ "$trimmed" != /goal* && "$trimmed" != /loop* ]]; then
    if [[ "$trimmed" == \#* ]]; then
      fail "comment line inside fence (breaks /loop first-token parsing): $trimmed"
    else
      fail "non-command prose inside fence (block must hold only the command): $trimmed"
    fi
    continue
  fi

  HAS_CMD=1

  # Rule 6: self-containment.
  if printf '%s' "$trimmed" | grep -qiE 'we discussed|the (one|thing|task|tests|file|repo) (we|above|from before)|as discussed'; then
    fail "non-self-contained placeholder in command: $trimmed"
  fi

  if [[ "$trimmed" == /loop* ]]; then
    # Rule 2: first token after /loop must be an interval or real prompt word,
    # never a comment marker.
    rest="$(printf '%s' "$trimmed" | sed 's#^/loop[[:space:]]*##')"
    first="$(printf '%s' "$rest" | awk '{print $1}')"
    if [[ "$first" == \#* ]]; then
      fail "/loop first token is a comment — misparses into self-paced mode: $trimmed"
    elif [[ -z "$first" ]]; then
      fail "/loop has no argument: $trimmed"
    fi
    # Rule 5: self-paced (no leading interval) needs a stop/omit-wakeup condition.
    if ! printf '%s' "$first" | grep -qE '^[0-9]+[smhd]$'; then
      if ! printf '%s' "$trimmed" | grep -qiE 'stop|omit|end |wakeup|until|when done'; then
        fail "/loop self-paced block missing a stop / omit-wakeup condition: $trimmed"
      else
        pass "/loop self-paced has a stop condition"
      fi
    else
      pass "/loop interval first token: $first"
    fi
  fi

  if [[ "$trimmed" == /goal* ]]; then
    # Rule 4: turn-cap safety valve. Accept any common phrasing of a turn/time
    # bound: "stop after N turns", "turn cap: N", "within N turns", "N-turn cap",
    # or a time clause ("stop after 1 hour"). The doc's "or stop after N turns" is
    # only one example form.
    if printf '%s' "$trimmed" | grep -qiE 'after [0-9]+ turns?|turn[ -]?cap:? *[0-9]+|cap (of |at )?[0-9]+ turns?|within [0-9]+ turns?|[0-9]+[ -]turn cap|stop after [0-9]+ (minutes?|hours?|min)'; then
      pass "/goal has a turn-cap / time safety valve"
    else
      fail "/goal missing a turn-cap safety valve (e.g. 'or stop after N turns' / 'Turn cap: N'): $trimmed"
    fi
  fi
done <<< "$INSIDE"

[[ "$HAS_CMD" -eq 1 ]] || fail "no /goal or /loop command found inside any fence"

echo "Checking stewardship affordance (outside fence)"
# Rule 3: a stop/status affordance must live outside the fence.
if printf '%s' "$OUTSIDE" | grep -qiE 'stop|cancel|interrupt|/goal clear|still running|expire|session'; then
  pass "stop/status affordance present outside the fence"
else
  fail "no stop/status affordance found outside the fence"
fi

echo ""
if [[ "$ERRORS" -eq 0 ]]; then
  echo "RESULT: emission OK — all hard rules satisfied"
else
  echo "RESULT: $ERRORS error(s) — fix before sending"
  exit 1
fi
