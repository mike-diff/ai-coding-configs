---
name: goal-or-loop
description: "Decides between the Claude Code /goal and /loop commands for a rough task, then emits a copy-paste-ready command block. Use when the mechanism is NOT yet chosen, for asks like should I use /goal or /loop, is this a goal or a loop, what is the best way to run this until it is done, set this up to run autonomously until X, or keep working on this unattended until it converges. Picks /goal (verifiable end-state provable from the transcript), /loop (cadence or waiting on an external clock), BOTH in sequence (terminal deliverable plus ongoing watch), or NEITHER (one-shot, needs human judgment, or unobservable). Triggers on keywords goal, loop, autonomously, until done, unattended, converge. Does NOT claim plain set up a recurring task / cron / poll every N minutes (that is loop-patterns) or schedule work that survives the session (that is schedule); and does NOT fire once the user has already typed /loop or /goal."
compatibility: "Designed for Claude Code"
---

# Goal or Loop

Pick the right autonomy primitive for a task, then hand back a command the user
can paste cold into a fresh session.

`/goal` and `/loop` look interchangeable ("run this until it's done") but fail in
opposite ways when mismatched. This skill teaches the decision, not the constants.

## When to Use This Skill

Use this skill when the user has a task they want to run autonomously but has
**not yet chosen the mechanism** and asks things like:

- "Should I use /goal or /loop for this?"
- "Is this a goal or a loop?"
- "What's the best way to run this until it's done / until it converges?"
- "Set this up to run autonomously / unattended until X is true."
- "Keep working on this until done."

Do **not** use this skill when:

- The user already typed `/loop` or `/goal` (the choice is made — help them with that command directly).
- The ask is plainly "set up a recurring task / poll every N min / watch-mode" → that is the `loop-patterns` skill.
- The ask is "schedule a task that survives the session closing / runs in the cloud" → that is the `schedule` skill (`/schedule`).

## The Two Commands (what makes them differ)

| | `/goal <condition>` | `/loop [interval] <prompt>` |
|---|---|---|
| Core idea | Work turn-after-turn until a condition **verifies** | Run a prompt on a **cadence**, or wait on an **external clock** |
| Who decides "done" | A separate small **judge** model reads the transcript each turn | Cadence fires, or the model **omits the next wakeup** to stop |
| What the judge can see | **Transcript text only** — cannot run commands or read files; can be **spoofed** by a fabricated success string | n/a |
| Run shape | Single continuous run, context grows; runs **unattended**, no mid-run approval | Interval mode = session cron; self-paced = model picks delay at runtime |
| Lifetime | Ends on verify / impossible / max-turns cap / `/goal clear` | Session-scoped (dies when session closes); auto-expires after about a week |
| Best for | "Keep going until X is objectively, **transcript-provably** true" | Polling / watch-mode / waiting on something that changes on its own clock |

Full mechanics and the constants that can drift: see [decision-table.md](references/decision-table.md)
and the drift note in [maintenance.md](references/maintenance.md).

## The Decision Procedure

Run the gates in order. Stop at the first one that resolves.

### Gate 0 — Does this even need autonomy?

Recommend **NEITHER** and name the better primitive when the task:

| Situation | Better primitive |
|---|---|
| Completes in a single turn / one-shot | Just prompt normally |
| Needs human judgment mid-run | Plan mode, or interactive work |
| Is a bounded delegate-and-return job | A subagent |
| Is cadence work that must **survive the session ending** | `/schedule` (not `/loop`) |
| Is destructive AND would run unsupervised | Interactive work with approval |
| Is **watching for an event** that can be streamed/pushed (a log line, a CI result) | the **Monitor tool** (streams output, no polling) or **Channels** (CI pushes the event in) — often more token-efficient than a polling `/loop` |

Do not force a fit. A function to write, a question to answer, a refactor you'll
review as it goes — none of these want `/goal` or `/loop`.

