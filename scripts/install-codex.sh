#!/usr/bin/env bash
# Link the repo-tracked Codex workflows into the personal global skill directory.
# Idempotent and conflict-safe: existing non-matching targets are never replaced.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_ROOT="$REPO_ROOT/.agents/skills"
TARGET_HOME="${CODEX_WORKFLOW_HOME:-${HOME:?HOME is required}}"
TARGET_ROOT="$TARGET_HOME/.agents/skills"
SKILLS=(discuss spec dev)

# Validate the full install set before changing the destination so a conflict in
# a later skill cannot leave an incomplete installation.
for skill in "${SKILLS[@]}"; do
  source_path="$SOURCE_ROOT/$skill"
  target_path="$TARGET_ROOT/$skill"

  [ -f "$source_path/SKILL.md" ] || {
    echo "Missing source skill: $source_path/SKILL.md" >&2
    exit 1
  }

  if [ -L "$target_path" ]; then
    existing_target=$(readlink -f "$target_path" || true)
    if [ "$existing_target" = "$source_path" ]; then
      continue
    fi

    echo "Refusing to replace existing symlink: $target_path -> $existing_target" >&2
    exit 1
  fi

  if [ -e "$target_path" ]; then
    echo "Refusing to replace existing path: $target_path" >&2
    exit 1
  fi
done

mkdir -p "$TARGET_ROOT"

for skill in "${SKILLS[@]}"; do
  source_path="$SOURCE_ROOT/$skill"
  target_path="$TARGET_ROOT/$skill"

  if [ -L "$target_path" ]; then
    echo "Already linked: \$$skill"
    continue
  fi

  ln -s "$source_path" "$target_path"
  echo "Linked \$$skill: $target_path -> $source_path"
done

echo "Codex workflows installed. Restart Codex if they do not appear in /skills."
