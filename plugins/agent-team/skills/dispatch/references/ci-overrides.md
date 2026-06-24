# /agent-team:dispatch — CI overrides and hard-won constraints

`/agent-team:dispatch` is `/agent-team:dev` adapted for an unattended GitHub Actions run. This file records the
deltas from interactive `/agent-team:dev` and the CI-specific constraints that were verified empirically
against `anthropics/claude-code-action@v1`.

## Deltas from interactive /agent-team:dev

| /agent-team:dev (interactive) | /agent-team:dispatch (CI) |
|---|---|
| Phase 3 "Clarify — STOP for user input" | SUSPENDED. Infer simplest interpretation, log under Assumptions, proceed. |
| Phase 6 Reflect "Questions for User" STOP | SUSPENDED. Reflection becomes a PR-body note, never a gate. |
| Halt waits for the user | Halt = comment the blocker + clean tree + terminal state `blocked`. Never wait. |
| User can kill a hung teammate | No force-kill; the job `timeout-minutes` is the only hard stop. Keep tasks small. |
| Agent Teams (`TaskCreate`, delegate mode, `shutdown_request`, `TeamDelete`) | Native **Task tool** sub-agents. No team lifecycle, no force-kill gap. |

## Why native Task sub-agents, not Agent Teams or Workflow scripts

Verified by spike (private `claude-dispatch-spike` repo, runs in CI):

- **Native Task path works headless, one level deep.** The Opus lead spawns `.claude/agents/*.md`
  sub-agents via the Task tool; each runs on its own `model:` frontmatter (a haiku sub-agent ran
  under an opus lead). Structured results return to the lead. This is the documented,
  headless-safe path and avoids the experimental Agent Teams non-terminating-turn failure mode
  (no force-kill; recovery is an interactive config edit that cannot run in CI).
- **Native nesting beyond one level is unreliable.** A sub-agent told to spawn its own
  sub-agent did NOT — it silently fabricated the expected child output (no proof of execution).
  Keep all delegation flat, one level. Do not design `/agent-team:dispatch` around deep nesting.
- **The Workflow scripting runtime (the v2.1.x "5-level nesting" engine) is NOT usable in CI
  via the action.** It is present in the environment but every invocation (scriptPath and inline)
  hits a `"Review dynamic workflow before running"` human-approval gate that cannot be cleared
  headlessly — `--permission-mode bypassPermissions` is forwarded but overridden by the action's
  own permission layer. Deep multi-tier orchestration is interactive-only.

## Required CI setup (or the run fails)

1. **Install the Claude GitHub App on the repo** — https://github.com/apps/claude. The `v1`
   action always does an App-token exchange (even with OAuth); without the App you get
   `401 ... Claude Code is not installed on this repository`. This is also why `id-token: write`
   is required in the workflow permissions.
2. **Auth secret** — `CLAUDE_CODE_OAUTH_TOKEN` (from `claude setup-token`, Pro/Max) as a repo
   secret. NOTE: subscription auth in unattended CI is a grey area under Anthropic's consumer
   terms; a metered `ANTHROPIC_API_KEY` is the unambiguous production path.
3. **`--allowedTools` is mandatory.** On `issues` events the action runs in *tag mode*, which
   imposes a read-only allowlist with NO `Task`/`Bash`. The lead cannot spawn sub-agents unless
   the workflow passes `--allowedTools Task,Bash,Read,Write,Edit,Grep,Glob` in `claude_args`.
4. **Imperative prompt.** A bare `/agent-team:dispatch` makes the model DESCRIBE the skill instead of
   running it. The workflow prompt must instruct it to invoke and execute the skill now.

## Behavior to expect

- On `issues` events, tag mode **pushes the `claude/issue-<n>` branch and posts a "Create PR"
  link** in the issue comment — it does NOT auto-open the PR (that is a `pull_request`-event
  behavior). Click the link to open the PR.
- `branch_prefix: "claude/"` — the action appends `issue-<n>` itself. Do NOT use
  `branch_prefix: "claude/issue-"` or you get a doubled `claude/issue-issue-<n>` branch name.

## Caps (defense in depth)

- `--max-turns` — caps the LEAD's turns only (a sub-agent cannot be turn-capped from here).
- `--max-budget-usd` — independent spend cap across the whole run.
- workflow `timeout-minutes` — wall-clock backstop; the only hard stop for a runaway sub-agent.
