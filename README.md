# AI Coding Configurations

An opinionated collection of **Cursor** and **Claude Code** configurations for AI-assisted development, with project-local **pi** maintainer skills for editing the workflows safely. Drop the relevant folder into any project to get structured workflows, specialized subagents, safety hooks, and reusable skills - all working together out of the box.

---

## Install

Two paths, pick one:

### Option A — Plugin (recommended for sharing)

```bash
/plugin marketplace add mike-diff/ai-coding-configs
/plugin install agent-team@mike-diff
```

Commands surface as `/agent-team:discuss`, `/agent-team:dev`, etc.
See [plugin README](./plugins/agent-team/README.md) for details.

### Option B — Standalone (drop-in, unprefixed commands)

```bash
git clone https://github.com/mike-diff/ai-coding-configs.git
cp -r ai-coding-configs/.claude/ /path/to/your/project/
```

Commands surface as `/discuss`, `/dev`, etc.
See [.claude/README.md](.claude/README.md) for details.

### Working on this repo with pi

This repository includes project-local pi maintainer skills:

```bash
/skill:agent-team-discuss
/skill:agent-team-spec
/skill:agent-team-dev
```

These are not another product surface. They are operator workflows for safely editing and validating the Agent Team configs across `.claude/`, `plugins/agent-team/` and `.cursor/`.

> **Note:** pi v0.79.0+ prompts for project trust before loading `.pi/skills/`. Approve the prompt (or run with `--approve`, or manage saved decisions via `/trust`) for these skills to appear.

---

## What's Included

| Tool | Config Folder |
|------|--------------|
| Claude Code | `.claude/` |
| Cursor | `.cursor/` |

Both share the same core philosophy and command set, with each adapted to their platform's native capabilities.

---

## How It Works

Each configuration gives your AI assistant a set of **commands** to run, **subagents** to delegate work to, **rules** to follow, **hooks** to enforce automatically, and **skills** to draw on as reference.

### Commands

