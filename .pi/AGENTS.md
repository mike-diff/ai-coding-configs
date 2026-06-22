# Agent Team Project Instructions

This repo maintains the Agent Team workflows across three product surfaces plus pi maintainer skills.

> Note: pi does NOT auto-load this nested file as context — it reads the repo-root
> `AGENTS.md` (cwd→root walk), not `.pi/AGENTS.md`. The canonical, pi-loaded copy of
> these instructions lives at the repo root `AGENTS.md`. This file is kept for human
> reference and is asserted by `tests/workflow-contract.sh`; keep it in sync with root.

## Surfaces

- Claude standalone: `.claude/`
- Claude Code plugin: `plugins/agent-team/`
- Cursor: `.cursor/`
- Pi maintainer cockpit: `.pi/`

## Source of truth rules

- Claude standalone is the source of truth for the Claude Code plugin. After changing `.claude/`, run `scripts/sync-plugin.sh` and review `plugins/agent-team/` diffs.
- Cursor is a separate runtime. When workflow semantics change, update `.cursor/` explicitly rather than assuming plugin sync covers it.
- Pi skills are maintainer/operator wrappers. They must point back to Claude/Cursor workflow files as source of truth and must not become a fourth independent workflow implementation. `.pi/` syncs nowhere automatically, so when `.claude` workflow semantics or skill frontmatter change, manually re-check the three `.pi/skills/agent-team-*` wrappers (and this file vs root `AGENTS.md`), then re-run `./tests/workflow-contract.sh`.

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
