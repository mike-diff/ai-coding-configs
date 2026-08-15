# Maintenance & Drift Note

`/goal` and `/loop` are **built into the Claude Code binary**. Their exact
constants and parsing rules can change between versions. The decision logic in
this skill — not the numbers — is the durable part.

## What is durable (encode this)

- **The decision axis:** transcript-provable end-state → `/goal`; cadence or
  waiting-on-an-external-clock → `/loop`; both → SEQUENCE; one-shot / needs
  judgment / unobservable → NEITHER.
- **External-clock precedence:** when the work must wait on something that
  changes on its own schedule, cadence wins regardless of end-state.
- **The judge sees transcript only** and can be spoofed — so the evidence-source
  check (self-validating / world-state / unobservable) is load-bearing.
- **/loop parses the first whitespace token** to pick interval-vs-self-paced —
  so the fenced block must contain only the literal command.
- **/loop is session-scoped**; work that must survive the session belongs to
  `/schedule`.

## What is a drifting constant (soft-phrase; do not hardcode)

These live in the binary and have changed across versions. Refer to them
qualitatively in emitted prompts, never as load-bearing numbers:

- The `/goal` **max-turns cap** and the condition **max character length**.
- The `/loop` **auto-expiry** ("about a week").
- The self-paced **delay clamp** and the prompt-cache window value to avoid
  (do not pin 270 / 300 / 1200 / 3600 into a prompt — the model picks the delay
  at runtime within the clamp).
- The interval **unit set / regex** (`^\d+[smhd]$` today).

## Authoritative facts (from the official /goal doc, code.claude.com)

Confirmed in the docs as of v2.1.139+. These are the source of truth where they
conflict with anything inferred from the binary:

- **Judge model:** a small fast model, **defaults to Haiku**, configured per
  provider. It reads the conversation only and **does not call tools** — so the
  condition must be provable from what Claude surfaces in the transcript.
- **Effective condition** (official guidance, matches G1–G4): *one measurable end
  state* + *a stated check* ("`npm test` exits 0", "`git status` is clean") +
  *constraints that must not change* ("no other test file is modified"). Bound it
  with a turn/time clause (`or stop after 20 turns`).
- **Condition limit: 4,000 characters.** Generous — craft additions (proof
  artifact, side-effect guard, exit-code capture) fit comfortably; do not trim
  craft to save characters.
- **One goal per session;** setting a new one replaces the active one. Setting a
  goal starts a turn immediately (no separate prompt needed).
- **`/goal` is a session-scoped prompt-based Stop hook.** Requirements: a
  **trusted workspace**; unavailable if `disableAllHooks` (any level) or
  `allowManagedHooksOnly` (managed settings) is set — the command says why.
- **Resume:** an active goal restores on `--resume`/`--continue` (turn count,
  timer, token baseline reset); `/clear` removes it; an achieved/cleared goal is
  not restored.
- **Status:** `/goal` with no argument shows condition, elapsed time, turns,
  token spend, and the evaluator's most recent reason. `/goal clear`
  (aliases: `stop`, `off`, `reset`, `none`, `cancel`) clears early.
- **Comparison (authoritative):** next turn starts when the previous turn
  *finishes* (`/goal`, Stop hook) vs when a time *interval elapses* (`/loop`).
  Auto mode is complementary — it removes per-tool prompts; `/goal` removes
  per-turn prompts.

## Authoritative facts (from the official /loop doc, code.claude.com)

Confirmed in the docs (scheduled tasks require v2.1.72+):

- **Self-paced** delay is chosen each iteration between **1 minute and 1 hour**
  based on observed state; the delay + reason print at the end of each iteration.
- **Omitting the next wakeup ends the loop** when the task is provably complete
  (self-paced mode). Fixed-interval loops run until stopped or 7 days elapse.
- **Stop affordance:** press **`Esc`** while a loop waits to clear the pending
  wakeup. (Tasks scheduled by asking Claude directly are not affected by `Esc`;
  delete them by ID.) Use this in stewardship notes instead of vague "cancel it".
- **7-day expiry:** recurring tasks fire one last time then self-delete 7 days
  after creation. Durable scheduling = Routines (`/schedule`), Desktop tasks, or
  GitHub Actions.
- **Monitor tool / Channels** are the event-driven alternatives to a polling
  `/loop`: Monitor streams a background script's output (no polling); Channels let
  CI push an event into the session. Prefer these for watch-for-an-event tasks.
- **Jitter:** recurring tasks fire up to 30 min late (or half the interval for
  sub-hourly); pick a minute that is not `:00`/`:30` if exact timing matters.
- **`loop.md`** (`.claude/loop.md` then `~/.claude/loop.md`, ≤25,000 bytes) is the
  default prompt for a bare `/loop`; ignored when a prompt is supplied.
- **Bedrock / Vertex / Foundry:** no-interval `/loop` falls back to a fixed
  10-minute schedule (self-pacing and `loop.md` unavailable). Flag this if the
  environment is one of these.
- **Min interval 1 minute**; up to **50 tasks** per session;
  `CLAUDE_CODE_DISABLE_CRON=1` disables the scheduler and `/loop` entirely.

## How to maintain this skill

- If a constant changes, the **decision tables stay correct** — only the soft
  phrasing about bounds may need a touch-up. Resist hardcoding new numbers.
- If a **new mode or command** ships (e.g. a new autonomy primitive), add a row
  to Gate 0 / Gate 2 rather than rewriting the axis.
- Re-run `scripts/check-emission.sh` against sample emissions after any edit to
  the output-format rules.