Commands are slash commands you run to kick off a workflow. Both tools share the same set, implemented as Agent Skills following the [agentskills.io](https://agentskills.io) specification:

| Command | What it does |
|---------|-------------|
| `/discuss` | Think through an idea before building. Spawns background research, interviews you, validates the plan, and emits an ADLC handoff. |
| `/spec` | Turn a feature description into a spec-backed contract: requirement validation, architecture planning, architecture validation, and phased tasks. |
| `/dev` | Build a feature end-to-end with a coordinated subagent team, then reflect, review/QA, commit or report PR-ready, and wrap up learnings. |
| `/to-dos` | Break down a feature into detailed, dependency-tracked tasks. |
| `/issue` | Fetch a GitHub issue, explore the codebase, produce an implementation plan. |
| `/ticket` | Create a well-structured GitHub issue through a guided interview. |
| `/orient` | Map the tech stack, architecture, and patterns of an unfamiliar codebase. |
| `/ask` | Ask clarifying questions before proceeding with work. |
| `/skill` | Create a new skill using TDD - baseline test, write content, validate against the agentskills.io spec. |
| `/slop-check` | Run tool-driven code quality analysis and conservative cleanup judgment. |
| `/primitives` | List every native tool and capability available in the current session. |
| `/goal-or-loop` | Decide whether a task should run as `/goal`, `/loop`, both in sequence, or neither, and emit a copy-paste-ready command block. |

---

### Subagents

Subagents are specialized agents that the orchestrator delegates work to. Each has a narrow focus.

**Claude Code** (`.claude/agents/`):

| Agent | Role |
|-------|------|
| `explorer` | Read-only codebase analysis |
| `implementer` | Writes and modifies code |
| `reviewer` | Spec compliance and code quality |
| `qa` | Runs lint, typecheck, and tests |
| `skill-author` | Creates skills using TDD |

**Cursor** (`.cursor/agents/`):

| Agent | Role |
|-------|------|
| `explorer` | Codebase analysis |
| `implementer` | Code implementation |
| `spec-reviewer` | Spec compliance verification |
| `checker` | Lint and typecheck |
| `tester` | Test execution |
| `browser-tester` | UI verification |
| `skill-author` | Skill creation via TDD |

---

### Rules

Rules are guidelines loaded automatically by the AI at the start of every session. They can't be ignored the way inline instructions sometimes are.

**Claude Code** (`.claude/rules/`):

| Rule | What it covers |
|------|---------------|
| `coding-standards` | Code quality, naming, structure, and prompt design (calibrated language, altitude, lean skills) |
| `mcp-caching` | Cache large MCP responses to `.context/` to avoid bloating context windows |

**Cursor** (`.cursor/rules/`):

| Rule | What it covers |
|------|---------------|
| `coding-standards` | Code quality, naming, structure |
| `dev-workflow` | Orchestration conventions for `/dev` |
| `commit-conventions` | Conventional Commits format |
| `subagent-outputs` | Required result block formats for subagents |
| `mcp-caching` | Cache large MCP responses to `.context/` |

---

### Hooks

Hooks are scripts that run automatically at specific points in the workflow - before or after tool use, on session start, on stop. Unlike rules (which the AI *should* follow), hooks *always* run regardless of what the AI decides.

**Claude Code** (`.claude/hooks/`):

| Hook | When it runs | What it does |
|------|-------------|-------------|
| `block-dangerous.sh` | Before shell commands | Blocks `rm -rf /`, force push to main, hard reset, `DROP TABLE`, `DELETE` without `WHERE` |
| `validate-commit.sh` | Before shell commands | Rejects commits that don't match `type(scope): description` |
| `redact-secrets.sh` | Before file reads | Blocks `.env*`, credential files, and content with AWS keys, GitHub tokens, private keys |
| `post-edit-lint.sh` | After every file edit | Auto-lints the edited file (ESLint, ruff) |
| `teammate-idle.sh` | When a teammate goes idle or stops | Requires a `<*-result>` block before the agent can stop |
| `task-completed.sh` | On task completion | Requires a `<*-result>` block before the task can be marked done |
| `notify-compact.sh` | Before context compaction | Shows context usage %; logs which rules and skills survive compaction |
| `session-start.sh` | On session start | Logs session digest; validates all hook scripts are executable |
| `permission-denied.sh` | On permission denied | Logs the blocked tool and reason to `.claude/.logs/permission-denied.log` |
| `file-changed.sh` | When a file changes | Logs file path and change type to `.claude/.logs/hooks.log` |
| `cwd-changed.sh` | When working directory changes | Logs new cwd to `.claude/.logs/hooks.log` |
| `task-created.sh` | When a task is created | Logs task id, teammate, and subject to `.claude/.logs/tasks.log` |
| `stop-failure.sh` | On API-error termination | Logs failure mode and raw payload to `.claude/.logs/stop-failures.log` |

**Cursor** (`.cursor/hooks/`):

| Hook | When it runs | What it does |
|------|-------------|-------------|
| `block-dangerous.sh` | Before shell execution | Same dangerous command blocking as Claude Code |
| `validate-commit.sh` | Before shell execution | Same conventional commit enforcement |
| `redact-secrets.sh` | Before file reads (Agent + Tab) | Same secret detection and blocking, applied to both Agent reads and Tab completions |
| `auto-format.sh` | After every file edit | Runs the project's formatter (Prettier, Ruff, rustfmt, gofmt) |
| `post-edit-lint.sh` | After every file edit | Lints the edited file, auto-fixes where possible, accumulates unfixable errors for the stop hook |
| `notify-compact.sh` | Before context compaction | Shows context usage percentage when compaction fires |
| `persist-session.sh` | On agent stop | Saves session state; injects accumulated lint errors as a followup message if any exist |
| `load-session.sh` | On session start | Injects previous session state as context |
| `session-end-log.sh` | On session end | Logs session completion metadata for auditability |
| `subagent-start-log.sh` | On subagent start | Logs multi-agent lifecycle start events |
| `subagent-stop-log.sh` | On subagent stop | Logs multi-agent lifecycle completion events |
| `post-tool-failure-log.sh` | On tool failure | Logs failed tool execution details for debugging |

---

### Skills

Skills are reference documents the AI draws on automatically based on context. They're not commands you invoke - they activate when relevant.

**Claude Code workflow skills** (`.claude/skills/`) - these power the commands above:

| Skill | Purpose |
|-------|---------|
| `team-orchestration` | Orchestration patterns for the lead agent |
| `review-patterns` | Review patterns for the reviewer agent |
| `testing-patterns` | QA patterns for the QA agent |
| `loop-patterns` | Recommended `/loop` cadences for each agent (explorer, implementer, reviewer, qa, skill-author) |
| `goal-or-loop` | Decide between `/goal`, `/loop`, both, or neither for a task, and emit a high-craft command block |
| `dev`, `discuss`, `spec`, `to-dos`, `issue`, `ticket`, `skill`, `slop-check`, `orient`, `ask`, `primitives` | Full workflow instructions for each command |

**Cursor skills** (`.cursor/skills/`) - all commands and domain skills:

| Skill | Type | When it activates |
|-------|------|------------------|
| `dev`, `discuss`, `spec`, `to-dos`, `issue`, `ticket`, `orient`, `ask`, `skill`, `primitives` | Commands (`disable-model-invocation: true`) | When you type `/name` in Agent chat |
| `skill-creator` | Domain skill | Creating or editing skills, writing SKILL.md files |
| `worktree-ops`, `best-of-n-ops`, `debug-ops`, `canvas-ops` | Operational skills | When running Cursor 3.x workflows for isolation, parallel attempts, debugging, and analytical outputs |

---

## A Typical Workflow

```
/discuss "add a caching layer"
  → Research + interview → validated plan + ADLC handoff

/spec "add Redis caching for API responses"
  → Requirement contract → validate → architecture plan → validate → phased task doc
  → Each phase ships a transcript-verifiable Goal Condition you can paste into /goal

/dev @.context/specs/spec-caching.md
  → Spec sweep: runs every phase end-to-end, committing at each phase boundary (autonomous)
  → Or one phase at a time: /dev "Implement Phase 1" @.context/specs/spec-caching.md
  → Preflight spec-backed mode → Explorer maps codebase → clarify → team up
  → Implementer builds → reflect → review council when risk triggers → QA runs tests
  → commit or PR-ready → wrapup captures lessons, assumptions, follow-ups, and ship handoff
```

Specs are local planning artifacts by default. They save under `.context/specs/`, which is gitignored, and should only be promoted into committed documentation when explicitly requested.

---

## Setup

### Claude Code

1. Copy `.claude/` into your project root.
2. Enable Agent Teams by adding this to your **user-level** `~/.claude/settings.json` (not the project-level one):
   ```json
   {
     "env": {
       "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
     },
     "teammateMode": "auto"
   }
   ```
   Set `teammateMode` to `tmux` for each agent in its own pane (requires tmux), or `in-process` to keep everything in one terminal. You can also pass it as a flag: `claude --teammate-mode tmux`.
3. Run `/orient` to map your codebase, then start with any command.

> The env var must live in user-level settings because Claude Code validates project hooks before applying project-level env vars - putting it in the project file can silently prevent slash commands from loading.

**Recent Claude Code features that pair well with this config** (v2.1.x):
- The command skills (`/dev`, `/discuss`, `/spec`, etc.) set `disable-model-invocation: true` in their `SKILL.md` frontmatter, so the model won't auto-launch them mid-conversation — you still invoke them with `/`. (This travels with the skill, so plugin installs keep the guard too.)
- If autonomous runs (like `/dev` spec sweep) hit the auto-mode classifier, tune `autoMode` rules — including `autoMode.hard_deny` — in your user settings.
- `/goal` sets a completion condition Claude works toward across turns — a lightweight native complement to the multi-phase `/dev` sweep. `/spec` now emits a ready-to-paste `## Goal Condition` per phase (transcript-verifiable commands + outputs, scope constraint, turn cap), so you can drive a single phase solo with `/goal "<condition>"` instead of the `/dev` team sweep. Don't stack both on the same phase.

### Cursor

1. Copy `.cursor/` into your project root.
2. Make hook scripts executable: `chmod +x .cursor/hooks/*.sh`
3. Run `/orient` to map your codebase, then start with any skill.

Useful Cursor 3.x workflows:
- `/worktree` for isolated implementation branches
- `/best-of-n` for parallel model attempts in isolated worktrees
- `/debug` for hypothesis-driven root-cause analysis

---

## Context Directory

Both configurations write ephemeral data to a `.context/` directory in your project:

```
.context/
├── mcp-cache/     # Cached MCP responses (avoids re-fetching large docs)
└── session/       # Session state for recovery after context resets
```

Add `.context/` to your project's `.gitignore` - it's session-specific and shouldn't be committed.

```bash
echo ".context/" >> .gitignore
```
