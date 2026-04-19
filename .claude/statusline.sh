#!/usr/bin/env bash
set -euo pipefail

# Graceful: never exit non-zero, always print something readable.
input=$(cat 2>/dev/null || echo '{}')

MODEL=$(echo "$input" | jq -r '.model.display_name // "claude"' 2>/dev/null || echo "claude")
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' 2>/dev/null | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // "N/A"' 2>/dev/null)

COST_FMT=$(printf '$%.2f' "${COST:-0}" 2>/dev/null || echo '$0.00')
if [[ "$FIVE_H" == "N/A" || -z "$FIVE_H" ]]; then
  FIVE_H_FMT="—"
else
  FIVE_H_FMT="$(printf '%.0f' "$FIVE_H" 2>/dev/null || echo '?')%"
fi

echo "[$MODEL] | ${CTX_PCT}% ctx | $COST_FMT | 5h: $FIVE_H_FMT"
