#!/usr/bin/env bash
# tests/workflow-contract.sh
# Static contract tests for the ADLC flow across discuss/spec/dev.
# .claude assertions track the 2026 rebuilt workflows (right-sized specs, direct-build
# /dev with external verify gate, background-subagent /discuss). .cursor and .pi keep
# their own assertions until those surfaces are migrated.

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

assert_max_lines() {
  local file="$1"
  local max="$2"
  local n
  n=$(wc -l < "$file")
  [ "$n" -le "$max" ] || fail "$file is $n lines (ceiling $max) — spec volume is a bug, trim it"
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

########################################
# .claude — rebuilt workflows
########################################

# No references to removed Claude Code primitives (teams lifecycle, delegate mode,
# teams env flag, removed hook events) anywhere in the live config.
stale=$(rg -n 'TeamDelete|TeamCreate|Shift\+Tab|CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS|TeammateIdle|TaskCompleted|shutdown_request|delegate mode' .claude --glob '!.logs/**' || true)
[ -z "$stale" ] || fail "removed-primitive references remain in .claude:\n$stale"

# /discuss hands off a compact ADLC seed and triages before spinning up research.
assert_file_contains ".claude/skills/discuss/references/phases.md" "<adlc-handoff>"
assert_file_contains ".claude/skills/discuss/references/phases.md" "human_decisions_required:"
assert_file_contains ".claude/skills/discuss/SKILL.md" "Triage first"

# /spec right-sizes, keeps the contract sections, and saves as uncommitted context.
assert_file_contains ".claude/skills/spec/SKILL.md" "No spec"
assert_file_contains ".claude/skills/spec/SKILL.md" "Light spec"
assert_file_contains ".claude/skills/spec/references/workflow.md" "## Requirement Contract"
assert_file_contains ".claude/skills/spec/references/workflow.md" "## Architecture Plan"
assert_file_contains ".claude/skills/spec/references/workflow.md" "component:"
assert_file_contains ".claude/skills/spec/references/workflow.md" "concerns: []"
assert_file_contains ".claude/skills/spec/references/workflow.md" ".context/specs/spec-[feature-name].md"
assert_file_contains ".claude/skills/spec/references/workflow.md" "Implement all phases autonomously"

# /spec emits a transcript-verifiable Goal Condition per phase (native /goal driver).
assert_file_contains ".claude/skills/spec/references/workflow.md" "## Goal Condition"
assert_file_contains ".claude/skills/spec/references/workflow.md" "or after"
assert_file_contains ".claude/skills/loop-patterns/SKILL.md" "goal-gated cross-phase walk"

# /dev clarifies before building, verifies externally, and supports council escalation.
assert_order ".claude/skills/dev/references/workflow.md" "## Phase 3: Clarify" "## Phase 4: Build"
assert_order ".claude/skills/dev/references/workflow.md" "## Phase 4: Build" "## Phase 5: Verify"
assert_file_contains ".claude/skills/dev/references/workflow.md" "Spec-backed mode"
assert_file_contains ".claude/skills/dev/references/workflow.md" "## Phase 6: Reflect"
assert_file_contains ".claude/skills/dev/references/workflow.md" "Wrapup"
assert_file_contains ".claude/skills/dev/references/workflow.md" "Review council triggers"
assert_file_contains ".claude/skills/dev/references/workflow.md" "@.context/specs/..."

# /dev sweep mode runs all phases autonomously, committing per phase, halting on failure.
assert_file_contains ".claude/skills/dev/references/workflow.md" "## Spec Sweep Mode"
assert_file_contains ".claude/skills/dev/references/workflow.md" "Commit at the phase boundary"
assert_file_contains ".claude/skills/dev/references/workflow.md" "Halt the sweep"
assert_file_contains ".claude/skills/dev/references/workflow.md" "Operational guardrails"
assert_file_contains ".claude/skills/dev/SKILL.md" "Spec Sweep Mode"

# Volume ceilings — long workflow prompts measurably reduce compliance.
assert_max_lines ".claude/skills/discuss/SKILL.md" 150
assert_max_lines ".claude/skills/spec/SKILL.md" 150
assert_max_lines ".claude/skills/dev/SKILL.md" 150
assert_max_lines ".claude/skills/discuss/references/phases.md" 250
assert_max_lines ".claude/skills/spec/references/workflow.md" 300
assert_max_lines ".claude/skills/dev/references/workflow.md" 350

# Implementer escalates high-risk assumptions instead of always proceeding.
assert_file_contains ".claude/agents/implementer.md" "High-risk assumptions"
assert_file_contains ".claude/agents/implementer.md" "stop and ask"

# Reviewer is briefed for coverage over filtering (severity-suppression regression trap).
assert_file_contains ".claude/agents/reviewer.md" "Report every issue you find"

########################################
# .cursor — rebuilt workflows (Cursor 2.4+ native subagents/skills)
########################################

# No references to superseded Cursor primitives (custom agents replaced by built-ins,
# the deleted delegation-first rule) in the live config.
cursor_stale=$(rg -n '/explorer|/checker|/tester|/browser-tester|dev-workflow\.mdc|\.cursorrules' .cursor || true)
[ -z "$cursor_stale" ] || fail "superseded-primitive references remain in .cursor:\n$cursor_stale"

assert_file_contains ".cursor/skills/discuss/references/phases.md" "<adlc-handoff>"
assert_file_contains ".cursor/skills/discuss/references/phases.md" "human_decisions_required:"
assert_file_contains ".cursor/skills/discuss/SKILL.md" "Triage first"
assert_file_contains ".cursor/skills/spec/SKILL.md" "No spec"
assert_file_contains ".cursor/skills/spec/SKILL.md" "Light spec"
for needle in "## Requirement Contract" "## Architecture Plan" "component:" "concerns: []"; do
  assert_file_contains ".cursor/skills/spec/references/workflow.md" "$needle"
done
assert_file_contains ".cursor/skills/spec/references/workflow.md" "Build in Parallel"
assert_file_contains ".cursor/skills/spec/references/workflow.md" "Safe Parallelization"
assert_file_contains ".cursor/skills/spec/references/workflow.md" "Implement all phases autonomously"
assert_file_contains ".cursor/skills/spec/references/workflow.md" "## Goal Condition"
assert_file_contains ".cursor/skills/spec/references/workflow.md" "or after"
assert_order ".cursor/skills/dev/references/workflow.md" "## Phase 3: Clarify" "## Phase 4: Build"
assert_order ".cursor/skills/dev/references/workflow.md" "## Phase 4: Build" "## Phase 5: Verify"
for needle in "Spec-backed mode" "## Phase 6: Reflect" "Wrapup" "Review council triggers" "## Spec Sweep Mode" "Commit at the phase boundary" "Halt the sweep" "Operational guardrails"; do
  assert_file_contains ".cursor/skills/dev/references/workflow.md" "$needle"
done
assert_file_contains ".cursor/skills/dev/references/workflow.md" "/multitask"
assert_file_contains ".cursor/skills/dev/references/workflow.md" "@.context/specs/..."
assert_file_contains ".cursor/skills/dev/SKILL.md" "Spec Sweep Mode"
assert_max_lines ".cursor/skills/discuss/SKILL.md" 150
assert_max_lines ".cursor/skills/spec/SKILL.md" 150
assert_max_lines ".cursor/skills/dev/SKILL.md" 150
assert_max_lines ".cursor/skills/discuss/references/phases.md" 250
assert_max_lines ".cursor/skills/spec/references/workflow.md" 300
assert_max_lines ".cursor/skills/dev/references/workflow.md" 350
assert_file_contains ".cursor/agents/implementer.md" "High-risk assumptions"
assert_file_contains ".cursor/agents/implementer.md" "stop and ask"
assert_file_contains ".cursor/agents/spec-reviewer.md" "Report every issue you find"

########################################
# Pi maintainer wrappers + shared conventions
########################################

# Root AGENTS.md is the file pi actually auto-loads (cwd->root walk); .pi/AGENTS.md is human/fixture only.
assert_file_contains "AGENTS.md" "Agent Team"
assert_file_contains ".pi/AGENTS.md" "Agent Team"
assert_file_contains ".pi/AGENTS.md" "scripts/sync-plugin.sh"
for skill in agent-team-discuss agent-team-spec agent-team-dev; do
  [ -f ".pi/skills/$skill/SKILL.md" ] || fail "missing pi skill: $skill"
  assert_file_contains ".pi/skills/$skill/SKILL.md" "name: $skill"
  assert_file_contains ".pi/skills/$skill/SKILL.md" "source of truth"
  # Maintainer wrappers must be /skill:-only, never model-auto-invoked (matches .claude guard).
  assert_file_contains ".pi/skills/$skill/SKILL.md" "disable-model-invocation: true"
done
assert_file_contains ".pi/skills/agent-team-spec/SKILL.md" ".context/specs/spec-[feature-name].md"
assert_file_contains ".pi/skills/agent-team-dev/SKILL.md" "Spec-backed mode"
assert_file_contains ".pi/skills/agent-team-discuss/SKILL.md" "<adlc-handoff>"

# pi package delivery: the root package.json pi manifest is what makes
# `pi install git:github.com/mike-diff/ai-coding-configs` load resources —
# without it the package install is inert.
assert_file_contains "package.json" '"pi-package"'
assert_file_contains "package.json" '"./.pi/skills"'
assert_file_contains "package.json" '"./.pi/prompts"'

# pi prompt-template aliases force-load the wrapper skills deterministically.
for t in discuss spec dev; do
  [ -f ".pi/prompts/$t.md" ] || fail "missing .pi/prompts/$t.md"
  assert_file_contains ".pi/prompts/$t.md" "agent-team-$t"
done

# pi safety extension: parity port of the Claude/Cursor hooks, shipped via the manifest.
assert_file_contains "package.json" '"./.pi/extensions/pi-guard"'
[ -f ".pi/extensions/pi-guard/index.ts" ] || fail "missing .pi/extensions/pi-guard/index.ts"
# Parity anchors — the same patterns the .claude/.cursor hooks enforce.
assert_file_contains ".pi/extensions/pi-guard/index.ts" 'git\s+reset\s+--hard'
assert_file_contains ".pi/extensions/pi-guard/index.ts" 'TRUNCATE'
assert_file_contains ".pi/extensions/pi-guard/index.ts" 'AKIA[0-9A-Z]{16}'
assert_file_contains ".pi/extensions/pi-guard/index.ts" 'ghp'

# pi agent definitions for the official subagent example extension (opt-in).
for a in explorer implementer reviewer qa; do
  [ -f ".pi/agents/$a.md" ] || fail "missing .pi/agents/$a.md"
  assert_file_contains ".pi/agents/$a.md" "name: $a"
done

# Codex skills stay explicit-invocation on the runtimes that read .agents/skills
# natively (pi, Cursor); Codex itself ignores the key and uses openai.yaml.
for skill in discuss spec dev; do
  assert_file_contains ".agents/skills/$skill/SKILL.md" "disable-model-invocation: true"
done

# Agent Plugins open-standard bundle ships the workflow skills for Cursor et al.
assert_file_contains "plugins/agent-plugin/plugin.json" "agent-plugins.org/schemas"
[ -f "plugins/agent-plugin/skills/spec/SKILL.md" ] || fail "agent-plugin missing spec skill — re-run sync-plugin.sh"
[ -f "plugins/agent-plugin/skills/discuss/SKILL.md" ] || fail "agent-plugin missing discuss skill — re-run sync-plugin.sh"
assert_file_contains "scripts/sync-plugin.sh" "plugins/agent-plugin"

# Cursor docs live at cursor.com/docs; docs.cursor.com is a 308 redirect on borrowed time.
stale_links=$(rg -n 'docs\.cursor\.com' .cursor --glob '!.logs/**' || true)
[ -z "$stale_links" ] || fail "stale docs.cursor.com links in .cursor:\n$stale_links"

# Specs default to uncommitted agent context, not committed docs.
assert_file_contains ".gitignore" ".context/"
assert_file_contains ".cursor/skills/spec/references/workflow.md" ".context/specs/spec-[feature-name].md"
assert_file_contains ".cursor/skills/dev/references/workflow.md" "@.context/specs/..."
assert_no_default_docs_specs

# Plugin parity: slop-check is official and smoke tests cannot hang indefinitely.
assert_file_contains "scripts/sync-plugin.sh" "slop-check"
assert_file_contains "tests/smoke.sh" "timeout"
assert_file_contains "tests/smoke.sh" "slop-check"
[ -f "plugins/agent-team/skills/slop-check/SKILL.md" ] || fail "plugin missing slop-check skill"

# review-patterns skill is renamed from code-review (avoids collision with the built-in /code-review).
[ -f ".claude/skills/review-patterns/SKILL.md" ] || fail "missing review-patterns skill"
[ ! -d ".claude/skills/code-review" ] || fail "code-review skill should be renamed to review-patterns"
[ ! -d "plugins/agent-team/skills/code-review" ] || fail "plugin still has stale code-review skill — re-run sync-plugin.sh"
assert_file_contains ".claude/skills/review-patterns/SKILL.md" "name: review-patterns"
assert_file_contains ".claude/agents/reviewer.md" "skills: review-patterns"

# Command skills are guarded from model auto-invocation via per-skill frontmatter.
assert_file_contains ".claude/skills/dev/SKILL.md" "disable-model-invocation: true"
assert_file_contains ".claude/skills/spec/SKILL.md" "disable-model-invocation: true"
assert_file_contains ".claude/skills/discuss/SKILL.md" "disable-model-invocation: true"

# Compact hook emits a desktop notification; post-edit-lint surfaces lint via additionalContext.
assert_file_contains ".claude/hooks/notify-compact.sh" "terminalSequence"
assert_file_contains ".claude/hooks/post-edit-lint.sh" "additionalContext"

echo "workflow-contract: ok"
