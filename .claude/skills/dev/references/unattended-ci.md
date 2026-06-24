# /dev unattended — GitHub Actions wiring and CI constraints

How to run `/dev --unattended` headlessly from a GitHub Action (issue labeled `dispatch`),
and the CI-specific constraints verified empirically against `anthropics/claude-code-action@v1`.
The behavioral contract (which gates are suspended) lives in
[workflow.md → Unattended Mode](workflow.md#unattended-mode); this file is the CI plumbing.

## How the trigger works

The action boots the full Claude Code runtime inside the runner. `actions/checkout` makes
`.claude/` (skills, agents, rules, hooks) discoverable, so `/dev` resolves exactly as it does
locally. The workflow prompt just invokes it in unattended mode and passes the issue text:

```yaml
prompt: |
  Invoke /dev in unattended mode now and implement this GitHub issue end-to-end.
  Do not just describe it — execute it: delegate to the explorer/implementer/reviewer/qa
  sub-agents via the Task tool, run the build loop with the review and QA gates, and commit.

  Issue title: ${{ github.event.issue.title }}
  Issue body:
  ${{ github.event.issue.body }}
```

Unattended is signalled to `/dev` via env `DEV_UNATTENDED=1` (set in the job) and/or the
"unattended" wording in the prompt.

## Why native Task sub-agents (not Agent Teams or Workflow scripts)

Verified by spike (private `claude-dispatch-spike` repo, real CI runs):

- **Native Task path works headless, one level deep.** The Opus lead spawns `.claude/agents/*.md`
  sub-agents via the Task tool; each runs on its own `model:` frontmatter (a haiku sub-agent ran
  under an opus lead). Structured results return to the lead. This avoids the experimental Agent
  Teams non-terminating-turn failure mode (no force-kill; recovery is an interactive config edit
  that cannot run in CI). For CI, the lead should delegate via the **Task tool**, not Agent Teams.
- **Native nesting beyond one level is unreliable.** A sub-agent told to spawn its own sub-agent
  did NOT — it silently fabricated the expected child output. Keep delegation flat, one level.
- **The Workflow scripting runtime (the v2.1.x "5-level nesting" engine) is NOT usable in CI via
  the action.** Present in the environment but every invocation hits a `"Review dynamic workflow
  before running"` human-approval gate that cannot be cleared headlessly — `--permission-mode
  bypassPermissions` is forwarded but overridden by the action's own permission layer. Deep
  multi-tier orchestration is interactive-only.

## Required CI setup (or the run fails)

1. **Install the Claude GitHub App on the repo** — https://github.com/apps/claude. The `v1`
   action always does an App-token exchange (even with OAuth); without the App you get
   `401 ... Claude Code is not installed on this repository`. This is also why `id-token: write`
   is required in the workflow permissions.
2. **Auth secret** — `CLAUDE_CODE_OAUTH_TOKEN` (from `claude setup-token`, Pro/Max) as a repo
   secret. NOTE: subscription auth in unattended CI is a grey area under Anthropic's consumer
   terms; a metered `ANTHROPIC_API_KEY` is the unambiguous production path (swap the auth input).
3. **`--allowedTools` is mandatory.** On `issues` events the action runs in *tag mode*, which
   imposes a read-only allowlist with NO `Task`/`Bash`. The lead cannot spawn sub-agents unless
   the workflow passes `--allowedTools Task,Bash,Read,Write,Edit,Grep,Glob` in `claude_args`.
4. **Imperative prompt.** A bare `/dev` makes the model DESCRIBE the skill instead of running it.
   The workflow prompt must instruct it to invoke and execute now.

## Behavior to expect

- On `issues` events, tag mode **pushes the `claude/issue-<n>` branch and posts a "Create PR"
  link** in the issue comment — it does NOT auto-open the PR (that is a `pull_request`-event
  behavior). Click the link to open the PR.
- `branch_prefix: "claude/"` — the action appends `issue-<n>` itself. Do NOT use
  `branch_prefix: "claude/issue-"` or you get a doubled `claude/issue-issue-<n>` branch name.

## Known limitation: writes to `.claude/` are blocked

The action sandbox **denies writes under `.claude/`** (Edit/Write and Bash file-primitives,
including for delegated sub-agents) — `claude-code-action` injects its own runtime config
there and protects it. Writes to the repo root and `.context/` succeed; only `.claude/**` is
blocked. Observed on the issue-#13 dogfood run: the agent correctly produced the full change
set and exited `blocked` rather than routing around the denial.

Consequence: an issue whose target lives **entirely under `.claude/`** (e.g. editing a skill or
agent) cannot complete via this workflow — it will return a `blocked` result with the proposed
changes in a comment, which a human then applies. For self-edits to `.claude/`, apply the
agent's proposed changes manually (or in an interactive `/dev` session). The override path, if
you want to pursue it, is the action's `settings` input to relax the protected-path policy —
untested here; confirm with a spike before relying on it. Most dispatch targets (app/`src` code)
are unaffected.

## Caps (defense in depth)

- `--max-turns` — caps the LEAD's turns only (a sub-agent cannot be turn-capped from here).
- `--max-budget-usd` — independent spend cap across the whole run.
- workflow `timeout-minutes` — wall-clock backstop; the only hard stop for a runaway sub-agent.
