# Claude Code Configuration

Drop `.claude/` into any project to get ten workflow commands, five specialized subagents, safety hooks, and reusable skills - all working together.

```
.claude/
├── settings.json
├── skills/                           # Auto-activating capabilities
├── agents/                           # Subagents for delegation
├── rules/                            # Standards auto-loaded every session
└── hooks/                            # Deterministic safety and quality gates
```

---

## Skills

Skills live in `.claude/skills/`. Each skill has a `SKILL.md` that loads automatically when its description semantically matches what you're working on. No manual activation needed.

### Workflow Skills

These power the slash commands. Each maps to a command of the same name.

| Skill | Command | What it does |
|-------|---------|-------------|
| `discuss` | `/discuss` | Explore an idea through conversation and parallel research. Produces a validated plan with a blind spot check. |
| `spec` | `/spec` | Turn a feature description into a phased implementation spec. |
| `dev` | `/dev` | Build a feature with a coordinated subagent team. |
| `to-dos` | `/to-dos` | Break a feature into detailed, dependency-tracked tasks using `TaskCreate`. |
| `issue` | `/issue` | Fetch a GitHub issue, explore the codebase, produce an implementation plan. |
| `ticket` | `/ticket` | Create a well-structured GitHub issue through a guided interview. |
| `orient` | `/orient` | Map the tech stack, architecture, and patterns of a codebase. |
| `ask` | `/ask` | Ask clarifying questions before proceeding. |
| `skill` | `/skill` | Create a new skill using TDD - baseline test, then write content. Includes spec reference, starter templates, and a validation script. |
| `primitives` | `/primitives` | Enumerate every native tool and capability available in the current session. |

### Semantic Skills

These activate automatically based on context - no command needed.

| Skill | Activates when... |
|-------|------------------|
| `team-orchestration` | Spawning or coordinating agent teams |
| `code-review` | Reviewing code, verifying implementation against spec |
| `testing-patterns` | Running lint, typecheck, or tests; writing new tests |

---

## Agents

Agents live in `.claude/agents/`. The orchestrator (lead) spawns these via Agent Teams to handle focused work.

| Agent | Role | Mode |
|-------|------|------|
| `explorer` | Read-only codebase analysis | async |
| `implementer` | Writes and modifies code | resumable |
| `reviewer` | Spec compliance and code quality | - |
| `qa` | Runs lint, typecheck, and tests | - |
| `skill-author` | Creates skills using TDD | - |

Requires Agent Teams: set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in your **user-level** `~/.claude/settings.json` env block - not in the project `settings.json`. See setup note below.

---

## Rules

Rules live in `.claude/rules/`. Claude Code loads these automatically at every session start for all agents and the lead.

| Rule | What it covers |
|------|---------------|
| `coding-standards` | Code quality, naming conventions, structured output requirements |
| `mcp-caching` | Cache large MCP responses to `.context/mcp-cache/` to avoid bloating context windows |

---

## Hooks

Hooks live in `.claude/hooks/` and are configured in `settings.json`. Unlike rules (which the agent *should* follow), hooks *always* run - they provide hard guarantees via exit code `2` to block with feedback.

| Hook | Trigger | What it does |
|------|---------|-------------|
| `block-dangerous.sh` | `PreToolUse: Bash` | Blocks `rm -rf /`, force push to main, hard reset, `DROP TABLE`, `DELETE` without `WHERE` |
| `validate-commit.sh` | `PreToolUse: Bash` | Rejects commit messages that don't match `type(scope): description` |
| `redact-secrets.sh` | `PreToolUse: Read` | Blocks `.env*`, credential files, and content containing AWS keys, GitHub tokens, private keys |
| `post-edit-lint.sh` | `PostToolUse: Write\|Edit` | Auto-lints the edited file after every write or edit |
| `teammate-idle.sh` | `TeammateIdle` + agent `Stop` | Requires a `<*-result>` block before a teammate can go idle or stop |
| `task-completed.sh` | `TaskCompleted` | Requires a `<*-result>` block before a task can be marked done |

All hooks use `$CLAUDE_PROJECT_DIR` (injected by Claude Code) to resolve paths reliably.

---

## How the Commands Work Together

```
/discuss "idea"
  → Lead (normal mode) interviews you
  → Scout + Researcher teammates do parallel research
  → Challenger stress-tests the plan
  → Blind Spot check runs automatically
  → Validated plan (optionally deepens into a spec)

/spec "feature"
  → CLARIFY → SPECIFY (approval gate) → PLAN → TASK
  → Saves to docs/specs/spec-[name].md

/dev "feature" @docs/specs/spec-[name].md
  → Lead (delegate mode) spawns team
  → Explorer maps codebase
  → Implementer builds → Reviewer checks → QA tests
  → Build loop repeats up to 5x before escalating
  → Hooks enforce quality at every step
```

---

## Setup

### Agent Teams

`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` must be set in your **user-level** `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Set `teammateMode` in `settings.json` to control how agents render (`auto`, `tmux`, or `in-process`), or pass it as a flag: `claude --teammate-mode tmux`. Use `tmux` for each agent in its own pane (requires tmux), or `in-process` to keep everything in one terminal.

Do not set it in the project `settings.json`. Claude Code validates project hooks before applying project-level env vars - if the env var is in the same file as the `TeammateIdle` and `TaskCompleted` hooks, those hooks can silently prevent project slash commands from loading.

### Context Directory

The `mcp-caching` rule and Cursor's session hooks write to `.context/` in your project root. Add it to your `.gitignore`:

```bash
echo ".context/" >> .gitignore
```

## User-level setup

Two settings in this config live in your **user-level** `~/.claude/settings.json`, not the project-level one in this repo:

1. **`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`** — required for Agent Teams (see existing notes).
2. **`autoMemoryDirectory` / `autoMemoryEnabled`** — Claude Code's policy rejects these keys from project settings to prevent shared projects redirecting memory writes. Copy this into `~/.claude/settings.json`:

    ```json
    {
      "autoMemoryEnabled": true,
      "autoMemoryDirectory": "~/.claude/projects/<your-project>/memory"
    }
    ```

    Replace `<your-project>` with a descriptive name. Claude Code will auto-create `MEMORY.md` and topic files there.

**Minimum Claude Code version:** 2.1.108 (released 2026-04-14). Verify with `claude --version`. Older versions will silently ignore `ENABLE_PROMPT_CACHING_1H` and may reject other features used here.
