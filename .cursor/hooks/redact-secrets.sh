#!/bin/bash
set -euo pipefail

# beforeReadFile hook: Block reading files that contain secrets or sensitive data.
# Uses fail-closed behavior - exit 2 blocks the read.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.content // empty')

if [[ -z "$FILE_PATH" ]]; then
  echo '{"permission": "allow"}'
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")
DIR=$(dirname "$FILE_PATH")

# Block known sensitive file patterns by name
case "$BASENAME" in
  .env|.env.local|.env.production|.env.staging|.env.development)
    echo "{\"permission\": \"deny\", \"user_message\": \"Blocked: $BASENAME contains environment secrets and was not sent to the model.\"}"
    exit 2
    ;;
  credentials.json|service-account.json|*.pem|*.key|id_rsa|id_ed25519)
    echo "{\"permission\": \"deny\", \"user_message\": \"Blocked: $BASENAME is a credentials/key file and was not sent to the model.\"}"
    exit 2
    ;;
esac

# Block .env files with any suffix
if echo "$BASENAME" | grep -qE '^\.env\.'; then
  echo "{\"permission\": \"deny\", \"user_message\": \"Blocked: $BASENAME looks like an env file and was not sent to the model.\"}"
  exit 2
fi

# Scan content for high-confidence secret patterns
if [[ -n "$CONTENT" ]]; then
  # AWS keys
  if echo "$CONTENT" | grep -qE 'AKIA[0-9A-Z]{16}'; then
    echo "{\"permission\": \"deny\", \"user_message\": \"Blocked: file contains what appears to be an AWS access key.\"}"
    exit 2
  fi

  # GitHub tokens
  if echo "$CONTENT" | grep -qE '(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36,}'; then
    echo "{\"permission\": \"deny\", \"user_message\": \"Blocked: file contains what appears to be a GitHub token.\"}"
    exit 2
  fi

  # Generic private keys
  if echo "$CONTENT" | grep -qE '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'; then
    echo "{\"permission\": \"deny\", \"user_message\": \"Blocked: file contains a private key.\"}"
    exit 2
  fi

  # Slack tokens
  if echo "$CONTENT" | grep -qE 'xox[bpors]-[0-9a-zA-Z-]{10,}'; then
    echo "{\"permission\": \"deny\", \"user_message\": \"Blocked: file contains what appears to be a Slack token.\"}"
    exit 2
  fi
fi

echo '{"permission": "allow"}'
exit 0
