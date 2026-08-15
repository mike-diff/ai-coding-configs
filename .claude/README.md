# Claude Code Configuration

Drop `.claude/` into any project to get lightweight workflow commands, five specialized subagents, safety hooks, and reusable skills - all working together.

```
.claude/
├── settings.json
├── statusline.sh                     # Custom status line (model, cost, context)
├── skills/                           # Auto-activating capabilities
├── agents/                           # Subagents for delegation
├── rules/                            # Standards auto-loaded every session
└── hooks/                            # Deterministic safety and quality gates
```

---

## Skills

Skills live in `.claude/skills/`. Workflow skills are explicit slash commands (they set `disable-model-invocation`, so Claude only runs them when you type `/name`); semantic skills auto-activate when their description matches what you're working on.

### Workflow Skills

These power the slash commands. Each maps to a command of the same name.

| Skill | Command | What it does |
|-------|---------|-------------|
| `discuss` | `/discuss` | Explore an idea through conversation and background research subagents. One adversarial validation pass, then a validated plan with an ADLC handoff. |
| `spec` | `/spec` | Right-sized specs: triage (no spec / light / full), one approval gate, self-contained phases with transcript-verifiable goal conditions. |
| `dev` | `/dev` | Implement directly by default, delegate when work decomposes; external verify gate (checks + fresh-context review), then commit or PR-ready and wrapup. |
| `to-dos` | `/to-dos` | Break a feature into detailed, dependency-tracked tasks using `TaskCreate`. |
| `issue` | `/issue` | Fetch a GitHub issue, explore the codebase, produce an implementation plan. |
| `ticket` | `/ticket` | Create a well-structured GitHub issue through a guided interview. |
| `orient` | `/orient` | Map the tech stack, architecture, and patterns of a codebase. |
| `ask` | `/ask` | Ask clarifying questions before proceeding. |
| `skill` | `/skill` | Create a new skill using TDD - baseline test, then write content. Includes spec reference, starter templates, and a validation script. |
| `slop-check` | `/slop-check` | Run tool-driven code quality analysis and conservative cleanup judgment. |
| `primitives` | `/primitives` | Enumerate every native tool and capability available in the current session. |

### Semantic Skills

These activate automatically based on context - no command needed.

| Skill | Activates when... |
|-------|------------------|
| `team-orchestration` | Deciding when to delegate, subagents vs Workflow, verification topology |
| `review-patterns` | Reviewing code, verifying implementation against spec |
| `testing-patterns` | Running lint, typecheck, or tests; writing tests |
| `goal-or-loop` | Choosing between `/goal` and `/loop` for unattended work |
| `loop-patterns` | Asking about `/loop`, polling, watch-mode, periodic tasks |

---

## Agents

Agents live in `.claude/agents/`. The lead spawns these as subagents (Agent tool) for focused work — fresh-context review, parallel implementation tracks, wide exploration. Every session has an implicit team; no env flag is needed.

| Agent | Role |
|-------|------|
| `explorer` | Read-only codebase analysis |
| `implementer` | Writes and modifies code |
| `reviewer` | Coverage-first spec compliance and code quality review |
| `qa` | Runs lint, typecheck, and tests |
| `skill-author` | Creates skills using TDD |

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
| `session-start.sh` | `SessionStart` | Logs session opens; verifies hook scripts are executable |
| `block-dangerous.sh` | `PreToolUse: Bash` | Blocks `rm -rf /`, force push to main, hard reset, `DROP TABLE`, `DELETE` without `WHERE` |
| `validate-commit.sh` | `PreToolUse: Bash` | Rejects commit messages that don't match `type(scope): description` |
| `redact-secrets.sh` | `PreToolUse: Read` | Blocks `.env*`, credential files, and content containing AWS keys, GitHub tokens, private keys |
| `post-edit-lint.sh` | `PostToolUse: Write\|Edit` | Auto-lints the edited file after every write or edit |
| `permission-denied.sh` | `PermissionDenied` | Logs auto-mode permission denials |
| `notify-compact.sh` | `PreCompact` | Desktop notification when context compacts |
| `cwd-changed.sh` | `CwdChanged` | Logs working-directory changes |
| `task-created.sh` | `TaskCreated` | Logs task-creation events |
| `stop-failure.sh` | `StopFailure` | Logs API-error turn endings |

