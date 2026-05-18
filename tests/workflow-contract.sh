#!/usr/bin/env bash
# tests/workflow-contract.sh
# Static contract tests for the lightweight ADLC flow across discuss/spec/dev.

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

assert_no_default_docs_specs() {
  local matches
  matches=$(rg -n 'Save complete specification to: `docs/specs|Saved to docs/specs|@docs/specs|File: docs/specs|File:\*\* `docs/specs|Saves to docs/specs' .claude .cursor README.md plugins/agent-team || true)
  [ -z "$matches" ] || fail "spec default still points at committed docs/specs:\n$matches"
}

assert_order() {
  local file="$1"
  local first="$2"
  local second="$3"
  local first_line second_line
  first_line=$(grep -nF "$first" "$file" | head -1 | cut -d: -f1 || true)
  second_line=$(grep -nF "$second" "$file" | head -1 | cut -d: -f1 || true)
  [ -n "$first_line" ] || fail "$file missing first marker: $first"
  [ -n "$second_line" ] || fail "$file missing second marker: $second"
  [ "$first_line" -lt "$second_line" ] || fail "$file expected '$first' before '$second'"
}

# /discuss must hand off a compact ADLC seed to /spec.
for prefix in .claude .cursor; do
  assert_file_contains "$prefix/skills/discuss/references/phases.md" "<adlc-handoff>"
  assert_file_contains "$prefix/skills/discuss/references/phases.md" "human_decisions_required:"
done

# /spec must perform spec validation and architecture validation internally.
for prefix in .claude .cursor; do
  assert_file_contains "$prefix/skills/spec/references/workflow.md" "## Requirement Contract"
  assert_file_contains "$prefix/skills/spec/references/workflow.md" "## Requirement Validation"
  assert_file_contains "$prefix/skills/spec/references/workflow.md" "## Architecture Plan"
  assert_file_contains "$prefix/skills/spec/references/workflow.md" "## Architecture Validation"
  assert_file_contains "$prefix/skills/spec/references/workflow.md" "component:"
  assert_file_contains "$prefix/skills/spec/references/workflow.md" "concerns: []"
done
assert_file_contains ".cursor/skills/spec/references/workflow.md" "Build in Parallel"
assert_file_contains ".cursor/skills/spec/references/workflow.md" "Safe Parallelization"

# /dev must clarify before team-up/plan and include reflect/review/wrapup phases.
assert_order ".claude/skills/dev/references/workflow.md" "## Phase 3: Clarify" "## Phase 4: Team Up"
assert_order ".cursor/skills/dev/references/workflow.md" "## Phase 3: Clarify" "## Phase 4: Plan"
for prefix in .claude .cursor; do
  assert_file_contains "$prefix/skills/dev/references/workflow.md" "Spec-backed mode"
  assert_file_contains "$prefix/skills/dev/references/workflow.md" "## Phase 6: Reflect"
  assert_file_contains "$prefix/skills/dev/references/workflow.md" "Wrapup"
  assert_file_contains "$prefix/skills/dev/references/workflow.md" "Review council triggers"
done
assert_file_contains ".cursor/skills/dev/references/workflow.md" "/multitask"

# Implementers must escalate high-risk assumptions instead of always proceeding.
for agent in .claude/agents/implementer.md .cursor/agents/implementer.md; do
  assert_file_contains "$agent" "High-risk assumptions"
  assert_file_contains "$agent" "stop and ask"
done

# Pi project-local skills provide maintainer entry points without adding a fourth source of truth.
assert_file_contains ".pi/AGENTS.md" "Agent Team"
assert_file_contains ".pi/AGENTS.md" "scripts/sync-plugin.sh"
for skill in agent-team-discuss agent-team-spec agent-team-dev; do
  [ -f ".pi/skills/$skill/SKILL.md" ] || fail "missing pi skill: $skill"
  assert_file_contains ".pi/skills/$skill/SKILL.md" "name: $skill"
  assert_file_contains ".pi/skills/$skill/SKILL.md" "source of truth"
done
assert_file_contains ".pi/skills/agent-team-spec/SKILL.md" ".context/specs/spec-[feature-name].md"
assert_file_contains ".pi/skills/agent-team-dev/SKILL.md" "Spec-backed mode"
assert_file_contains ".pi/skills/agent-team-discuss/SKILL.md" "<adlc-handoff>"

# Specs default to uncommitted agent context, not committed docs.
assert_file_contains ".gitignore" ".context/"
assert_file_contains ".claude/skills/spec/references/workflow.md" ".context/specs/spec-[feature-name].md"
assert_file_contains ".cursor/skills/spec/references/workflow.md" ".context/specs/spec-[feature-name].md"
assert_file_contains ".claude/skills/dev/references/workflow.md" "@.context/specs/..."
assert_file_contains ".cursor/skills/dev/references/workflow.md" "@.context/specs/..."
assert_no_default_docs_specs

# Plugin parity: slop-check is official and smoke tests cannot hang indefinitely.
assert_file_contains "scripts/sync-plugin.sh" "slop-check"
assert_file_contains "tests/smoke.sh" "timeout"
assert_file_contains "tests/smoke.sh" "slop-check"
[ -f "plugins/agent-team/skills/slop-check/SKILL.md" ] || fail "plugin missing slop-check skill"

echo "workflow-contract: ok"
