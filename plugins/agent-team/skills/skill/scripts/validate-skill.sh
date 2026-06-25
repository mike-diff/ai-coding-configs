#!/usr/bin/env bash
# validate-skill.sh — Validates a SKILL.md against the agentskills.io specification.
# Usage: scripts/validate-skill.sh <path-to-skill-directory>
# Example: scripts/validate-skill.sh .claude/skills/my-skill

set -euo pipefail

SKILL_DIR="${1:-}"

if [[ -z "$SKILL_DIR" ]]; then
  echo "ERROR: No skill directory provided." >&2
  echo "Usage: $0 <path-to-skill-directory>" >&2
  exit 1
fi

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "ERROR: Directory not found: $SKILL_DIR" >&2
  exit 1
fi

SKILL_FILE="$SKILL_DIR/SKILL.md"
if [[ ! -f "$SKILL_FILE" ]]; then
  echo "ERROR: SKILL.md not found in $SKILL_DIR" >&2
  exit 1
fi

ERRORS=0
WARNINGS=0
DIR_NAME="$(basename "$SKILL_DIR")"

pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo "  ⚠️  $1"; WARNINGS=$((WARNINGS + 1)); }

echo ""
echo "Validating: $SKILL_FILE"
echo "────────────────────────────────────────"

# ── Frontmatter presence ──────────────────────────────────────────────────────
echo ""
echo "Frontmatter"

if ! head -1 "$SKILL_FILE" | grep -q '^---$'; then
  fail "File must start with '---' (YAML frontmatter)"
else
  pass "Starts with frontmatter delimiter"
fi

# Extract frontmatter block
FRONTMATTER=$(awk '/^---$/{if(++c==2) exit} c==1' "$SKILL_FILE")

# ── name field ────────────────────────────────────────────────────────────────
# Strip the key, surrounding quotes, and edge whitespace (xargs avoided — it
# chokes on unbalanced quotes/apostrophes in values).
NAME=$(echo "$FRONTMATTER" | grep '^name:' | head -1 \
  | sed -e 's/^name:[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^["'"'"']//' -e 's/["'"'"']$//')

if [[ -z "$NAME" ]]; then
  fail "Missing required 'name' field"
