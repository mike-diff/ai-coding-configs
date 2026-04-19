---
feature: claude-config-modernization
created: 2026-04-19
status: draft
---

# Specification: Claude Code Config Modernization

## Overview

Upgrade the drop-in `.claude/` configuration in this repo to use Claude Code features that shipped between 2026-02-19 and 2026-04-19 — 1-hour prompt caching, statusline with rate-limit visibility, `autoMemoryDirectory`, 6 new hook events, conditional hook routing via the `if` field, `/loop` per-agent guidance, and documentation for newly shipped slash commands. Primary beneficiaries are downstream consumers who copy `.claude/` into their own projects; the config stays portable, with no hardcoded paths.

## Goals

1. Cut token usage and stretch the 5-hour quota via 1-hour prompt caching, real-time cost visibility, and explicit auto-memory wiring.
2. Add observability for silent failure modes (session-start validation, permission denials, compaction survival, conditional hook routing, stop-on-failure).
3. Automate light workflow signals (file/cwd change, task lifecycle, per-agent `/loop` guidance) without new background processes.
4. Document newly shipped Claude Code commands and sandbox hardening in `.claude/README.md` so downstream consumers can discover them.

## Technical Stack

- **Target harness:** Claude Code **≥ 2.1.108** (2026-04-14) — pinned to the oldest version that supports every feature used in this spec (the floor is set by `ENABLE_PROMPT_CACHING_1H`).
- **Languages:** Bash (hooks), JSON (`settings.json`), Markdown (skills, agents, rules, output-styles, README)
- **Log destination:** `.claude/.logs/` (gitignored)
- **Ephemeral cache:** `.context/` (gitignored)
- **Distribution model:** Drop-in — `.claude/` is copied into consumer project roots. Config must be portable (no hardcoded absolute paths other than `$CLAUDE_PROJECT_DIR`).

## Technical Plan

### Project Structure (after spec)

```
.claude/
├── settings.json                     # Gains env block + if-conditional hooks + new hook wiring
├── README.md                         # Refreshed with new commands, min version, user-level setup
├── statusline.sh                     # NEW — displays model, context %, cost, 5h rate limit
├── output-styles/
│   └── teaching.md                   # NEW — optional teaching output style
├── agents/                           # Unchanged structure; prompts gain /loop usage notes
├── skills/
│   └── loop-patterns/SKILL.md        # NEW — /loop patterns per agent
├── rules/                            # Unchanged
└── hooks/
    ├── block-dangerous.sh            # Unchanged body; settings.json routes it via if
    ├── validate-commit.sh            # Unchanged body; settings.json routes it via if
    ├── redact-secrets.sh             # Unchanged
    ├── post-edit-lint.sh             # Unchanged
    ├── teammate-idle.sh              # Unchanged
    ├── task-completed.sh             # Unchanged
    ├── notify-compact.sh             # ENHANCED — summarizes what survives compaction
    ├── session-start.sh              # NEW — repo digest + hook-wiring validation
    ├── permission-denied.sh          # NEW — audit log for denied tool calls
    ├── file-changed.sh               # NEW — signal only, logs to .claude/.logs/
    ├── cwd-changed.sh                # NEW — signal only, logs to .claude/.logs/
    ├── task-created.sh               # NEW — task manifest log
    └── stop-failure.sh               # NEW — failure audit log
```

### Integration Points

- **Claude Code harness** — reads `.claude/settings.json`, executes hooks on events, renders statusline, applies `ENABLE_PROMPT_CACHING_1H` env var
- **User-level settings (`~/.claude/settings.json`)** — REQUIRED for `autoMemoryDirectory` and `autoMemoryEnabled` (security policy rejects these from project settings)
- **`$CLAUDE_PROJECT_DIR`** — injected by Claude Code; used by all hook commands for portable path resolution

### Key Architectural Decisions

- **Pin minimum Claude Code version** (2.1.108) rather than supporting older versions. Rationale: user approved Q3 option A — assume latest, break cleanly, document the floor in README.
- **`autoMemoryDirectory` ships as docs only, not project settings.** Rationale: Claude Code rejects this key from project `.claude/settings.json` by policy — project settings cannot redirect memory writes.
- **Observability-only hooks (`PermissionDenied`, `StopFailure`) are pure loggers, never return exit 2.** Rationale: Claude Code ignores exit codes from these events — any non-zero exit is a script bug, not a block.
- **Conditional `if` migration only where it adds real clarity.** Hooks that only serve one matcher (e.g. `redact-secrets.sh` on `Read`) keep the plain matcher. Hooks that currently run on every `Bash` call (`block-dangerous.sh`, `validate-commit.sh`) migrate to `if` to cut evaluations.
- **Optional/heavy items ship fully wired.** Per Q4 option A, `teaching` output style, `FileChanged`/`CwdChanged`/`TaskCreated` hooks all ship live; consumers disable by editing `settings.json`.

## Non-Goals (Global)

1. No changes to `.cursor/` — Cursor parity is deferred to a future spec
2. No MCP server additions or changes
3. No structural changes to existing agent definitions — existing 5 agents keep their roles; prompts may gain `/loop` usage notes only
4. No net-new commands or skills beyond the enumerated items (1 new skill: `loop-patterns`)
5. No test harness or CI for `.claude/` validation — repo convention has no build system
6. No backwards-compatibility shims for older Claude Code versions — minimum is 2.1.108, below which failures are expected to be loud
7. No modifications to `block-dangerous.sh`, `redact-secrets.sh`, `validate-commit.sh`, `post-edit-lint.sh`, `teammate-idle.sh`, or `task-completed.sh` bodies — only their wiring in `settings.json`

## Success Criteria (Project)

