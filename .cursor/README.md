# Cursor Configuration

This directory contains Cursor-specific configuration for AI-assisted development.

## Structure

```
.cursor/
├── hooks.json          # Lifecycle hooks configuration
├── hooks/              # Hook scripts (deterministic automation)
│   ├── auto-format.sh       # Auto-format files after edits
│   ├── post-edit-lint.sh    # Lint files after edits, feed errors to stop hook
│   ├── block-dangerous.sh   # Block destructive commands
│   ├── validate-commit.sh   # Enforce conventional commits
│   ├── redact-secrets.sh    # Block reading secret files (Agent + Tab)
│   ├── notify-compact.sh    # Notify on context compaction
│   ├── persist-session.sh   # Save session state; inject lint errors as followup
│   └── load-session.sh      # Inject session state on start
├── skills/             # Slash commands + auto-activating capabilities (agentskills.io format)
│   ├── dev/            # /dev - AI-supervised feature development
│   ├── discuss/        # /discuss - Idea exploration & validated planning
│   ├── spec/           # /spec - Feature specification generator
│   ├── issue/          # /issue - Plan from GitHub issue
│   ├── ticket/         # /ticket - Create GitHub issues via interview
│   ├── to-dos/         # /to-dos - Generate implementation tasks
│   ├── orient/         # /orient - Learn a new codebase
│   ├── skill/          # /skill - Create new skills via TDD
│   ├── ask/            # /ask - Clarification questions
│   ├── primitives/     # /primitives - Enumerate native tools
│   └── skill-creator/  # Agent Skills spec, templates, and validation script
├── agents/             # Subagents for task delegation
│   ├── explorer.md     # Codebase analysis
│   ├── implementer.md  # Code implementation
│   ├── spec-reviewer.md # Spec compliance verification
│   ├── checker.md      # Lint/typecheck
│   ├── tester.md       # Test execution
│   ├── browser-tester.md # UI verification
│   └── skill-author.md # Skill creation via TDD
├── rules/              # Project rules (auto-applied based on context)
│   ├── dev-workflow.md      # /dev workflow conventions
│   ├── coding-standards.md  # Code style and quality
│   ├── commit-conventions.md # Git commit format
│   ├── subagent-outputs.md  # Required subagent result formats
│   └── mcp-caching.md      # Cache large MCP responses
├── skills/             # Reusable capabilities
│   └── skill-creator/  # Agent Skills spec, templates, and validation script
└── README.md           # This file
```

## Hooks

Hooks are deterministic scripts that run at specific points in the agent lifecycle. Unlike rules (which the LLM *might* follow), hooks **always** execute - they provide hard guarantees.

Configuration: `.cursor/hooks.json`

### Active Hooks

| Hook | Event | Script | Purpose |
|------|-------|--------|---------|
| Auto-format | `afterFileEdit` | `auto-format.sh` | Runs the project's formatter (prettier, ruff, rustfmt, gofmt) after every file edit |
| Post-edit lint | `afterFileEdit` | `post-edit-lint.sh` | Lints the edited file (ESLint, ruff), auto-fixes where possible, accumulates unfixable errors for the stop hook |
| Block dangerous | `beforeShellExecution` | `block-dangerous.sh` | Blocks `rm -rf /`, `git push --force main`, `git reset --hard`, `DROP TABLE`, etc. |
| Validate commit | `beforeShellExecution` | `validate-commit.sh` | Rejects commit messages that don't match `type(scope): description` format |
| Redact secrets | `beforeReadFile` + `beforeTabFileRead` | `redact-secrets.sh` | Blocks `.env*`, credential files, and content containing AWS keys, GitHub tokens, private keys, Slack tokens — applied to both Agent reads and Tab completions |
| Notify compact | `preCompact` | `notify-compact.sh` | Shows context usage percentage in chat when compaction fires |
| Persist session | `stop` | `persist-session.sh` | Saves git state and session info; injects accumulated lint errors as a followup message if any exist |
| Load session | `sessionStart` | `load-session.sh` | Injects previous session state as `additional_context` when starting a new conversation |

### Hooks vs Rules

| Concern | Rule (non-deterministic) | Hook (deterministic) |
|---------|--------------------------|----------------------|
| Code formatting | Checker finds issues late in build loop | Auto-formatted on every edit |
| Lint errors | Agent may not notice without feedback | Auto-fixed on every edit; remainder injected as followup at stop |
| Dangerous commands | "Be careful" instructions | Denied before execution |
| Commit format | Convention sometimes ignored | Validated and rejected if wrong |
| Secret exposure | Trust + .cursorignore | Fail-closed content scan (Agent reads + Tab completions) |
| Context compaction | Agent continues unaware | User notified with usage % |
| Session persistence | LLM remembers to save | Guaranteed on every stop |

### Debugging Hooks

