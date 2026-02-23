#!/usr/bin/env bash
set -euo pipefail

# PreToolUse Hook (matcher: Read)
# Blocks reading files that contain secrets or sensitive data.
# Exit 0 = allow the read
# Exit 2 = block the read (stderr fed back to Claude)
#
# Input: JSON via stdin with tool_input.file_path or tool_input.path

# Debug logging
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hooks.log"

log() {
  echo "[$(date '+%H:%M:%S')] [redact-secrets] $1" >> "$LOG_FILE"
}

# Read JSON input from stdin
INPUT="$(cat /dev/stdin 2>/dev/null || echo "")"
if [[ -z "$INPUT" ]]; then
  exit 0
fi

# Extract the file path from tool input
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

BASENAME="$(basename "$FILE_PATH")"

log "CHECK: $FILE_PATH"

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

# Only scan if the file exists and is readable
if [[ -f "$FILE_PATH" ]] && [[ -r "$FILE_PATH" ]]; then
  CONTENT="$(head -c 50000 "$FILE_PATH" 2>/dev/null)" || true

  if [[ -n "$CONTENT" ]]; then
    # AWS access keys
    if echo "$CONTENT" | grep -qE 'AKIA[0-9A-Z]{16}'; then
      log "BLOCKED: contains AWS access key"
      echo "Blocked: file contains what appears to be an AWS access key." >&2
      exit 2
    fi

    # GitHub tokens
    if echo "$CONTENT" | grep -qE '(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36,}'; then
      log "BLOCKED: contains GitHub token"
      echo "Blocked: file contains what appears to be a GitHub token." >&2
      exit 2
    fi

    # Private keys (RSA, EC, OpenSSH)
    if echo "$CONTENT" | grep -qE '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'; then
      log "BLOCKED: contains private key"
      echo "Blocked: file contains a private key." >&2
      exit 2
    fi

    # Slack tokens
    if echo "$CONTENT" | grep -qE 'xox[bpors]-[0-9a-zA-Z-]{10,}'; then
      log "BLOCKED: contains Slack token"
      echo "Blocked: file contains what appears to be a Slack token." >&2
      exit 2
    fi
  fi
fi

log "ALLOWED"
exit 0
