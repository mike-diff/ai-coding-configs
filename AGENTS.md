# Agent Team Project Instructions

This repo maintains the Agent Team workflows across multiple product surfaces. This
file is the project context any agent (pi, and other tools that read `AGENTS.md`)
loads when working in this repo. (A copy also lives at `.pi/AGENTS.md` for human
reference and test fixtures; pi only auto-loads this root file.)

## Surfaces

- Claude standalone: `.claude/`
- Claude Code plugin: `plugins/agent-team/`
- Cursor: `.cursor/`
- pi maintainer cockpit: `.pi/`

## Source of truth rules

- Claude standalone (`.claude/`) is the source of truth for the Claude Code plugin. After changing `.claude/`, run `scripts/sync-plugin.sh` and review `plugins/agent-team/` diffs.
- Cursor is a separate runtime. When workflow semantics change, update `.cursor/` explicitly rather than assuming plugin sync covers it.
- pi skills (`.pi/skills/`) are maintainer/operator wrappers. They must point back to the Claude/Cursor workflow files as source of truth and must not become a fourth independent workflow implementation. `.pi/` syncs nowhere automatically, so when `.claude` workflow semantics or skill frontmatter change, manually re-check the three `.pi/skills/agent-team-*` wrappers and re-run `./tests/workflow-contract.sh`.

## pi runtime notes

- pi is single-agent: there is no team/subagent/delegate primitive and no `TaskCreate` or shared task list. Workflows that read as "spawn a team" / "review council" on the Claude surface run as sequential, single-session passes on pi.
- `/goal` and `/loop` are Claude Code commands, not pi features. A spec's "Goal Condition" block is portable copy-paste text for a Claude session, not executable on pi.
- pi has native context compaction; long sweeps do not need a custom harness.

## Workflow constraints

- Preserve the lightweight public UX: `/discuss`, `/spec`, and `/dev` remain the core flow.
- Do not add separate public ADLC commands like `/validate`, `/architect`, `/reflect`, `/review`, or `/wrapup`.
- Generated specs default to `.context/specs/spec-[feature-name].md`. `.context/` is gitignored.
- Do not save generated specs to `docs/specs/` unless the user explicitly asks to promote a spec into committed project documentation.
- Do not stage or commit generated specs by default.

## Validation

Run these after workflow changes:

```bash
./tests/workflow-contract.sh
bash -n tests/workflow-contract.sh tests/smoke.sh scripts/sync-plugin.sh .claude/hooks/*.sh .cursor/hooks/*.sh plugins/agent-team/hooks/*.sh
git diff --check
```

When plugin behavior changes, also run:

```bash
COMMAND_TIMEOUT_SECONDS=60 ./tests/smoke.sh
```

## Dirty files

- `.claude/.logs/hooks.log` is generated noise. Restore or ignore it unless explicitly requested.
- `.context/` contains generated agent state and specs. Do not commit it.
