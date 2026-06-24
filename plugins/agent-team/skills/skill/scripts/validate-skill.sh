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
NAME=$(echo "$FRONTMATTER" | grep '^name:' | sed 's/^name: *//' | tr -d '"'"'" | xargs)

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

  # No XML tags
  if echo "$NAME" | grep -qE '[<>]'; then
    fail "name must not contain XML tags (< or >)"
  else
    pass "name has no XML tags"
  fi

  # No reserved words
  if echo "$NAME" | grep -qiE 'anthropic|claude'; then
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

DESC=$(echo "$FRONTMATTER" | grep '^description:' | sed 's/^description: *//' | tr -d '"' | xargs)

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

  # Heuristic: should contain "use when" or "activates when" or "when working"
  if echo "$DESC" | grep -iqE 'use when|activates when|when working|when building|when creating|when you need'; then
    pass "description includes when-to-use trigger"
  else
    warn "description may be missing a when-to-use trigger (e.g. 'Use when...')"
  fi

  # No XML tags (description is injected into the system prompt)
  if echo "$DESC" | grep -qE '[<>]'; then
    fail "description must not contain XML tags (< or >)"
  else
    pass "description has no XML tags"
  fi

  # Heuristic: should be written in third person
  if echo "$DESC" | grep -iqE '\bI can\b|\bI will\b|\byou can\b|\byou will\b|\byou'"'"'ll\b|\bwe can\b'; then
    warn "description may not be third person (avoid 'I can…'/'You can…')"
  else
    pass "description appears to be third person"
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

# Windows-style paths: backslash inside a markdown link target
BACKSLASH_REFS=$(grep -oE '\]\([^)]*\\[^)]*\)' "$SKILL_FILE" 2>/dev/null || true)
if [[ -n "$BACKSLASH_REFS" ]]; then
  warn "Windows-style path(s) found — use forward slashes:"
  echo "$BACKSLASH_REFS" | sed 's/^/    /'
else
  pass "No Windows-style paths detected"
fi

# ── Reference tables of contents ──────────────────────────────────────────────
# Reference files over 100 lines should include a ## Contents / ## Table of Contents
# near the top, so partial reads still reveal the file's full scope.
echo ""
echo "Reference Tables of Contents"

if [[ -d "$SKILL_DIR/references" ]]; then
  TOC_CHECKED=0
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    TOC_CHECKED=1
    REF_LINES=$(wc -l < "$ref")
    if [[ $REF_LINES -gt 100 ]]; then
      if head -30 "$ref" | grep -qiE '^##+ (contents|table of contents)'; then
        pass "$(basename "$ref") ($REF_LINES lines) has a table of contents"
      else
        warn "$(basename "$ref") ($REF_LINES lines) has no '## Contents' near the top"
      fi
    fi
  done < <(find "$SKILL_DIR/references" -maxdepth 1 -name '*.md' -type f)
  [[ $TOC_CHECKED -eq 0 ]] && pass "No reference files to check"
else
  pass "No references/ directory"
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
