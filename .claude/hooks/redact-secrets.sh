#!/usr/bin/env bash
set -euo pipefail

# PreToolUse Hook (matcher: Read)
# Blocks reading files that contain secrets or sensitive data.
# Exit 0 = allow the read
# Exit 2 = block the read (stderr fed back to Claude)
#
# Input: JSON via stdin with tool_input.file_path or tool_input.path

# Debug logging
LOG_DIR="${CLAUDE_PLUGIN_DATA:-${CLAUDE_PROJECT_DIR:-.}/.claude/.logs}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hooks.log"

log() {
  echo "[$(date '+%H:%M:%S')] [redact-secrets] $1" >> "$LOG_FILE"
}

# CHECK/ALLOWED lines are per-call noise; blocks always log.
# Set CLAUDE_HOOK_DEBUG=1 to trace every invocation.
debug() {
  [[ "${CLAUDE_HOOK_DEBUG:-0}" == "1" ]] || return 0
  log "$1"
}

# Read JSON input from stdin
INPUT="$(cat)"
if [[ -z "$INPUT" ]]; then
  exit 0
fi

# Extract the file path from tool input
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

BASENAME="$(basename "$FILE_PATH")"

debug "CHECK: $FILE_PATH"

# --- Block the user's ssh directory (any key type, any file name) ---

case "$FILE_PATH" in
  "$HOME"/.ssh/*)
    log "BLOCKED: ssh directory ($FILE_PATH)"
    echo "Blocked: $FILE_PATH is in your .ssh directory and was not sent to the model." >&2
    exit 2
    ;;
esac

# --- Block known sensitive file patterns by name ---

case "$BASENAME" in
  .env|.env.local|.env.production|.env.staging|.env.development)
    log "BLOCKED: env file ($BASENAME)"
    echo "Blocked: $BASENAME contains environment secrets and was not sent to the model." >&2
    exit 2
    ;;
  credentials.json|service-account.json|*.pem|*.key|id_rsa|id_ed25519)
    log "BLOCKED: credentials/key file ($BASENAME)"
    echo "Blocked: $BASENAME is a credentials/key file and was not sent to the model." >&2
    exit 2
    ;;
esac

# Block .env files with any suffix (.env.*)
if echo "$BASENAME" | grep -qE '^\.env\.'; then
  log "BLOCKED: env file variant ($BASENAME)"
  echo "Blocked: $BASENAME looks like an env file and was not sent to the model." >&2
  exit 2
fi

# --- Scan file content for high-confidence secret patterns ---
# grep reads the file directly (streamed, no size cap) so a secret at any
# offset is caught.

if [[ -f "$FILE_PATH" ]] && [[ -r "$FILE_PATH" ]]; then
  if grep -qE 'AKIA[0-9A-Z]{16}' "$FILE_PATH" 2>/dev/null; then
    log "BLOCKED: contains AWS access key"
    echo "Blocked: file contains what appears to be an AWS access key." >&2
    exit 2
  fi

  if grep -qE '(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36,}' "$FILE_PATH" 2>/dev/null; then
    log "BLOCKED: contains GitHub token"
    echo "Blocked: file contains what appears to be a GitHub token." >&2
    exit 2
  fi

  if grep -qE -- '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' "$FILE_PATH" 2>/dev/null; then
    log "BLOCKED: contains private key"
    echo "Blocked: file contains a private key." >&2
    exit 2
  fi

  if grep -qE 'xox[bpors]-[0-9a-zA-Z-]{10,}' "$FILE_PATH" 2>/dev/null; then
    log "BLOCKED: contains Slack token"
    echo "Blocked: file contains what appears to be a Slack token." >&2
    exit 2
  fi
fi

debug "ALLOWED"
exit 0
