# Agent Team Project Instructions

This repo maintains the Agent Team workflows across multiple product surfaces. This
file is the project context any agent (pi, and other tools that read `AGENTS.md`)
loads when working in this repo. (A copy also lives at `.pi/AGENTS.md` for human
reference and test fixtures; pi only auto-loads this root file.)

## Surfaces

- Claude standalone: `.claude/`
- Claude Code plugin: `plugins/agent-team/`
- Agent Plugins open-standard bundle (Cursor et al.): `plugins/agent-plugin/`
- Cursor: `.cursor/`
- Codex personal workflows: `.agents/skills/`
- pi maintainer cockpit: `.pi/` (shipped as a pi package via the `pi` manifest in `package.json`)

## Source of truth rules

- Claude standalone (`.claude/`) is the source of truth for both generated distributions. After changing `.claude/`, run `scripts/sync-plugin.sh` and review the `plugins/agent-team/` diffs (namespaced commands, path rewrites) and the `plugins/agent-plugin/` diffs (Agent Plugins open standard, verbatim skills).
- Cursor is a separate runtime. When workflow semantics change, update `.cursor/` explicitly rather than assuming plugin sync covers it.
- Codex is a separate native runtime. `.agents/skills/` is the repo-tracked source for `$discuss`, `$spec`, and `$dev`; `scripts/install-codex.sh` links those skills into the current user's global `~/.agents/skills/` discovery path. Do not copy Claude-only team or task primitives into the Codex skills. The skills carry `disable-model-invocation: true`: a no-op on Codex (invocation policy lives in `agents/openai.yaml`), but it keeps pi and Cursor — which read `.agents/skills/` natively — from auto-triggering them.
- pi skills (`.pi/skills/`) are maintainer/operator wrappers. They point back to the `.claude/` workflow files — the canonical workflow semantics — as their only source of truth, and must not become a fourth independent workflow implementation. (`.cursor/` and `.agents/` are runtime adaptations of those semantics, not co-equal sources; pointing wrappers at two sources is how they drift.) `.pi/` syncs nowhere automatically, so when `.claude` workflow semantics or skill frontmatter change, manually re-check the three `.pi/skills/agent-team-*` wrappers and re-run `./tests/workflow-contract.sh`. The root `package.json` `pi` manifest is what makes `pi install git:github.com/mike-diff/ai-coding-configs` deliver `.pi/skills/` and `.pi/prompts/` — update it when adding pi resources, or the package install goes inert.

## pi runtime notes

- pi is single-agent at its core: no built-in subagent primitive and no `TaskCreate` or shared task list. The official `subagent` and `todo` example extensions add those when installed; `.pi/agents/*.md` ships definitions for the subagent extension (project scope is opt-in via its `agentScope` setting). Workflow steps that read as "background research subagents", "fresh-context reviewer", or "parallel review lenses" on the Claude surface run as sequential, single-session passes on pi unless that extension is active.
- `/goal` and `/loop` are Claude Code commands, not pi features (Cursor is rolling out a native CLI `/goal`, gated as of 2026-08). A spec's "Goal Condition" block is portable copy-paste text, not executable on pi.
- pi has native context compaction; long sweeps do not need a custom harness.
- `.pi/extensions/pi-guard/` is the pi port of the Claude/Cursor safety hooks (dangerous shell commands, commit-message format, secret-bearing reads), shipped through the package manifest. Keep its patterns in lockstep with `.claude/hooks/` and `.cursor/hooks/`; the contract test asserts the parity anchors.

## Workflow constraints

- Preserve the lightweight public UX: `/discuss`, `/spec`, and `/dev` remain the core flow.
- On Codex, preserve the equivalent explicit UX: `$discuss`, `$spec`, and `$dev`.
- Do not add separate public ADLC commands like `/validate`, `/architect`, `/reflect`, `/review`, or `/wrapup`.
- Generated specs default to `.context/specs/spec-[feature-name].md`. `.context/` is gitignored.
- Do not save generated specs to `docs/specs/` unless the user explicitly asks to promote a spec into committed project documentation.
- Do not stage or commit generated specs by default.

## Validation

Run these after workflow changes:

```bash
./tests/workflow-contract.sh
./tests/codex-workflow-contract.sh
./tests/hooks-contract.sh
bash -n tests/workflow-contract.sh tests/codex-workflow-contract.sh tests/smoke.sh scripts/sync-plugin.sh scripts/install-codex.sh .claude/hooks/*.sh .cursor/hooks/*.sh plugins/agent-team/hooks/*.sh
git diff --check
```

When plugin behavior changes, also run:

```bash
COMMAND_TIMEOUT_SECONDS=60 ./tests/smoke.sh
```

## Dirty files

- `.claude/.logs/hooks.log` is generated noise. Restore or ignore it unless explicitly requested.
- `.context/` contains generated agent state and specs. Do not commit it.
