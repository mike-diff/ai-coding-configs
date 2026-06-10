#!/usr/bin/env bash
set -euo pipefail

# Graceful: never exit non-zero, always print something readable.
input=$(cat 2>/dev/null || echo '{}')

MODEL=$(echo "$input" | jq -r '.model.display_name // "claude"' 2>/dev/null || echo "claude")
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)

# Rate limits only present for Claude.ai subscribers, after the first API response.
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null || true)
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null || true)
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null || true)

CTX_USED=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0' 2>/dev/null || echo 0)
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000' 2>/dev/null || echo 200000)
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null || true)

CTX_USED_K=$(awk "BEGIN { printf \"%.0f\", $CTX_USED / 1000 }" 2>/dev/null || echo "?")
CTX_SIZE_K=$(awk "BEGIN { printf \"%.0f\", $CTX_SIZE / 1000 }" 2>/dev/null || echo "?")
COST_FMT=$(printf '$%.2f' "${COST:-0}" 2>/dev/null || echo "\$0.00")

PARTS=("[$MODEL]")

if [[ -n "$FIVE_H" ]]; then
  FIVE_H_PART="5h: $(printf '%.0f' "$FIVE_H")%"
  if [[ -n "$FIVE_H_RESET" ]]; then
    RESET_HHMM=$(date -d "@${FIVE_H_RESET%.*}" +%H:%M 2>/dev/null || true)
    [[ -n "$RESET_HHMM" ]] && FIVE_H_PART+=" (resets $RESET_HHMM)"
  fi
  PARTS+=("$FIVE_H_PART")
fi

if [[ -n "$WEEK" ]]; then
  PARTS+=("7d: $(printf '%.0f' "$WEEK")%")
fi

if [[ -n "$CTX_PCT" ]]; then
  PARTS+=("ctx ${CTX_USED_K}k/${CTX_SIZE_K}k ($(printf '%.0f' "$CTX_PCT")%)")
else
  PARTS+=("ctx ${CTX_USED_K}k/${CTX_SIZE_K}k")
fi

PARTS+=("$COST_FMT")

OUT=""
for PART in "${PARTS[@]}"; do
  OUT+="${OUT:+ | }$PART"
done
echo "$OUT"