**Before recommending `/goal`, note its requirements** (it is a session-scoped
Stop hook): a **trusted workspace**, and hooks must be enabled — `/goal` is
unavailable if `disableAllHooks` (any settings level) or `allowManagedHooksOnly`
(managed settings) is set. If you know the environment blocks hooks (e.g. a
locked-down/CI/managed setup), say so and prefer `/loop` or a manual approach.

### Gate 1 — Adaptive interview (only when underspecified)

If the input already names a clear **done-signal** or a **cadence**, skip this gate.

Otherwise ask a short batch (max ~3 questions) covering only the gaps:

- What is the objective, concretely?
- What is the done-signal (or the cadence)?
- Will you keep this session open? (session-scoped vs survives-close)
- Does it mutate state — writes, deletes, deploys?

Ask only what is missing. Do not interrogate a well-specified task.

### Gate 2 — Classify

| The task is... | Verdict |
|---|---|
| A verifiable end-state, provable **from the transcript alone**, no waiting on an external clock | **/goal** |
| Cadence-driven, OR satisfying it requires **waiting on an external clock** (even if a clean end-state exists) | **/loop** |
| Has BOTH a terminal deliverable AND an ongoing watch/maintenance clause | **SEQUENCE** (/goal then /loop) |

**External-clock precedence:** when the work must wait on something that changes
on its own schedule, cadence wins regardless of end-state. "Poll the build until
it goes green" has an end-state ("green") but you are **waiting on CI's clock** →
that is `/loop`, not `/goal`.

**Actor-vs-clock test (apply before invoking external-clock precedence).** Ask:
*who makes progress between ticks — an external system, or the agent?*

- **External system advances it** (CI is compiling, a deploy pipeline you don't
  control is rolling out, a queue drains itself) → genuine external clock → `/loop`.
- **The agent advances it** (the agent itself runs `./deploy.sh`, reads the
  failure, fixes it, re-runs) → there is **no external clock**; this is iterative
  convergence → `/goal` (fragile if the proof is world-state). "Run until the
  deploy succeeds" where the agent runs the deploy is a **fragile /goal**, not a
  /loop — the agent is the actor, not a waiter. Do not mislabel agent-driven
  retry-and-fix as external-clock waiting.

### Evidence-source check — gate before emitting ANY /goal

Classify how the done-condition would be **proven**:

| Evidence source | Example | Verdict |
|---|---|---|
| Self-validating in-transcript | test runner pass/fail, a diff, a grep count, a file the model wrote then re-read | `/goal` is **safe** |
| World-state relayed | deploy status, DB migrated, remote API behavior | `/goal` is **fragile** — the judge cannot verify and can be spoofed |
| Unobservable from text | "looks clean", "feels fast", "code is good" | `/goal` is **wrong** |

- **Fragile** → require the condition to include **verbatim command output**, and warn the user to **spot-check**. (Or route to `/loop` / interactive.)
- **Wrong** → refuse `/goal`. Route to NEITHER / interactive work and say why.

## Output Format (strict)

Emit exactly this shape. The fence must be self-contained and paste-cold-ready.

1. **Rationale** — 1-2 lines, plain text, **above** the fence. Name the pick and why. NEVER an in-band comment. Do not restate the command in prose above the fence, and do not write two rationale blocks — one tight reason, then the fence. (The craft lives *inside* the condition, not in a longer preamble.)
2. **Fenced block** — the **literal command ONLY**. No comments, no prose, no `#` line, nothing else inside the fence.
3. **Stewardship note** — plain text, **below** the fence: how it terminates, how to **stop** it, where to see it is still running, and its cost/duration **shape** qualitatively (no fabricated dollar figures).

For a **SEQUENCE**, emit two ordered fenced blocks with a plain-text note:
"run block 1; when it ends, run block 2."

Copy-paste skeletons for each verdict: [prompt-blocks.md](assets/prompt-blocks.md).
Validate any emission against the hard rules: run `scripts/check-emission.sh`.

### Rules the fenced block MUST obey

