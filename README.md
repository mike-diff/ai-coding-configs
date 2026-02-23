# AI Coding Configurations

An opinionated collection of **Cursor** and **Claude Code** configurations for AI-assisted development. Drop the relevant folder into any project to get structured workflows, specialized subagents, safety hooks, and reusable skills — all working together out of the box.

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

Commands are slash commands you run to kick off a workflow. Both tools share the same set — implemented as Agent Skills following the [agentskills.io](https://agentskills.io) specification:

| Command | What it does |
|---------|-------------|
| `/discuss` | Think through an idea before building. Spawns background research, interviews you, validates the plan. |
| `/spec` | Turn a feature description into a phased implementation spec ready to hand to `/dev`. |
| `/dev` | Build a feature end-to-end with a coordinated subagent team. |
| `/to-dos` | Break down a feature into detailed, dependency-tracked tasks. |
| `/issue` | Fetch a GitHub issue, explore the codebase, produce an implementation plan. |
| `/ticket` | Create a well-structured GitHub issue through a guided interview. |
| `/orient` | Map the tech stack, architecture, and patterns of an unfamiliar codebase. |
| `/ask` | Ask clarifying questions before proceeding with work. |
| `/skill` | Create a new skill using TDD — baseline test, write content, validate against the agentskills.io spec. |
| `/primitives` | List every native tool and capability available in the current session. |

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
| `coding-standards` | Code quality, naming, structure |
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

Hooks are scripts that run automatically at specific points in the workflow — before or after tool use, on session start, on stop. Unlike rules (which the AI *should* follow), hooks *always* run regardless of what the AI decides.

**Claude Code** (`.claude/hooks/`):

| Hook | When it runs | What it does |
|------|-------------|-------------|
| `block-dangerous.sh` | Before shell commands | Blocks `rm -rf /`, force push to main, hard reset, `DROP TABLE`, `DELETE` without `WHERE` |
| `validate-commit.sh` | Before shell commands | Rejects commits that don't match `type(scope): description` |
| `redact-secrets.sh` | Before file reads | Blocks `.env*`, credential files, and content with AWS keys, GitHub tokens, private keys |
| `post-edit-lint.sh` | After every file edit | Auto-lints the edited file (ESLint, ruff) |
| `teammate-idle.sh` | When a teammate goes idle or stops | Requires a `<*-result>` block before the agent can stop |
| `task-completed.sh` | On task completion | Requires a `<*-result>` block before the task can be marked done |

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

---

### Skills

Skills are reference documents the AI draws on automatically based on context. They're not commands you invoke — they activate when relevant.

**Claude Code workflow skills** (`.claude/skills/`) — these power the commands above:

| Skill | Purpose |
|-------|---------|
| `team-orchestration` | Orchestration patterns for the lead agent |
| `code-review` | Review patterns for the reviewer agent |
| `testing-patterns` | QA patterns for the QA agent |
| `dev`, `discuss`, `spec`, `to-dos`, `issue`, `ticket`, `skill`, `orient`, `ask`, `primitives` | Full workflow instructions for each command |

**Cursor skills** (`.cursor/skills/`) — all commands and domain skills:

| Skill | Type | When it activates |
|-------|------|------------------|
| `dev`, `discuss`, `spec`, `to-dos`, `issue`, `ticket`, `orient`, `ask`, `skill`, `primitives` | Commands (`disable-model-invocation: true`) | When you type `/name` in Agent chat |
| `skill-creator` | Domain skill | Creating or editing skills, writing SKILL.md files |

---

## A Typical Workflow

```
/discuss "add a caching layer"
  → Research + interview → validated plan

/spec "add Redis caching for API responses"
  → Clarify → specify → plan → phased task doc

/dev "Implement Phase 1" @docs/specs/spec-caching.md
  → Explorer maps codebase → Implementer builds
  → Reviewer checks spec compliance → QA runs tests
  → Hooks enforce quality at every step
```

---

## Setup

### Claude Code

1. Copy `.claude/` into your project root.
2. Enable Agent Teams by adding this to your **user-level** `~/.claude/settings.json` (not the project-level one):
   ```json
   {
     "env": {
       "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
     }
   }
   ```
3. Start Claude with `claude --teammate-mode tmux` for team mode.
4. Run `/orient` to map your codebase, then start with any command.

> The env var must live in user-level settings because Claude Code validates project hooks before applying project-level env vars — putting it in the project file can silently prevent slash commands from loading.

### Cursor

1. Copy `.cursor/` into your project root.
2. Make hook scripts executable: `chmod +x .cursor/hooks/*.sh`
3. Run `/orient` to map your codebase, then start with any skill.

---

## Context Directory

Both configurations write ephemeral data to a `.context/` directory in your project:

```
.context/
├── mcp-cache/     # Cached MCP responses (avoids re-fetching large docs)
└── session/       # Session state for recovery after context resets
```

Add `.context/` to your project's `.gitignore` — it's session-specific and shouldn't be committed.

```bash
echo ".context/" >> .gitignore
```
