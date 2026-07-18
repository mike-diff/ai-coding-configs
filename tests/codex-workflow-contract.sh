#!/usr/bin/env bash
# Static and installer contract tests for the native Codex workflow surface.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1"
  local needle="$2"
  grep -Fq "$needle" "$file" || fail "$file missing required text: $needle"
}

assert_file_not_contains() {
  local file="$1"
  local needle="$2"
  if grep -Fq "$needle" "$file"; then
    fail "$file contains Claude-only text: $needle"
  fi
}

assert_frontmatter_keys() {
  local file="$1"
  local expected_name="$2"
  local frontmatter

  frontmatter=$(awk '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { exit }
    in_frontmatter { print }
  ' "$file")

  printf '%s\n' "$frontmatter" | grep -Fqx "name: $expected_name" ||
    fail "$file frontmatter name is not $expected_name"
  printf '%s\n' "$frontmatter" | grep -Eq '^description: .+' ||
    fail "$file frontmatter lacks a description"

  local key_count
  key_count=$(printf '%s\n' "$frontmatter" | grep -Ec '^[a-zA-Z0-9_-]+:')
  [ "$key_count" -eq 2 ] || fail "$file frontmatter must contain only name and description"
}

for skill in discuss spec dev; do
  skill_dir=".agents/skills/$skill"
  [ -f "$skill_dir/SKILL.md" ] || fail "missing $skill_dir/SKILL.md"
  [ -f "$skill_dir/references/workflow.md" ] || fail "missing $skill_dir/references/workflow.md"
  [ -f "$skill_dir/agents/openai.yaml" ] || fail "missing $skill_dir/agents/openai.yaml"

  assert_frontmatter_keys "$skill_dir/SKILL.md" "$skill"
  assert_file_contains "$skill_dir/agents/openai.yaml" "allow_implicit_invocation: false"
  assert_file_contains "$skill_dir/agents/openai.yaml" "\$$skill"
  assert_file_contains "$skill_dir/SKILL.md" "references/workflow.md"

  for claude_primitive in "\$ARGUMENTS" TaskCreate TaskUpdate TeamCreate TeamDelete "delegate mode" "/compact"; do
    assert_file_not_contains "$skill_dir/SKILL.md" "$claude_primitive"
    assert_file_not_contains "$skill_dir/references/workflow.md" "$claude_primitive"
  done
done

discuss_workflow=".agents/skills/discuss/references/workflow.md"
assert_file_contains "$discuss_workflow" "Fresh"
assert_file_contains "$discuss_workflow" "Revisit"
assert_file_contains "$discuss_workflow" "Reference-driven"
assert_file_contains "$discuss_workflow" "mandatory blind-spot"
assert_file_contains "$discuss_workflow" "<adlc-handoff>"
assert_file_contains "$discuss_workflow" "recommended_next: \$spec"
assert_file_contains "$discuss_workflow" "recommended_next: \$dev"
assert_file_contains "$discuss_workflow" "Do not implement"

spec_workflow=".agents/skills/spec/references/workflow.md"
assert_file_contains "$spec_workflow" "## Requirement Contract"
assert_file_contains "$spec_workflow" "## Requirement Validation"
assert_file_contains "$spec_workflow" "explicit approval"
assert_file_contains "$spec_workflow" "## Architecture Plan"
assert_file_contains "$spec_workflow" "## Architecture Validation"
assert_file_contains "$spec_workflow" "## Goal Condition"
assert_file_contains "$spec_workflow" "/goal"
assert_file_contains "$spec_workflow" ".context/specs/spec-[feature-name].md"
assert_file_contains "$spec_workflow" "Do not stage or commit"

dev_workflow=".agents/skills/dev/references/workflow.md"
assert_file_contains "$dev_workflow" "Ad hoc"
assert_file_contains "$dev_workflow" "Spec-backed"
assert_file_contains "$dev_workflow" "Single-phase"
assert_file_contains "$dev_workflow" "Sweep"
assert_file_contains "$dev_workflow" "Unattended"
assert_file_contains "$dev_workflow" "one writer"
assert_file_contains "$dev_workflow" "pre-existing"
assert_file_contains "$dev_workflow" "## Reflection"
assert_file_contains "$dev_workflow" "risk-triggered review"
assert_file_contains "$dev_workflow" "committed"
assert_file_contains "$dev_workflow" "pr-ready"
assert_file_contains "$dev_workflow" "blocked"
assert_file_contains "$dev_workflow" "failed"
assert_file_contains "$dev_workflow" "Commit only when"

[ -x scripts/install-codex.sh ] || fail "scripts/install-codex.sh must be executable"

install_fixture=$(mktemp -d)
conflict_fixture=$(mktemp -d)
late_conflict_fixture=$(mktemp -d)
trap 'rm -rf "$install_fixture" "$conflict_fixture" "$late_conflict_fixture"' EXIT

CODEX_WORKFLOW_HOME="$install_fixture" scripts/install-codex.sh >/dev/null
CODEX_WORKFLOW_HOME="$install_fixture" scripts/install-codex.sh >/dev/null

for skill in discuss spec dev; do
  target="$install_fixture/.agents/skills/$skill"
  [ -L "$target" ] || fail "installer did not create symlink: $target"
  [ "$(readlink -f "$target")" = "$REPO_ROOT/.agents/skills/$skill" ] ||
    fail "installer linked $skill to the wrong source"
done

mkdir -p "$conflict_fixture/.agents/skills/discuss"
if CODEX_WORKFLOW_HOME="$conflict_fixture" scripts/install-codex.sh >/dev/null 2>&1; then
  fail "installer overwrote a conflicting global skill"
fi
[ -d "$conflict_fixture/.agents/skills/discuss" ] || fail "installer removed the conflict target"

mkdir -p "$late_conflict_fixture/.agents/skills/spec"
if CODEX_WORKFLOW_HOME="$late_conflict_fixture" scripts/install-codex.sh >/dev/null 2>&1; then
  fail "installer accepted a conflict after an installable skill"
fi
[ ! -e "$late_conflict_fixture/.agents/skills/discuss" ] ||
  fail "installer partially installed skills before reporting a later conflict"
[ -d "$late_conflict_fixture/.agents/skills/spec" ] ||
  fail "installer removed the later conflict target"

echo "codex-workflow-contract: ok"