- **The block contains ONLY the literal command.** `/loop` reads the **first whitespace token** to choose interval-vs-self-paced; a leading comment (`/loop # note\n5m foo`) silently misparses into self-paced mode. Neither command has comment syntax. Put nothing before or inside the command.
- **Self-contained.** Name the repo / branch / files / acceptance criteria **inline**. Never "the X we discussed" — it must work pasted into a fresh session.
- **Do not encode second-level timing constants** (e.g. 270 / 300 / 1200 / 3600) in a self-paced prompt — the model picks the delay at runtime within the tool's clamp.

### Craft checklist — what makes the emitted command PERFORM

The condition/prompt quality is the product. A weak one wastes the whole run.

**/goal** (a separate small judge reads **only the transcript** each turn):

- **Literal success predicate** — quote the exact command + exact pass string/exit (`` `pnpm test` exits 0 with 0 failures ``), never "it works".
- **Proof artifact** — tell the working model what to **paste into the transcript** (test summary, `tsc` output, grep count). No surfaced proof → the judge can never confirm → burns turns to the cap.
- **Side-effect guard** — when the task mutates code, add "and no test file is modified" / "nothing outside `src/` changes" so it can't be met by cheating.
- **Right-sized turn cap** — mechanical ≈ 6–10, multi-file migration ≈ 15–25. Not a fixed default.

**/loop** (each tick re-reads fresh):

- **Cadence** — pin an interval ONLY when the user states one ("every 5 minutes") or there is a true fixed external rhythm. When the loop should **stop the instant a state resolves** (poll CI until it's done, watch for an event), **self-pace** — do not invent an interval; a fixed clock just polls a resolved state. Default to self-pacing when unsure.
- **One idempotent action per tick, with the exact command.**
- **Explicit stop / omit-the-next-wakeup condition** — the #1 cause of zombie loops is no exit. **Omitting the wakeup MEANS stop** — only use "omit the next wakeup" on the *done/terminal* branch. The *keep-going* branch must say "report and wait for the next tick", never "omit the wakeup and check again" (self-contradictory — it would end the loop).
- **Hard bound** beyond the ~1-week auto-expiry when open-ended ("stop at end of day", "after 20 checks").

Full skeletons per verdict: [prompt-blocks.md](assets/prompt-blocks.md).

## Red Flags — STOP Immediately

<rationalization_defense>
| Thought | Reality |
|---|---|
| "It says 'until it's good' — I'll set a /goal." | Unobservable from text. The judge sees transcript only and will loop forever or be spoofed. Refuse → NEITHER. |
| "It has an end-state ('until green'), so /goal." | If reaching it means **waiting on an external clock** (CI, a deploy), cadence wins. Use /loop. |
| "I'll drop a `# poll every 5m` comment in the block so it's clear." | `/loop` parses the first token; a leading comment misparses it into self-paced mode. Rationale goes ABOVE the fence, never inside. |
| "I'll reference 'the tests we discussed' to keep it short." | The block must paste cold into a fresh session. Name files/branch/criteria inline. |
| "The deploy goal is fine, the judge will read the output." | World-state is relayed, not verified — spoofable. Require verbatim output + a spot-check warning, or route away. |
| "They want it recurring forever, so /loop." | If it must survive the session closing, /loop dies with the session. Route to /schedule. |
| "This one-liner should run as a /goal to be safe." | One-shot tasks need neither. Just prompt normally. Don't force a fit. |
| "I'll skip the stop note, they'll figure it out." | Every emission needs a stop/status affordance outside the fence — unattended runs are hard to kill blind. |
</rationalization_defense>

## Resources

- [decision-table.md](references/decision-table.md) — full mechanics of both commands, the classification matrix, and worked examples per verdict.
- [maintenance.md](references/maintenance.md) — drift note: `/goal` and `/loop` are built into the Claude Code binary; their constants and parsing can change between versions. The decision logic is the durable part.
- [prompt-blocks.md](assets/prompt-blocks.md) — fill-in skeletons for /goal, /loop cron, /loop self-paced, and sequence.
- `scripts/check-emission.sh` — asserts a candidate emission obeys the hard rules (fence holds only the command, /loop interval is first token, stop affordance present).
