#!/usr/bin/env bash
# scripts/sync-plugin.sh
# Sync the plugin tree from the standalone .claude/ source.
# Idempotent: safe to run multiple times.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/.claude"
DST="$REPO_ROOT/plugins/agent-team"

SKILL_NAMES='ask|code-review|dev|discuss|issue|loop-patterns|orient|primitives|skill|spec|team-orchestration|testing-patterns|ticket|to-dos'

echo "Syncing $SRC -> $DST"

# 1. Agents (byte-identical, hooks: already stripped from source)
mkdir -p "$DST/agents"
cp -R "$SRC/agents/." "$DST/agents/"

# 2. Output styles (byte-identical)
mkdir -p "$DST/output-styles"
cp -R "$SRC/output-styles/." "$DST/output-styles/"

# 3. Rules source (byte-identical)
mkdir -p "$DST/rules-source"
cp -R "$SRC/rules/." "$DST/rules-source/"

# 4. Hooks (byte-identical, log-path env-fallback already in source)
mkdir -p "$DST/hooks"
# preserve hooks.json (plugin-only, not in source)
HOOKS_JSON_BACKUP=""
if [ -f "$DST/hooks/hooks.json" ]; then
  HOOKS_JSON_BACKUP="$(cat "$DST/hooks/hooks.json")"
fi
# preserve inject-rules.sh (plugin-only)
INJECT_RULES_BACKUP=""
if [ -f "$DST/hooks/inject-rules.sh" ]; then
  INJECT_RULES_BACKUP="$(cat "$DST/hooks/inject-rules.sh")"
fi
cp -R "$SRC/hooks/." "$DST/hooks/"
# restore plugin-only files
if [ -n "$HOOKS_JSON_BACKUP" ]; then
  printf '%s\n' "$HOOKS_JSON_BACKUP" > "$DST/hooks/hooks.json"
fi
if [ -n "$INJECT_RULES_BACKUP" ]; then
  printf '%s\n' "$INJECT_RULES_BACKUP" > "$DST/hooks/inject-rules.sh"
fi
chmod +x "$DST/hooks/"*.sh

# 5. Skills (copy + namespace prefix sed + hardcoded path rewrites)
mkdir -p "$DST/skills"
# Clear destination first to avoid stale files when source removes a skill
rm -rf "$DST/skills/"*
cp -R "$SRC/skills/." "$DST/skills/"

# Apply namespace prefix to all .md files in plugin skills
find "$DST/skills" -name "*.md" -print0 | xargs -0 perl -i -pe \
  "s{(?<![:/\\w-])/($SKILL_NAMES)\\b(?!:)}{/agent-team:\$1}g"

# Hardcoded path rewrites in skill/SKILL.md
perl -i -pe \
  's{ls -la \.claude/skills/}{ls -la "${CLAUDE_PROJECT_DIR}/.claude/skills/}g; \
   s{bash \.claude/skills/skill/scripts/validate-skill\.sh \.claude/skills/}{bash "${CLAUDE_PLUGIN_ROOT}/skills/skill/scripts/validate-skill.sh" "${CLAUDE_PROJECT_DIR}/.claude/skills/}g' \
  "$DST/skills/skill/SKILL.md"

# Same rewrites in skill-author.md (already copied to $DST/agents/ in step 1)
perl -i -pe \
  's{bash \.claude/skills/skill/scripts/validate-skill\.sh \.claude/skills/}{bash "${CLAUDE_PLUGIN_ROOT}/skills/skill/scripts/validate-skill.sh" "${CLAUDE_PROJECT_DIR}/.claude/skills/}g' \
  "$DST/agents/skill-author.md"

# 6. Verification: no unprefixed slash-command refs in plugin skills
UNPREFIXED=$(perl -ne 'print "$ARGV:$.: $_" if /(?<![:\/\w-])\/(ask|code-review|dev|discuss|issue|loop-patterns|orient|primitives|skill|spec|team-orchestration|testing-patterns|ticket|to-dos)\b(?!:)/' $(find "$DST/skills" -name "*.md") 2>/dev/null | grep -v "/agent-team:" || true)
if [ -n "$UNPREFIXED" ]; then
  echo "WARNING: unprefixed slash-command references remain:" >&2
  echo "$UNPREFIXED" >&2
  exit 1
fi

echo "Sync complete."