else
  pass "name field present: '$NAME'"

  # Length
  if [[ ${#NAME} -gt 64 ]]; then
    fail "name exceeds 64 characters (${#NAME} chars)"
  else
    pass "name length OK (${#NAME} chars)"
  fi

  # Valid characters: lowercase letters, numbers, hyphens only
  if echo "$NAME" | grep -qE '[^a-z0-9-]'; then
    fail "name contains invalid characters (only a-z, 0-9, - allowed)"
  else
    pass "name characters valid"
  fi

  # No leading/trailing hyphen
  if echo "$NAME" | grep -qE '^-|-$'; then
    fail "name must not start or end with a hyphen"
  else
    pass "name has no leading/trailing hyphens"
  fi

  # No consecutive hyphens
  if echo "$NAME" | grep -q '\-\-'; then
    fail "name must not contain consecutive hyphens (--)"
  else
    pass "name has no consecutive hyphens"
  fi

  # No XML tags — match an actual tag (<tag> or </tag>), not a bare '<'/'>' which
  # can appear legitimately (comparisons, arrows). A name with raw <> already fails
  # the charset check above; this keeps the message accurate.
  if echo "$NAME" | grep -qE '</?[a-zA-Z]'; then
    fail "name must not contain XML tags (e.g. <tag>)"
  else
    pass "name has no XML tags"
  fi

  # No reserved words — whole-token match so a coincidental substring (e.g.
  # 'claudette') is not rejected, while 'claude' or 'my-claude-tool' is.
  if echo "$NAME" | grep -qiwE 'anthropic|claude'; then
    fail "name must not contain reserved words (anthropic, claude)"
  else
    pass "name has no reserved words"
  fi

  # Matches directory name
  if [[ "$NAME" != "$DIR_NAME" ]]; then
    fail "name '$NAME' does not match directory name '$DIR_NAME'"
  else
    pass "name matches directory name"
  fi
fi

# ── description field ─────────────────────────────────────────────────────────
echo ""
echo "Description"

DESC=$(echo "$FRONTMATTER" | grep '^description:' | head -1 \
  | sed -e 's/^description:[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^["'"'"']//' -e 's/["'"'"']$//')

if [[ -z "$DESC" ]]; then
  fail "Missing required 'description' field"
else
  pass "description field present"

  DESC_LEN=${#DESC}
  if [[ $DESC_LEN -gt 1024 ]]; then
    fail "description exceeds 1024 characters ($DESC_LEN chars)"
  else
    pass "description length OK ($DESC_LEN chars)"
  fi

  # No XML tags (the description is injected into the system prompt). Match an actual
  # tag (<tag> or </tag>), not a bare '<'/'>' — descriptions legitimately use these
  # for comparisons ('use when > 3 columns') and the skill's own docs recommend
  # mentioning <details> for old patterns.
  if echo "$DESC" | grep -qE '</?[a-zA-Z]'; then
    fail "description must not contain XML tags (e.g. <tag>)"
  else
    pass "description has no XML tags"
  fi

  # Heuristic: should contain "use when" or "activates when" or "when working"
  if echo "$DESC" | grep -iqE 'use when|activates when|when working|when building|when creating|when you need'; then
    pass "description includes when-to-use trigger"
  else
    warn "description may be missing a when-to-use trigger (e.g. 'Use when...')"
  fi

  # Heuristic: should be third person (no first/second person)
  if echo "$DESC" | grep -iqE '\bI can\b|\bI will\b|\byou can\b|\byou will\b|\byou.ll\b|\bwe can\b'; then
    warn "description may not be in third person (avoid 'I can…'/'You can…')"
  else
    pass "description reads as third person"
  fi
fi

# ── Body content ──────────────────────────────────────────────────────────────
echo ""
echo "Body"

LINE_COUNT=$(wc -l < "$SKILL_FILE")
if [[ $LINE_COUNT -gt 500 ]]; then
  warn "SKILL.md is $LINE_COUNT lines — over 500 line recommendation. Move detail to references/"
else
  pass "Line count OK ($LINE_COUNT lines)"
fi

# ── Optional directories ──────────────────────────────────────────────────────
echo ""
echo "Optional Directories"

for dir in references scripts assets; do
  if [[ -d "$SKILL_DIR/$dir" ]]; then
    COUNT=$(find "$SKILL_DIR/$dir" -maxdepth 1 -type f | wc -l | xargs)
    pass "$dir/ present ($COUNT file(s))"
  else
    warn "$dir/ not present (optional but recommended for robust skills)"
  fi
done

# ── File references depth check ───────────────────────────────────────────────
echo ""
echo "File References"

# Match markdown links with deep relative paths: [text](some/deep/path)
# Exclude external URLs (http/https) and anchors (#)
DEEP_REFS=$(grep -oE '\[[^]]*\]\([^)]*\/[^)]*\/[^)]*\)' "$SKILL_FILE" 2>/dev/null | \
  grep -vE '\]\(https?://' | grep -vE '\]\(#' || true)
if [[ -n "$DEEP_REFS" ]]; then
  fail "Deep file references found (keep one level deep from SKILL.md):"
  echo "$DEEP_REFS" | sed 's/^/    /'
else
  pass "No deep file references detected"
fi

# Windows-style backslash paths in markdown links (warn — many skills are clean,
# so a violation shouldn't fail the build).
BACKSLASH_REFS=$(grep -oE '\]\([^)]*\\[^)]*\)' "$SKILL_FILE" 2>/dev/null || true)
if [[ -n "$BACKSLASH_REFS" ]]; then
  warn "Backslash in file reference (use forward slashes):"
  echo "$BACKSLASH_REFS" | sed 's/^/    /'
else
  pass "No Windows-style (backslash) paths in references"
fi

# ── Reference tables of contents ──────────────────────────────────────────────
# Reference files >100 lines should open with a table of contents so Claude sees
# the full scope under partial reads. Warn-only — long refs without a ToC are
# common across skills and must not fail the build.
if [[ -d "$SKILL_DIR/references" ]]; then
  echo ""
  echo "Reference Tables of Contents"
  TOC_CHECKED=0
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    REF_LINES=$(wc -l < "$ref")
    if [[ $REF_LINES -gt 100 ]]; then
      TOC_CHECKED=1
      if head -30 "$ref" | grep -qiE '^##+[[:space:]]+(contents|table of contents)'; then
        pass "$(basename "$ref") (${REF_LINES} lines) has a table of contents"
      else
        warn "$(basename "$ref") (${REF_LINES} lines) is missing a '## Contents' table of contents"
      fi
    fi
  done < <(find "$SKILL_DIR/references" -maxdepth 1 -type f -name '*.md')
  [[ $TOC_CHECKED -eq 0 ]] && pass "No reference files over 100 lines"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────"
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo "✅ Valid — no errors, no warnings"
elif [[ $ERRORS -eq 0 ]]; then
  echo "⚠️  Valid with $WARNINGS warning(s) — review before publishing"
else
  echo "❌ Invalid — $ERRORS error(s), $WARNINGS warning(s)"
  exit 1
fi
echo ""