- [ ] SC-001: `.claude/README.md` documents minimum Claude Code version (2.1.108) and verification command
- [ ] SC-002: Every new hook emits a log line to `.claude/.logs/hooks.log` when its event fires, with hook name and disposition (allowed / logged / blocked)
- [ ] SC-003: A fresh session on a scratch project (copy `.claude/` + user-level env setup per README) starts without errors and loads all new hooks — verified by running `claude -p "echo orient test"` and grepping the log
- [ ] SC-004: `.claude/README.md` documents every new hook, setting, slash command, environment variable, and output style introduced by this spec
- [ ] SC-005: The statusline renders on session start and displays model, context %, session cost, and 5-hour rate-limit percentage (or `—` if not available on the consumer's plan)
- [ ] SC-006: `jq . .claude/settings.json` exits 0 (valid JSON) and the new `if` conditional hooks route correctly — verified by running a `git commit --dry-run` and a non-git `ls` command and checking only the git case triggered `validate-commit.sh`
- [ ] SC-007: Dropping the modernized `.claude/` into an empty scratch directory triggers `SessionStart` and its log line appears in `.claude/.logs/hooks.log`
- [ ] SC-008: `shellcheck .claude/hooks/*.sh` reports zero new issues

## Planned Phases

| Phase | Name | User Stories | Priority |
|-------|------|--------------|----------|
| 1 | Quick Wins — Token & Quota | US1, US2, US3 | P0 |
| 2 | Observability Hooks | US4, US5, US6, US7 | P1 |
| 3 | Workflow Automation | US8, US9, US10 | P2 |
| 4 | Docs | US11, US12, US13 | P3 |
| 5 | Polish | (cleanup, full CLI smoke test) | P4 |

**User Story Summary:**

- **US1**: Enable 1-hour prompt caching (`ENABLE_PROMPT_CACHING_1H`) to stretch the 5-hour quota → Phase 1
- **US2**: Add statusline showing model, context %, cost, 5-hour rate-limit headroom → Phase 1
- **US3**: Document `autoMemoryDirectory` and `autoMemoryEnabled` for user-level `~/.claude/settings.json` → Phase 1
- **US4**: Add `SessionStart` hook that validates hook wiring and logs a session digest → Phase 2
- **US5**: Add `PermissionDenied` hook that logs denied tool calls → Phase 2
- **US6**: Enhance existing `notify-compact.sh` to summarize what survives compaction → Phase 2
- **US7**: Migrate existing PreToolUse hooks to the `if` conditional field where it adds clarity → Phase 2
- **US8**: Add `FileChanged` + `CwdChanged` hooks for lightweight automation signals → Phase 3
- **US9**: Add `TaskCreated` + `StopFailure` hooks for agent lifecycle observability → Phase 3
- **US10**: Document `/loop` patterns per existing agent in a new `loop-patterns` skill → Phase 3
- **US11**: Refresh `.claude/README.md` with a "Built-in commands leveraged" section (`/context`, `/memory`, `/effort`, `/team-onboarding`, `/color`, `/tui`, `/loop`) → Phase 4
- **US12**: Ship an optional "teaching" output style in `.claude/output-styles/` → Phase 4
- **US13**: Document sandbox hardening options (`sandbox.network.deniedDomains`, `CLAUDE_CODE_NO_FLICKER`) → Phase 4

## Open Questions

None — all verification resolved against live docs (cached at `.context/mcp-cache/claude-code-feature-verification-20260419.md`).

---

# Phase 1: Quick Wins — Token & Quota

## Scope

Enable 1-hour prompt caching, add a cost-visible statusline, and document user-level `autoMemoryDirectory` setup. These three items land the largest token/quota impact with minimal surface area.

## User Stories

### US1: Enable 1-hour prompt caching (Priority: P0)

**As a** downstream consumer running long Claude Code sessions, **I want to** have 1-hour prompt caching enabled by default **so that** resumed sessions reuse cached context and my 5-hour quota stretches further.

**Acceptance Criteria:**
- Given a fresh session started from `.claude/settings.json`, when Claude reads the env block, then `ENABLE_PROMPT_CACHING_1H=1` is set.
- Given a session paused for 30 minutes and resumed, when Claude processes the first message after resume, then prior context is served from the 1-hour cache (not re-tokenized from scratch).
- Given an older Claude Code version that predates this env var, when the user starts a session, then the var is silently ignored (no error).

**Proof Artifacts:**
- `jq '.env.ENABLE_PROMPT_CACHING_1H' .claude/settings.json` returns `"1"` — demonstrates FR-001
- README snippet showing the env block — demonstrates FR-003

### US2: Statusline with context %, cost, rate-limit (Priority: P0)

**As a** user working against the 5-hour rolling quota, **I want to** see my current context %, session cost, and 5-hour rate-limit percentage at all times **so that** I can pace my work without hitting quota surprise mid-task.

**Acceptance Criteria:**
- Given `statusline.sh` is wired in `settings.json`, when a session starts, then the status line renders with model, context %, cost, and 5h rate-limit.
- Given the user is on a plan without `rate_limits` in the status input (e.g. an API-key-only user), when the script runs, then rate-limit field displays `—` (not an error).
- Given malformed or missing JSON fields, when the script runs, then it never exits non-zero (degrades gracefully).

**Proof Artifacts:**
- Screenshot/terminal paste of a running session showing `[model] | NN% ctx | $X.XX | 5h: NN%` — demonstrates FR-004, FR-005
- Manual test: `echo '{"model":{"display_name":"opus"}}' | .claude/statusline.sh` prints output without error — demonstrates FR-006

### US3: Document `autoMemoryDirectory` for user-level settings (Priority: P0)

**As a** consumer adopting this config, **I want** a documented user-level setup snippet for `autoMemoryDirectory` and `autoMemoryEnabled` **so that** auto-memory persists where I expect and I can inspect/edit it.

**Acceptance Criteria:**
- Given `.claude/README.md`, when a new consumer reads the setup section, then they see a user-level `~/.claude/settings.json` snippet configuring `autoMemoryEnabled` and `autoMemoryDirectory`.
- Given the README, when the consumer reads the note, then they understand why this cannot live in project `.claude/settings.json` (security policy).

**Proof Artifacts:**
- Rendered section in `.claude/README.md` showing the user-level snippet and the explanatory note — demonstrates FR-007

## Functional Requirements

- **FR-001** [US1]: The system MUST set `ENABLE_PROMPT_CACHING_1H=1` in `.claude/settings.json` `env` block.
- **FR-002** [US1]: The `settings.json` MUST remain valid JSON after the edit (`jq .` exits 0).
- **FR-003** [US1]: `.claude/README.md` MUST document the env var, its purpose, and plan eligibility.
- **FR-004** [US2]: The `statusline.sh` script MUST render model, context %, cost (USD, 2 decimals), and 5-hour rate-limit %.
- **FR-005** [US2]: `settings.json` MUST wire `statusline.sh` via the `statusLine` key.
- **FR-006** [US2]: `statusline.sh` MUST exit 0 even when input JSON fields are missing (graceful fallback to `—` or `0`).
- **FR-007** [US3]: `.claude/README.md` MUST include a "User-level setup" section with a copy-pasteable snippet configuring `autoMemoryEnabled: true` and `autoMemoryDirectory`, plus a note explaining the policy-level restriction.

## Non-Goals (This Phase)

1. No new hooks — hooks ship in Phase 2+
2. No changes to hook wiring — that is Phase 2 (US7)
3. No documentation of slash commands — that is Phase 4 (US11)
4. No auto-memory seeding, CLAUDE.md generation, or memory content shipped in this repo — consumers build their own

## Dependencies (verified 2026-04-19)

| Feature | Minimum Claude Code | Purpose | Docs Reference |
|---------|--------------------|---------|----------------|
| `ENABLE_PROMPT_CACHING_1H` env var | 2.1.108 | 1-hour prompt cache TTL | https://code.claude.com/docs/en/env-vars.md |
| `statusLine` settings key + stdin JSON with `rate_limits.five_hour` | 2.1.80 | Real-time cost/quota visibility | https://code.claude.com/docs/en/statusline.md |
| `autoMemoryDirectory` / `autoMemoryEnabled` settings keys | 2.1.74 | Per-project memory location | https://code.claude.com/docs/en/memory.md |

## Reference Documentation

| Feature | Key Syntax | Reference |
|---------|------------|-----------|
| Prompt caching | `"env": {"ENABLE_PROMPT_CACHING_1H": "1"}` | env-vars.md |
| Statusline wiring | `"statusLine": {"type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/statusline.sh"}` | statusline.md |
| Statusline input JSON | `.model.display_name`, `.context_window.used_percentage`, `.cost.total_cost_usd`, `.rate_limits.five_hour.used_percentage`, `.rate_limits.five_hour.resets_at` | statusline.md |
| autoMemoryDirectory | User-level `~/.claude/settings.json` only; accepts absolute / `~` / relative paths; policy rejects from project settings | memory.md |

## Implementation Guidance

**Prompt caching — add to `.claude/settings.json`:**

Add a top-level `env` block. If one exists (it does not, currently), merge into it. Do not delete any existing keys.

```json
{
  "env": {
    "ENABLE_PROMPT_CACHING_1H": "1"
  },
  "hooks": { ... existing unchanged ... }
}
```

**Statusline script — `.claude/statusline.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Graceful: never exit non-zero, always print something readable.
input=$(cat 2>/dev/null || echo '{}')

MODEL=$(echo "$input" | jq -r '.model.display_name // "claude"' 2>/dev/null || echo "claude")
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' 2>/dev/null | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // "N/A"' 2>/dev/null)

COST_FMT=$(printf '$%.2f' "${COST:-0}" 2>/dev/null || echo '$0.00')
if [[ "$FIVE_H" == "N/A" || -z "$FIVE_H" ]]; then
  FIVE_H_FMT="—"
else
  FIVE_H_FMT="$(printf '%.0f' "$FIVE_H" 2>/dev/null || echo '?')%"
fi

echo "[$MODEL] | ${CTX_PCT}% ctx | $COST_FMT | 5h: $FIVE_H_FMT"
```

Make executable: `chmod +x .claude/statusline.sh`.

**Statusline wiring — add to `.claude/settings.json` top level (sibling of `hooks`):**

```json
"statusLine": {
  "type": "command",
  "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/statusline.sh"
}
```

**README section — append to `.claude/README.md` under a new "User-level setup" heading:**

```markdown
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
```

## Tasks

- T001 [US1] Add `env` block with `ENABLE_PROMPT_CACHING_1H: "1"` to `.claude/settings.json` (merge as new top-level key alongside existing `hooks`)
- T002 [P] [US2] Create `.claude/statusline.sh` using the Implementation Guidance template; `chmod +x` the file
- T003 [US2] Add `statusLine` top-level key to `.claude/settings.json` pointing to the new script
- T004 [P] [US1, US2, US3] Append the "User-level setup" section (including min-version note and `autoMemoryDirectory` snippet) to `.claude/README.md`
- T005 [US1, US2] Validate `jq . .claude/settings.json` exits 0 (depends on T001, T003)
- T006 [US2] Smoke-test the statusline: `echo '{"model":{"display_name":"opus-4-7"},"context_window":{"used_percentage":42.5},"cost":{"total_cost_usd":1.23},"rate_limits":{"five_hour":{"used_percentage":18}}}' | .claude/statusline.sh` — expect `[opus-4-7] | 42% ctx | $1.23 | 5h: 18%` (depends on T002)
- T007 [US2] Smoke-test graceful degradation: `echo '{}' | .claude/statusline.sh` — expect output without error (depends on T002)

## Files to Create

- `.claude/statusline.sh` — executable statusline script rendering model/context/cost/5h

## Files to Modify

- `.claude/settings.json` — add `env` and `statusLine` top-level keys
- `.claude/README.md` — add "User-level setup" section with `autoMemoryDirectory` snippet and min-version note

## Success Criteria

1. `.claude/settings.json` contains `ENABLE_PROMPT_CACHING_1H=1` in the env block and `statusLine` is wired
2. `.claude/statusline.sh` is executable and produces the expected format for both full and empty input
3. `.claude/README.md` documents user-level setup including `autoMemoryDirectory` and minimum Claude Code version
4. `jq . .claude/settings.json` exits 0
5. Manual CLI smoke: starting `claude` in the repo shows the new statusline

## Proof Artifacts

- CLI output: `jq '.env, .statusLine' .claude/settings.json` shows both keys populated
- CLI output: the two smoke-test commands in T006/T007 print expected strings
- Terminal screenshot (or paste) of `claude` running with new statusline visible

## Verify Before Proceeding

- [ ] Goal achieved: Is 1-hour caching enabled, is the statusline rendering, and is user-level memory setup documented?
- [ ] Tests: `jq . .claude/settings.json` exits 0; both smoke-test invocations of `statusline.sh` succeed
- [ ] Proof: Terminal screenshot of live statusline captured
- [ ] No regressions: existing `hooks` key in `settings.json` still present and unchanged; existing hooks still fire (run a noop `Bash` command and confirm `.claude/.logs/hooks.log` gets `block-dangerous` entry)

---

# Phase 2: Observability Hooks

## Prerequisites

Phase 1 must be complete. You should have:
- `.claude/settings.json` with a top-level `env` block, `statusLine`, and an existing `hooks` block
- `.claude/statusline.sh` present and executable
- `.claude/README.md` with "User-level setup" section and min-version (2.1.108) note
- `.claude/.logs/` directory exists (created automatically by existing hooks, but ensure `mkdir -p` is defensive in new scripts)

## Scope

Add four observability hooks (`SessionStart`, `PermissionDenied`), enhance the existing `PreCompact` hook to summarize what survives compaction, and migrate existing `PreToolUse` hooks to the new `if` conditional field for cleaner routing.

## User Stories

### US4: SessionStart hook for repo digest + validation (Priority: P1)

**As a** user starting a Claude Code session on a project using this config, **I want** a SessionStart hook that validates hook wiring and emits a session digest to the log **so that** broken hooks or missing dependencies fail loudly instead of silently.

**Acceptance Criteria:**
- Given a session start, when the hook fires, then `.claude/.logs/hooks.log` contains a line with session_id, source (startup/resume/clear/compact), model, and cwd.
- Given all 8 hook scripts exist and are executable, when the hook validates them, then it logs `OK: hook inventory complete`.
- Given one of the existing hook scripts is missing the execute bit, when the hook runs, then it logs `WARN: <hook> not executable` but does NOT block session start (exit 0).

**Proof Artifacts:**
- Log line in `.claude/.logs/hooks.log` showing the session digest — demonstrates FR-101
- Manual test: `chmod -x .claude/hooks/block-dangerous.sh && claude -p "test"` produces the warn line, then restore with `chmod +x` — demonstrates FR-102

### US5: PermissionDenied hook for audit logging (Priority: P1)

**As a** user running Claude Code in auto mode, **I want** a `PermissionDenied` hook that logs every denied tool call with tool name and reason **so that** I can review denial patterns and refine permissions.

**Acceptance Criteria:**
- Given auto mode denies a tool call, when the hook fires, then a line is appended to `.claude/.logs/permission-denied.log` with timestamp, tool name, and reason.
- Given the hook runs, it never returns exit code 2 (Claude Code ignores it anyway, but we guard against surprising behavior).
- Given malformed stdin JSON, when the hook runs, then it exits 0 without crashing (defensive jq).

**Proof Artifacts:**
- `.claude/.logs/permission-denied.log` contains a tested synthetic entry — demonstrates FR-103

### US6: Enhanced PreCompact hook summarizing survivors (Priority: P1)

**As a** user whose session is about to compact, **I want** the existing `notify-compact.sh` to additionally list which rules, skills, and agents survive compaction **so that** I know what instructions remain in Claude's context after the compaction.

**Acceptance Criteria:**
- Given `PreCompact` fires, when `notify-compact.sh` runs, then it logs (a) context usage %, (b) a list of `.claude/rules/*.md` files (these persist), (c) a list of currently-loaded skill names from stdin if present.
- Given the script is enhanced, it retains existing behavior (exit 0, non-blocking).

**Proof Artifacts:**
- Log entry in `.claude/.logs/hooks.log` showing the survivor summary when PreCompact is triggered — demonstrates FR-104

### US7: Migrate existing PreToolUse hooks to the `if` conditional field (Priority: P1)

**As a** maintainer of this config, **I want** `block-dangerous.sh` and `validate-commit.sh` routed via the `if` field instead of running on every `Bash` call and filtering internally **so that** hook evaluations are cleaner, fewer, and easier to audit.

**Acceptance Criteria:**
- Given `settings.json`, when a non-git, non-dangerous `Bash` command fires (e.g. `ls`), then `validate-commit.sh` does NOT execute (log line absent).
- Given a `git commit` command, when it fires, then `validate-commit.sh` executes (log line present).
- Given a dangerous pattern (e.g. `git push --force main`), when it fires, then `block-dangerous.sh` executes and blocks (exit 2).
- Given an unrelated `Bash` command, when it fires, then `block-dangerous.sh` does NOT execute.

**Proof Artifacts:**
- `.claude/.logs/hooks.log` from a test run showing `ls` command produces NO validate-commit entry — demonstrates FR-105
- Same log showing `git commit` produces validate-commit entry — demonstrates FR-105
- Same log showing `echo hi` produces NO block-dangerous entry — demonstrates FR-106

## Functional Requirements

- **FR-101** [US4]: `session-start.sh` MUST log session_id, source, model, and cwd to `.claude/.logs/hooks.log` on every session start.
- **FR-102** [US4]: `session-start.sh` MUST validate hook scripts are present and executable, log warnings for any failures, and exit 0 regardless (non-blocking).
- **FR-103** [US5]: `permission-denied.sh` MUST append timestamp, tool name, and reason to `.claude/.logs/permission-denied.log` and always exit 0.
- **FR-104** [US6]: `notify-compact.sh` MUST additionally log (a) a list of `.claude/rules/*.md` present and (b) the input JSON's loaded-skills field if present, in addition to existing behavior.
- **FR-105** [US7]: `validate-commit.sh` MUST only execute when the Bash command matches `git commit *` — enforced via the `if` field in `settings.json`, not inside the script.
- **FR-106** [US7]: `block-dangerous.sh` MUST only execute when the Bash command matches a destructive-pattern rule — routed via `if` in `settings.json` (the script's internal regex checks remain as defense-in-depth).

## Non-Goals (This Phase)

1. No changes to `redact-secrets.sh`, `post-edit-lint.sh`, `teammate-idle.sh`, or `task-completed.sh` hook wiring — they stay on simple matchers
2. No behavior changes to the bodies of `block-dangerous.sh` or `validate-commit.sh` — only how they are invoked
3. No new slash commands — `/loop` and friends are Phase 3+
4. No new env vars — Phase 1 handles `ENABLE_PROMPT_CACHING_1H`

## Dependencies (verified 2026-04-19)

*(Only NEW features introduced in this phase)*

| Feature | Minimum Claude Code | Purpose | Docs Reference |
|---------|--------------------|---------|----------------|
| `SessionStart` hook event | 2.1.x (pre-spec floor) | Session startup validation | https://code.claude.com/docs/en/hooks.md |
| `PermissionDenied` hook event | 2.1.89 | Observability for denied tool calls | hooks.md — changelog 2026-04-01 |
| Conditional hooks (`if` field) | 2.1.85 | Routed execution without regex inside scripts | hooks.md — changelog 2026-03-26 |

## Reference Documentation

| Event | Stdin Fields | Exit 2 Behavior |
|-------|--------------|-----------------|
| `SessionStart` | `session_id`, `cwd`, `hook_event_name`, `source`, `model` | Blocks session start (use exit 0 always for validation hook) |
| `PermissionDenied` | `hook_event_name`, `tool_name`, `tool_input`, `reason` | Ignored — observability only |
| `PreCompact` (existing) | event name; may include loaded-skill/rule fields | Observability |

**`if` field syntax:** permission-rule expression — `Bash(<pattern>)`, `Edit(<glob>)`. Only supported on `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`.

## Implementation Guidance

**`.claude/hooks/session-start.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/hooks.log"
HOOKS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks"

ts() { date '+%H:%M:%S'; }
log() { echo "[$(ts)] [session-start] $1" >> "$LOG"; }

INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
SID=$(echo "$INPUT" | jq -r '.session_id // "?"')
SRC=$(echo "$INPUT" | jq -r '.source // "?"')
MDL=$(echo "$INPUT" | jq -r '.model // "?"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "?"')

log "START sid=$SID source=$SRC model=$MDL cwd=$CWD"

# Validate required hook scripts are executable
REQUIRED=(block-dangerous.sh validate-commit.sh redact-secrets.sh post-edit-lint.sh teammate-idle.sh task-completed.sh notify-compact.sh)
MISSING=0
for h in "${REQUIRED[@]}"; do
  if [[ ! -x "$HOOKS_DIR/$h" ]]; then
    log "WARN: $h not executable or missing"
    MISSING=$((MISSING+1))
  fi
done
if [[ $MISSING -eq 0 ]]; then
  log "OK: hook inventory complete"
else
  log "WARN: $MISSING hook(s) have issues — run chmod +x .claude/hooks/*.sh"
fi

exit 0
```

**`.claude/hooks/permission-denied.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/permission-denied.log"

INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "?"' 2>/dev/null || echo '?')
REASON=$(echo "$INPUT" | jq -r '.reason // "?"' 2>/dev/null || echo '?')

echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] tool=$TOOL reason=$REASON" >> "$LOG"
exit 0
```

**Enhance `.claude/hooks/notify-compact.sh`** (keep existing lines; add survivor summary):

```bash
# ... existing body ...

# Added: survivor summary
RULES_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/rules"
if [[ -d "$RULES_DIR" ]]; then
  RULE_LIST=$(find "$RULES_DIR" -maxdepth 1 -name '*.md' -printf '%f ' 2>/dev/null || echo '')
  log "SURVIVORS rules: $RULE_LIST"
fi

LOADED_SKILLS=$(echo "${INPUT:-{}}" | jq -r '.loaded_skills // [] | join(",")' 2>/dev/null || echo '')
[[ -n "$LOADED_SKILLS" ]] && log "SURVIVORS skills-at-compact: $LOADED_SKILLS"
```

(The exact merge into the existing script is at the implementer's discretion — key behavior: add two additional log lines, preserve all existing behavior, exit 0.)

**`.claude/settings.json` — replace the existing `hooks` block with the `if`-migrated version.** The full replacement (preserving all existing wiring plus adding the new hooks):

```json
{
  "env": {
    "ENABLE_PROMPT_CACHING_1H": "1"
  },
  "statusLine": {
    "type": "command",
    "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/statusline.sh"
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session-start.sh" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(rm -rf *)",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous.sh"
          },
          {
            "type": "command",
            "if": "Bash(git push *)",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous.sh"
          },
          {
            "type": "command",
            "if": "Bash(git reset *)",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous.sh"
          },
          {
            "type": "command",
            "if": "Bash(git commit*)",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/validate-commit.sh"
          }
        ]
      },
      {
        "matcher": "Read",
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/redact-secrets.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/post-edit-lint.sh" }
        ]
      }
    ],
    "PermissionDenied": [
      {
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/permission-denied.sh" }
        ]
      }
    ],
    "TeammateIdle": [
      {
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/teammate-idle.sh" }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/task-completed.sh" }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/notify-compact.sh" }
        ]
      }
    ]
  }
}
```

Note on `if` patterns: the destructive-pattern list above uses multiple `if` clauses (one per pattern family) because the `if` expression language is permission-rule syntax, not full regex. The script `block-dangerous.sh` keeps its internal regex as defense-in-depth — if any of these clauses match, the script runs and does its own fine-grained check.

## Tasks

- T101 [US4] Create `.claude/hooks/session-start.sh` per Implementation Guidance; `chmod +x`
- T102 [P] [US5] Create `.claude/hooks/permission-denied.sh` per Implementation Guidance; `chmod +x`
- T103 [P] [US6] Enhance `.claude/hooks/notify-compact.sh` with survivor-summary block (preserve existing body, append the two new log lines)
- T104 [US7] Update `.claude/settings.json` `hooks.PreToolUse` array to split `block-dangerous.sh` and `validate-commit.sh` into separate `if`-routed entries (remove the combined matcher) (depends on T101, T102 so the full file is consistent)
- T105 [US4, US5] Wire `SessionStart` and `PermissionDenied` events into `.claude/settings.json` `hooks` block (merge with T104 into a single final settings.json write)
- T106 [US4, US5, US6, US7] Validate `jq . .claude/settings.json` exits 0 (depends on T104, T105)
- T107 [US4] CLI smoke test: run `claude -p "echo session-start test"` in the repo; grep `.claude/.logs/hooks.log` for `[session-start] START` line (depends on T101, T105)
- T108 [US7] CLI smoke test for `if` routing: run `claude -p "run: ls"` and `claude -p "run: git commit -m test --dry-run"`; verify the first does NOT produce a `validate-commit` log entry and the second DOES (depends on T104)
- T109 [US7] CLI smoke test for block-dangerous: run a session and attempt a benign `echo hi` Bash command; verify NO `block-dangerous` entry in log (depends on T104)
- T110 [US6] Manually trigger compaction via `/compact` in a loaded session; grep log for new `SURVIVORS rules:` line (depends on T103)

## Files to Create

- `.claude/hooks/session-start.sh` — SessionStart hook
- `.claude/hooks/permission-denied.sh` — PermissionDenied audit log

## Files to Modify

- `.claude/hooks/notify-compact.sh` — append survivor summary
- `.claude/settings.json` — migrate PreToolUse hooks to `if` field, wire SessionStart + PermissionDenied events

## Success Criteria

1. SessionStart fires on every session and logs a digest line
2. PermissionDenied log file exists and receives entries for denied tool calls
3. PreCompact hook logs a rules-survivor line
4. `if`-routed hooks only fire when the command pattern matches
5. All hook scripts pass `shellcheck` with no new errors

## Proof Artifacts

- Log excerpt from `.claude/.logs/hooks.log` showing `[session-start] START` and `OK: hook inventory complete`
- Log excerpt showing `validate-commit` only ran on `git commit`, not on `ls`
- `.claude/.logs/permission-denied.log` exists (may be empty if no denials occurred)
- Log excerpt showing `SURVIVORS rules:` from a compaction

## Verify Before Proceeding

- [ ] Goal achieved: Are observability hooks logging, and are PreToolUse hooks only firing when they should?
- [ ] Tests: T107, T108, T109, T110 all pass
- [ ] Proof: Log excerpts captured showing correct routing behavior
- [ ] No regressions: `redact-secrets.sh`, `post-edit-lint.sh`, `teammate-idle.sh`, `task-completed.sh` all still fire on their events (trigger each and grep log)

---

# Phase 3: Workflow Automation

## Prerequisites

Phase 2 must be complete. You should have:
- `.claude/settings.json` with `env`, `statusLine`, `hooks` (including `SessionStart`, `PermissionDenied`, conditional `if` PreToolUse, existing others)
- `.claude/hooks/session-start.sh` and `permission-denied.sh` present
- Enhanced `notify-compact.sh` emitting survivor-summary lines
- `.claude/.logs/hooks.log` receiving entries consistently

## Scope

Add four lightweight signal hooks (`FileChanged`, `CwdChanged`, `TaskCreated`, `StopFailure`) as pure loggers, and ship a new `loop-patterns` skill documenting recommended `/loop` usage for each existing agent.

## User Stories

### US8: FileChanged + CwdChanged hooks (Priority: P2)

**As a** user whose workflow benefits from lightweight automation signals, **I want** `FileChanged` and `CwdChanged` hooks that log file and directory transitions to `.claude/.logs/hooks.log` **so that** I (or a future enhancement) can react to them without spinning up `/loop` processes.

**Acceptance Criteria:**
- Given a tracked file changes on disk, when the hook fires, then a line with `file_path` and `change_type` is appended to the log.
- Given `cd` changes directory within a session, when the hook fires, then a line with new `cwd` is appended to the log.
- Given either hook runs, it exits 0 (never exits 2 — we are signaling only, not blocking).
- Given stdin is empty or malformed, the hook exits 0 without crashing.

**Proof Artifacts:**
- Log excerpt showing `FileChanged` entry after editing `.env.example` — demonstrates FR-201
- Log excerpt showing `CwdChanged` entry — demonstrates FR-202

### US9: TaskCreated + StopFailure hooks (Priority: P2)

**As a** user running coordinated agent teams, **I want** `TaskCreated` and `StopFailure` hooks logging task lifecycle and API-error terminations **so that** I can audit which tasks were spawned and diagnose unexpected session endings.

**Acceptance Criteria:**
- Given a subagent calls `TaskCreate`, when the hook fires, then a line with task_id, subject, teammate_name is appended to `.claude/.logs/tasks.log`.
- Given a session ends due to rate limit / billing / other API failure, when `StopFailure` fires, then a line with the error matcher is appended to `.claude/.logs/stop-failures.log`.
- Given either hook, exit 0 always (StopFailure ignores exit code; TaskCreated would block if exit 2, which we deliberately avoid).

**Proof Artifacts:**
- `.claude/.logs/tasks.log` has entries after spawning a sub-agent via the Agent tool — demonstrates FR-203
- `.claude/.logs/stop-failures.log` exists (may be empty in happy-path testing) — demonstrates FR-204

### US10: /loop patterns per agent (Priority: P2)

**As a** user orchestrating the five existing agents, **I want** a `loop-patterns` skill documenting recommended `/loop` use cases for each agent **so that** I can delegate polling/watch work without guessing cadence or prompt shape.

**Acceptance Criteria:**
- Given the new skill `.claude/skills/loop-patterns/SKILL.md`, when Claude's skill index loads it, then it activates when the user asks about "loop", "polling", "watch", or "periodic".
- Given the skill body, it documents at least one concrete `/loop` pattern for explorer, implementer, reviewer, qa — with example commands and recommended cadence.
- Given a skill-spec lint (`jq .` of the frontmatter block and presence of `name`, `description`), it is valid per `.claude/skills/skill/` conventions.

**Proof Artifacts:**
- Rendered `SKILL.md` containing the 4 agent patterns with example `/loop` invocations — demonstrates FR-205
- `claude` session where typing "how should I use /loop with explorer?" surfaces the skill — demonstrates FR-205 (semantic activation is nondeterministic; failure tolerant — if skill activation doesn't fire in one test, re-run once; document the skill name so users can invoke manually)

## Functional Requirements

- **FR-201** [US8]: `file-changed.sh` MUST append timestamp, file_path, change_type to `.claude/.logs/hooks.log` and exit 0.
- **FR-202** [US8]: `cwd-changed.sh` MUST append timestamp and cwd to `.claude/.logs/hooks.log` and exit 0.
- **FR-203** [US9]: `task-created.sh` MUST append timestamp, task_id, task_subject, teammate_name to `.claude/.logs/tasks.log` and exit 0.
- **FR-204** [US9]: `stop-failure.sh` MUST append timestamp, permission_mode, and matcher (if parseable) to `.claude/.logs/stop-failures.log` and exit 0.
- **FR-205** [US10]: `.claude/skills/loop-patterns/SKILL.md` MUST contain a YAML frontmatter with `name: loop-patterns`, a 1-line `description` that mentions "loop", "polling", or "watch", and body sections for each of the 5 existing agents (explorer, implementer, reviewer, qa, skill-author).

## Non-Goals (This Phase)

1. No reactive behavior driven by the new hooks — they are signal-only loggers. Consumers wire actions later themselves.
2. No changes to existing agent prompts beyond the new skill — the `/loop` skill is the discovery surface, not agent-prompt edits
3. No new slash commands — only a new skill

## Dependencies (verified 2026-04-19)

| Feature | Minimum Claude Code | Purpose | Docs Reference |
|---------|--------------------|---------|----------------|
| `FileChanged` hook event | 2.1.85 | File change signal | hooks.md — changelog 2026-03-25 |
| `CwdChanged` hook event | 2.1.85 | Directory change signal | hooks.md — changelog 2026-03-25 |
| `TaskCreated` hook event | 2.1.84 | Task lifecycle signal | hooks.md — changelog 2026-03-26 |
| `StopFailure` hook event | 2.1.82 | API-error termination signal | hooks.md — changelog 2026-03-17 |
| `/loop` command | 2.1.x (exists pre-spec floor; improved 2.1.113) | Periodic / self-paced execution | https://code.claude.com/docs/en/commands.md#loop |

## Reference Documentation

| Event | Stdin | Notes |
|-------|-------|-------|
| `FileChanged` | `hook_event_name`, `file_path`, `change_type` | Matchers are filename globs; exit 2 blocks reload |
| `CwdChanged` | `hook_event_name`, `cwd` | Exit 2 blocks the cd |
| `TaskCreated` | `hook_event_name`, `task_id`, `task_subject`, `task_description`, `teammate_name`, `team_name` | Exit 2 OR `{"decision":"block","reason":"..."}` blocks task |
| `StopFailure` | `hook_event_name`, `permission_mode` | Matchers: error type (`rate_limit`, `authentication_failed`, `billing_error`, `invalid_request`, `server_error`, `max_output_tokens`, `unknown`); exit code ignored |

## Implementation Guidance

**`.claude/hooks/file-changed.sh`** (template for all four signal hooks — minimal logger):

```bash
#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/hooks.log"
INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
FP=$(echo "$INPUT" | jq -r '.file_path // "?"' 2>/dev/null || echo '?')
CT=$(echo "$INPUT" | jq -r '.change_type // "?"' 2>/dev/null || echo '?')
echo "[$(date '+%H:%M:%S')] [file-changed] $CT $FP" >> "$LOG"
exit 0
```

**`.claude/hooks/cwd-changed.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/hooks.log"
INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
NEW=$(echo "$INPUT" | jq -r '.cwd // "?"' 2>/dev/null || echo '?')
echo "[$(date '+%H:%M:%S')] [cwd-changed] -> $NEW" >> "$LOG"
exit 0
```

**`.claude/hooks/task-created.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/tasks.log"
INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
TID=$(echo "$INPUT" | jq -r '.task_id // "?"' 2>/dev/null || echo '?')
SUB=$(echo "$INPUT" | jq -r '.task_subject // "?"' 2>/dev/null || echo '?')
TM=$(echo "$INPUT" | jq -r '.teammate_name // "?"' 2>/dev/null || echo '?')
echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] task=$TID teammate=$TM subject=\"$SUB\"" >> "$LOG"
exit 0
```

**`.claude/hooks/stop-failure.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/.logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/stop-failures.log"
INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
PM=$(echo "$INPUT" | jq -r '.permission_mode // "?"' 2>/dev/null || echo '?')
echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] stop-failure permission_mode=$PM raw=$INPUT" >> "$LOG"
exit 0
```

**`.claude/settings.json` — add to `hooks` object:**

```json
"FileChanged": [
  {
    "hooks": [
      { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/file-changed.sh" }
    ]
  }
],
"CwdChanged": [
  {
    "hooks": [
      { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/cwd-changed.sh" }
    ]
  }
],
"TaskCreated": [
  {
    "hooks": [
      { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/task-created.sh" }
    ]
  }
],
"StopFailure": [
  {
    "hooks": [
      { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/stop-failure.sh" }
    ]
  }
]
```

**`.claude/skills/loop-patterns/SKILL.md`:**

```markdown
---
name: loop-patterns
description: Recommended /loop patterns for the agents shipped in this repo (explorer, implementer, reviewer, qa, skill-author). Activates when the user asks about /loop, polling, watch-mode, periodic tasks, or autonomous iteration.
---

# /loop patterns per agent

The `/loop` command runs a prompt or slash command on a recurring interval, or self-paces via ScheduleWakeup when no interval is given. These patterns match the responsibilities of the five agents in `.claude/agents/`.

## explorer — periodic codebase crawl

Best when the codebase shifts rapidly (active development, frequent merges).

    /loop 15m Explore changes since the last crawl and append new findings to .context/explorer-notes.md

Cadence: 10–30 minutes. Good for: pre-implementation recon during long discussions.

## implementer — self-paced watch-build

When implementing a long feature across many edits. Omit the interval so ScheduleWakeup picks delays based on build duration.

    /loop Continue building the current feature spec; after each iteration, run the project's build and paste any new errors into the next prompt.

Cadence: self-paced. Good for: large spec phases, CI-heavy projects.

## reviewer — post-edit incremental review

    /loop 20m Review all files modified since the last review pass and flag any that violate `.claude/rules/coding-standards.md`.

Cadence: 15–30 minutes. Good for: keeping a running review in parallel with implementer.

## qa — watch-test loop

    /loop 5m Run the project's test command; if any fail, message the implementer with the full failure output.

Cadence: 5–15 minutes. Good for: active red-green TDD sessions.

## skill-author — TDD drip

Uncommon; used during long skill authoring when the baseline test suite is slow.

    /loop Re-run the skill baseline test after each edit to .claude/skills/<name>/SKILL.md.

Cadence: self-paced. Good for: multi-file skill authoring.

## Not recommended

- Running `/loop` on one-shot tasks — starts a recurring process that outlives the task
- Cadences under 60 seconds — the runtime clamps `delaySeconds` to [60, 3600]
- Loops that accumulate unbounded context — pair with summarize-and-reset instructions
```

## Tasks

- T201 [P] [US8] Create `.claude/hooks/file-changed.sh` and `cwd-changed.sh` per Implementation Guidance; `chmod +x`
- T202 [P] [US9] Create `.claude/hooks/task-created.sh` and `stop-failure.sh` per Implementation Guidance; `chmod +x`
- T203 [US8, US9] Add `FileChanged`, `CwdChanged`, `TaskCreated`, `StopFailure` event wiring to `.claude/settings.json` `hooks` object (depends on T201, T202)
- T204 [US8, US9] Validate `jq . .claude/settings.json` exits 0 (depends on T203)
- T205 [P] [US10] Create `.claude/skills/loop-patterns/SKILL.md` per Implementation Guidance
- T206 [US8] CLI smoke test: make Claude edit or touch a file in session; grep `.claude/.logs/hooks.log` for `[file-changed]` entry (depends on T203)
- T207 [US8] CLI smoke test: have Claude `cd` to a different directory; grep log for `[cwd-changed]` entry (depends on T203)
- T208 [US9] CLI smoke test: spawn a sub-agent via the Agent tool; confirm `.claude/.logs/tasks.log` gets an entry (depends on T203)
- T209 [US9] Verify `.claude/.logs/stop-failures.log` is created on first StopFailure fire — may be empty in happy-path testing; confirm `stop-failure.sh` runs cleanly with synthetic stdin: `echo '{"permission_mode":"default"}' | .claude/hooks/stop-failure.sh && tail -1 .claude/.logs/stop-failures.log` (depends on T202)
- T210 [US10] Validate skill frontmatter: `head -5 .claude/skills/loop-patterns/SKILL.md | grep -E '^(name|description):'` returns two lines (depends on T205)

## Files to Create

- `.claude/hooks/file-changed.sh`
- `.claude/hooks/cwd-changed.sh`
- `.claude/hooks/task-created.sh`
- `.claude/hooks/stop-failure.sh`
- `.claude/skills/loop-patterns/SKILL.md`

## Files to Modify

- `.claude/settings.json` — add 4 new event wires

## Success Criteria

1. All 4 new signal hooks log to `.claude/.logs/` on their events
2. `loop-patterns` skill is present with valid frontmatter and covers all 5 agents
3. `shellcheck` on all 4 new hooks reports no errors
4. `jq . .claude/settings.json` exits 0

## Proof Artifacts

- Log excerpt showing `[file-changed]`, `[cwd-changed]`, and task entries from a test session
- Synthetic-stdin test output for `stop-failure.sh` confirming the script runs
- Rendered `SKILL.md` covering all 5 agents

## Verify Before Proceeding

- [ ] Goal achieved: Are all 4 signal hooks logging, and is the `/loop` skill discoverable?
- [ ] Tests: T206, T207, T208, T209, T210 all pass
- [ ] Proof: Log excerpts captured; skill frontmatter validated
- [ ] No regressions: Phase 1 & 2 hooks and statusline all still fire correctly

---

# Phase 4: Docs

## Prerequisites

Phase 3 must be complete. You should have:
- `.claude/settings.json` with all new hook events wired
- All 6 new hook scripts present and logging
- `.claude/skills/loop-patterns/SKILL.md` present
- `.claude/statusline.sh` present

## Scope

Refresh `.claude/README.md` with documentation for all Claude Code features used in this spec, ship an optional "teaching" output style, and document sandbox hardening options.

## User Stories

### US11: Built-in commands leveraged section in README (Priority: P3)

**As a** downstream consumer of this config, **I want** `.claude/README.md` to surface the built-in Claude Code commands this config assumes or leverages **so that** I know what's available without reading the upstream docs.

**Acceptance Criteria:**
- Given `.claude/README.md`, when a user reads it, then there is a new "Built-in commands leveraged" section listing at minimum: `/context`, `/memory`, `/effort`, `/team-onboarding`, `/color`, `/tui`, `/loop`.
- Given the section, each command has a 1–2 sentence "what it does / when to use" note.
- Given the README, it notes the minimum Claude Code version (2.1.108) at the top.

**Proof Artifacts:**
- Rendered README section showing the 7 commands with descriptions — demonstrates FR-301

### US12: Optional teaching output style (Priority: P3)

**As a** user onboarding teammates to a codebase, **I want** an optional `teaching` output style **so that** I can switch Claude into a mode that narrates patterns and explains architectural choices while it codes.

**Acceptance Criteria:**
- Given `.claude/output-styles/teaching.md`, when Claude Code loads output styles, then this style is selectable.
- Given the style is active, the output includes (per the prompt) "plain-English narration of patterns being followed or departed from" on each non-trivial change.
- Given the file, it has valid frontmatter (`name`, `description`) per output-styles convention.

**Proof Artifacts:**
- Rendered `teaching.md` with frontmatter and 3–5 behavior clauses — demonstrates FR-302

### US13: Sandbox hardening docs (Priority: P3)

**As a** security-conscious consumer, **I want** documentation of `sandbox.network.deniedDomains` and `CLAUDE_CODE_NO_FLICKER` **so that** I can harden network access and tune terminal rendering.

**Acceptance Criteria:**
- Given `.claude/README.md`, when a user reads the new "Hardening options" section, then they see `sandbox.network.deniedDomains` with a 2–3 line example and `CLAUDE_CODE_NO_FLICKER` with a 1-line explanation.

**Proof Artifacts:**
- Rendered "Hardening options" section in README with both settings — demonstrates FR-303

## Functional Requirements

- **FR-301** [US11]: `.claude/README.md` MUST contain a "Built-in commands leveraged" section covering `/context`, `/memory`, `/effort`, `/team-onboarding`, `/color`, `/tui`, `/loop`.
- **FR-302** [US12]: `.claude/output-styles/teaching.md` MUST exist with valid frontmatter and instruct Claude to narrate patterns while coding.
- **FR-303** [US13]: `.claude/README.md` MUST document `sandbox.network.deniedDomains` and `CLAUDE_CODE_NO_FLICKER` in a "Hardening options" section.

## Non-Goals (This Phase)

1. No new features or hooks
2. No changes to existing skills or agents (teaching output style is new, not a skill edit)
3. No changes to the top-level `README.md` beyond mirroring if the user-facing table is affected (out of scope — stays in `.claude/README.md`)
4. No exhaustive docs for every Claude Code command — only the 7 we explicitly recommend

## Dependencies (verified 2026-04-19)

| Feature | Minimum Claude Code | Purpose | Docs Reference |
|---------|--------------------|---------|----------------|
| Output styles (`.claude/output-styles/`) | 2.1.74 | Custom response modes | https://code.claude.com/docs/en/output-styles.md |
| `sandbox.network.deniedDomains` setting | 2.1.113 | Network allowlist | settings.md — changelog 2026-04-17 |
| `CLAUDE_CODE_NO_FLICKER` env var | 2.1.89 | Terminal rendering tweak | env-vars.md — changelog 2026-04-01 |
| `/effort`, `/context`, `/memory`, `/team-onboarding`, `/color`, `/tui`, `/loop` | Various (all ≤ 2.1.108) | Built-in slash commands | commands.md |

## Reference Documentation

| Item | Shape | Notes |
|------|-------|-------|
| Output style frontmatter | `---\nname: teaching\ndescription: <1 line>\n---` | Body is a prompt that adjusts Claude's response style |
| Sandbox denied domains | `"sandbox": {"network": {"deniedDomains": ["evil.example.com"]}}` | Top-level settings.json key |
| `CLAUDE_CODE_NO_FLICKER` | env var `"1"` | Reduces terminal redraw on slow links |

## Implementation Guidance

**`.claude/output-styles/teaching.md`:**

```markdown
---
name: teaching
description: Narrate patterns and architectural choices while coding. Good for onboarding teammates or exploring unfamiliar codebases. Trades token cost for knowledge transfer.
---

# Teaching output style

When this style is active:

- Before each non-trivial edit, briefly state which existing pattern in the codebase the change follows (reference file:line if possible).
- When deviating from an established pattern, state the deviation and the reason in one sentence.
- Prefer naming the abstraction being used ("this is the standard repository pattern used in src/db/") over describing mechanics.
- Keep narration to 1–2 sentences per change — do not write paragraphs. Narration is a running commentary, not documentation.
- For trivial edits (typos, renames, formatting), narration is skipped.
- When finishing, summarize in one sentence what the reader has learned about this codebase from the session.
```

**README additions — "Built-in commands leveraged" section:**

```markdown
## Built-in commands leveraged

This config assumes the following native Claude Code commands are available. These are shipped by Claude Code itself, not by this repo.

| Command | When to use |
|---------|-------------|
| `/context` | Inspect what's loaded in your current context and where tokens are being spent |
| `/memory` | Inspect and edit auto-memory — see the "User-level setup" section above for where memory is stored |
| `/effort` | Switch between reasoning effort levels per task |
| `/team-onboarding` | Generate or refresh a team onboarding guide for this project |
| `/color` | Change session accent color (useful when running multiple sessions in parallel) |
| `/tui` | Toggle full-screen, flicker-free rendering |
| `/loop` | Run a prompt on a recurring or self-paced interval. See `.claude/skills/loop-patterns/SKILL.md` for per-agent recipes |
```

**README additions — "Hardening options" section:**

```markdown
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
```

## Tasks

- T301 [P] [US11] Append "Built-in commands leveraged" section to `.claude/README.md` per Implementation Guidance
- T302 [P] [US12] Create `.claude/output-styles/teaching.md` per Implementation Guidance
- T303 [P] [US13] Append "Hardening options" section to `.claude/README.md` per Implementation Guidance
- T304 [US11] Ensure the min-version note (2.1.108) from Phase 1 is still present and correctly references the top of the README (depends on T301, T303 if any reorganization happened)
- T305 [US12] Validate output style frontmatter: `head -4 .claude/output-styles/teaching.md | grep -E '^(name|description):'` returns both lines (depends on T302)

## Files to Create

- `.claude/output-styles/teaching.md`

## Files to Modify

- `.claude/README.md` — add "Built-in commands leveraged" and "Hardening options" sections

## Success Criteria

1. README has the 7-command table
2. README has the hardening options section
3. Output style file is present with valid frontmatter
4. All sections reference the correct min Claude Code version (2.1.108)

## Proof Artifacts

- Rendered README sections (visual inspection or `grep -A` snippets)
- Output-style file with frontmatter lines

## Verify Before Proceeding

- [ ] Goal achieved: Does the README cover all new commands/features, and is the teaching output style shippable?
- [ ] Tests: T305 passes; README section headings (`## Built-in commands leveraged`, `## Hardening options`) are findable via grep
- [ ] Proof: Rendered sections captured
- [ ] No regressions: All prior README content (setup, commands, skills tables) is still present

---

# Phase 5: Polish

## Prerequisites

All previous phases must be complete.

## Scope

Final cleanup pass — JSON validation, `shellcheck` across all hook scripts, executable-bit verification, end-to-end CLI smoke test in a fresh scratch directory, and top-level `README.md` updates if any user-facing feature tables reference changed content.

## Tasks

- T501 [P] Run `jq . .claude/settings.json` and verify exit 0
- T502 [P] Run `shellcheck .claude/hooks/*.sh .claude/statusline.sh` and fix any new issues flagged (pre-existing issues out of scope unless trivial)
- T503 [P] Verify all hook scripts are executable: `ls -l .claude/hooks/*.sh .claude/statusline.sh` — every file should show `x` bits for owner
- T504 Remove any TODO/debug comments accidentally introduced during Phases 1–4
- T505 Grep `.claude/README.md` for broken internal cross-references: `grep -oE '\.claude/[a-z/.-]+' .claude/README.md | sort -u` then verify each path exists
- T506 Review top-level `README.md`: does its "Hooks" or "Skills" table need updating to mention the new hooks (session-start, permission-denied, file-changed, cwd-changed, task-created, stop-failure) and new skill (`loop-patterns`)? If yes, update it to match `.claude/README.md` content. If no, leave untouched.
- T507 End-to-end CLI smoke test:
    1. Create a scratch dir: `mkdir -p /tmp/claude-scratch && cd /tmp/claude-scratch`
    2. Copy the config: `cp -r <repo>/.claude .`
    3. Set user-level env per README (skip if already set)
    4. Run `claude --version` and confirm it is ≥ 2.1.108
    5. Run `claude -p "echo smoketest"` non-interactively
    6. Check `.claude/.logs/hooks.log` contains `[session-start] START` and `OK: hook inventory complete`
    7. Check `.claude/.logs/hooks.log` does NOT contain `[validate-commit]` from the echo (confirms `if` routing worked)
    8. Clean up: `rm -rf /tmp/claude-scratch`
- T508 Collect all proof artifacts referenced by each phase's "Proof Artifacts" block into `.context/spec-proofs-claude-config-modernization.md` for durability
- T509 Update spec status: change frontmatter `status: draft` → `status: complete` after verification

## Success Criteria

1. `jq . .claude/settings.json` exits 0
2. `shellcheck` reports no new issues across all hook and statusline scripts
3. Every hook script and statusline is executable (`+x`)
4. End-to-end CLI smoke test (T507) passes every step
5. Top-level `README.md` is consistent with `.claude/README.md`
6. No TODO/debug artifacts remain
7. Spec status is marked complete

## Verify Before Proceeding

- [ ] Goal achieved: Is the config ready for downstream consumers to drop in and use?
- [ ] Tests: T501–T507 all pass
- [ ] Proof: `.context/spec-proofs-claude-config-modernization.md` contains captured artifacts
- [ ] No regressions: A consumer running through the README "Setup" steps reaches a working session without errors

---