If hooks aren't working as expected:
1. Open Output channels in Cursor and select "Hooks"
2. Check that scripts are executable: `chmod +x .cursor/hooks/*.sh`
3. Verify `hooks.json` is valid JSON
4. Restart Cursor after adding/changing hooks

## Usage

### Skills as Slash Commands

All workflows are implemented as Agent Skills in `.cursor/skills/`. Type `/` in Agent chat to invoke any of them:

```
/discuss What if we added a caching layer?
/spec Add user authentication with JWT tokens
/dev Add authentication middleware
/issue 42
/ticket Add dark mode toggle
/to-dos Refactor the auth module
/orient
/skill Create a skill for React Query v5 patterns
```

Each skill is a directory with `SKILL.md` (overview) and `references/workflow.md` (full instructions) following the [agentskills.io](https://agentskills.io) specification. Full workflow detail for each is in the skill's `references/` directory.

### Subagents

Subagents are specialized agents that handle specific tasks:

| Agent | Purpose | Invocation |
|-------|---------|------------|
| explorer | Codebase analysis | `/explorer [task]` |
| implementer | Code changes | `/implementer [task]` |
| spec-reviewer | Spec compliance | `/spec-reviewer [task]` |
| checker | Lint/typecheck | `/checker` |
| tester | Run tests | `/tester` |
| browser-tester | UI verification | `/browser-tester [url]` |
| skill-author | Skill creation via TDD | Spawned by `/skill` |

**Note:** Subagents require Cursor nightly. To switch:
1. Open Cursor Settings (Cmd+Shift+J)
2. Select "Beta"
3. Set update channel to "Nightly"
4. Restart Cursor

### Rules

Rules auto-apply based on file patterns:

- `dev-workflow.md` - Active during /dev command
- `coding-standards.md` - Active for code files (*.ts, *.py, etc.)
- `commit-conventions.md` - Active for git operations
- `subagent-outputs.md` - Active for subagent files
- `mcp-caching.md` - Always active, caches large MCP responses

### Skills

Skills provide specialized knowledge that auto-activates based on description matching.

| Skill | When it activates |
|-------|------------------|
| `skill-creator` | Creating or editing skills, writing SKILL.md files, validating skill structure |

## MCP Integration

This workflow is designed to work with:

- **context7** - Library documentation lookups
- **sequential-thinking** - Complex reasoning and planning
- **browser** (playwright/venom/chrome) - UI testing

Configure MCPs in `.cursor/mcp.json` or `~/.cursor/mcp.json`.

## Context Management

The workflow uses a `.context/` directory for dynamic context management:

```
.context/
├── mcp-cache/           # Cached MCP responses (context7 docs, browser snapshots)
│   ├── context7-query-[topic]-[ts].md
│   └── browser-snapshot-[page]-[ts].md
└── session/             # Session state for recovery after compaction
    └── dev-state.md     # Current /dev session state (auto-managed by hooks)
```

**Purpose:**
- **MCP caching** - Large MCP responses are saved to files instead of bloating the context window
- **Session persistence** - The `persist-session.sh` hook auto-saves state on every agent stop; `load-session.sh` auto-injects it on session start

### Required: Add to .gitignore

The `.context/` directory contains ephemeral session data and should be gitignored:

```bash
# Add to your project's .gitignore
echo ".context/" >> .gitignore
```

Or add manually:
```gitignore
# Cursor AI context management (ephemeral)
.context/
```

**Why gitignore?**
- Contains session-specific data, not project code
- MCP cache files can be large
- Session state is only relevant during active development
- Prevents accidental commits of temporary AI context

## Customization

### Adding Project-Specific Rules

Create `.cursor/rules/your-rule.md`:

```markdown
---
description: "Your rule description"
globs:
  - "src/**/*.ts"
alwaysApply: false
---

# Your Rule Title

[Rule content...]
```

### Creating Custom Skills (Slash Commands)

Create `.cursor/skills/your-skill/SKILL.md`:

```markdown
---
name: your-skill
description: "What it does and when to use it. Include trigger keywords."
argument-hint: <expected input>
disable-model-invocation: true
---

# Your Skill Title

[Skill instructions using $ARGUMENTS for input...]
```

### Creating Custom Subagents

Create `.cursor/agents/your-agent.md`:

```markdown
---
name: your-agent
description: "When to use this agent"
model: inherit
readonly: false
---

# Your Agent - Specialty

[Agent instructions...]
```

### Adding Custom Hooks

Add entries to `.cursor/hooks.json` and create scripts in `.cursor/hooks/`:

```json
{
  "version": 1,
  "hooks": {
    "afterFileEdit": [
      { "command": ".cursor/hooks/your-hook.sh" }
    ]
  }
}
```

Hook scripts receive JSON via stdin and return JSON via stdout. Exit code `0` allows the action, exit code `2` blocks it. See the [Cursor hooks documentation](https://docs.cursor.com/agent/hooks) for full details.