Hooks read their JSON payload from stdin (file descriptor 0). `permissions.deny`
rules in `settings.json` additionally block reads of env and credential files —
deny rules are enforced by Claude Code itself, in every permission mode, and
extend to file reads through Bash (`cat .env` is denied too).

---

## How the Commands Work Together

```
/discuss "idea"
  → Lead interviews you; scout + researcher subagents work in the background
  → One adversarial challenger pass stress-tests the draft plan
  → Validated plan + ADLC handoff → /spec (complex) or /dev (small)

/spec "feature"
  → Right-size triage (no spec / light / full) → clarify → draft
  → One approval gate → saves to .context/specs/spec-[name].md
  → Each phase carries a transcript-verifiable Goal Condition (drivable via /goal)

/dev "feature" or /dev @.context/specs/spec-[name].md
  → Orient → explore (when unfamiliar) → clarify → build (direct by default,
    subagents when work decomposes) → verify gate (checks + fresh-context review,
    risk-triggered council) → reflect → commit or PR-ready → wrapup
```

Specs are local planning artifacts by default. They save under `.context/specs/`, which is gitignored, and should only be promoted into committed documentation when explicitly requested.

---

## Setup

### Context Directory

The `mcp-caching` rule and Cursor's session hooks write to `.context/` in your project root. Add it to your `.gitignore`:

```bash
echo ".context/" >> .gitignore
```

## User-level setup

One setting in this config lives in your **user-level** `~/.claude/settings.json`, not the project-level one in this repo:

1. **`autoMemoryDirectory` / `autoMemoryEnabled`** — Claude Code's policy rejects these keys from project settings to prevent shared projects redirecting memory writes. Copy this into `~/.claude/settings.json`:

    ```json
    {
      "autoMemoryEnabled": true,
      "autoMemoryDirectory": "~/.claude/projects/<your-project>/memory"
    }
    ```

    Replace `<your-project>` with a descriptive name. Claude Code will auto-create `MEMORY.md` and topic files there.

**Minimum Claude Code version:** 2.1.108 (released 2026-04-14). Verify with `claude --version`. Older versions will silently ignore `ENABLE_PROMPT_CACHING_1H` and may reject other features used here. Last verified against 2.1.229 (August 2026).

## Built-in commands leveraged

This config assumes the following native Claude Code commands are available. These are shipped by Claude Code itself, not by this repo.

| Command | When to use |
|---------|-------------|
| `/context` | Inspect what's loaded in your current context and where tokens are being spent |
| `/memory` | Inspect and edit auto-memory — see the "User-level setup" section above for where memory is stored |
| `/effort` | Switch between reasoning effort levels per task |
| `/team-onboarding` | Generate or refresh a team onboarding guide for this project |
| `/color` | Change session accent color (useful when running multiple sessions in parallel) |
| `/loop` | Run a prompt on a recurring or self-paced interval. See `.claude/skills/loop-patterns/SKILL.md` for per-agent recipes |

## Hardening options

Optional settings for security-sensitive or bandwidth-constrained environments.

**Deny outbound network calls to specific domains** (block the sandbox from reaching listed hosts, even for tools that normally have network access). Add to `.claude/settings.json`:

    {
      "sandbox": {
        "network": {
          "deniedDomains": ["evil.example.com", "*.tracker.example"]
        }
      }
    }

**Reduce terminal flicker on slow links.** Set `CLAUDE_CODE_NO_FLICKER=1` in your shell env or `.claude/settings.json` env block:

    {
      "env": {
        "CLAUDE_CODE_NO_FLICKER": "1"
      }
    }
