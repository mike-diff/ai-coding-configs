# Decision Reference: /goal vs /loop

Detailed mechanics, the full classification matrix, and a worked example per
verdict. Load this when SKILL.md's tables are not enough to resolve a case.

## Command mechanics

### /goal <condition>

- Sets a completion condition. After **each turn**, a separate small **judge**
  model reads the transcript and returns `{"ok": true|false, "impossible"?: true, "reason": "..."}`.
- If `ok:false`, a Stop hook re-engages the working model for another turn.
- Ends when the judge returns `ok:true`, declares `impossible:true`, hits a
  **max-turns cap**, or the user runs `/goal clear`.
- **The judge sees ONLY the transcript.** It cannot run commands or read files,
  and it can be **spoofed** by a fabricated success string in the transcript.
- Runs **unattended** — no mid-run approval. Single continuous run; context grows.
- Requires a trusted workspace with hooks enabled. The condition string has a
  max character length.
- Best for: "keep working until X is objectively, **transcript-provably** true."

### /loop [interval] <prompt>

Two modes, chosen by the **first whitespace token**:

- **Interval mode** — `/loop 5m foo` (units `s/m/h/d`, pattern `^\d+[smhd]$`, or a
  trailing "every N minutes"). A session-scoped cron: fires on cadence, and also
  runs once immediately.
- **Self-paced mode** — `/loop foo` (no interval). The **model picks the delay
  each turn at runtime** (the harness clamps it; never pick the value that lands
  on the prompt-cache window). The model **ends the loop by omitting the next
  wakeup**.
- Loops **auto-expire after about a week**. Session-scoped: they die when the
  session closes.
- Best for: polling / watch-mode / cadence, or waiting on state that changes on
  its own (external) clock.

### Critical parsing fact

`/loop` reads the **first whitespace token** to choose mode. NEVER put a comment
or prose before the command: `/loop # note\n5m foo` silently misparses into
self-paced mode. Neither command has comment syntax; both take a raw arg string.
The emitted fenced block must contain **only** the literal command.

## Full classification matrix

| Question | Yes → | No → |
|---|---|---|
| Does it complete in one turn / need human judgment mid-run / is destructive-and-unsupervised? | NEITHER (Gate 0) | continue |
| Must it survive the session closing? | /schedule (not /loop) | continue |
| Is it cadence-driven OR does satisfying it require waiting on an external clock? | /loop | continue |
| Is there a verifiable end-state provable from the transcript alone? | /goal (run evidence-source check) | re-examine; likely NEITHER |
| Is there BOTH a terminal deliverable AND an ongoing watch clause? | SEQUENCE | single verdict |

## Evidence-source check (gate before any /goal)

| Source | Examples | Verdict | Action |
|---|---|---|---|
| Self-validating in-transcript | test runner pass/fail, a diff, grep count, a file written then re-read | safe | emit /goal |
| World-state relayed | deploy status, DB migrated, remote API behavior | fragile | require verbatim output + spot-check warning, or route to /loop / interactive |
| Unobservable from text | "looks clean", "feels fast", "code is good", "well-designed" | wrong | refuse /goal → NEITHER / interactive |

## Worked examples

### /goal — verifiable, in-transcript

> "Get `pnpm test` green on branch `fix/auth`."

Test runner output is self-validating in-transcript. Include a turn cap.

    /goal On branch fix/auth in repo ~/app, make `pnpm test` exit 0 with all suites passing; paste the final test summary. Done when the suite passes, or stop after 12 turns.

### /loop — external-clock precedence

> "Poll the CI build until it goes green."

There is an end-state ("green") but reaching it means **waiting on CI's clock** →
cadence wins. Self-paced, omit-wakeup on green:

    /loop Check the latest CI run for branch main in repo ~/app via `gh run list --branch main --limit 1`. If conclusion is success, report it and stop (omit the next wakeup). If failure, report and stop. If still running, wait and check again.

### SEQUENCE — terminal deliverable + maintenance

> "Get the test suite passing, then keep it green as new PRs merge today."

Two ordered blocks. Run block 1; when it ends, run block 2.

Block 1 (terminal, /goal):

    /goal In repo ~/app on branch main, make `pnpm test` pass with all suites green; paste the final summary. Done when the suite passes, or stop after 15 turns.

Block 2 (maintenance, /loop self-paced):

    /loop Watch repo ~/app branch main for newly merged PRs today. After each merge, run `pnpm test`; if it fails, report the failing suite and stop (omit the next wakeup). Otherwise wait and check again. Stop at end of day.

### Fragile /goal — world-state

> "Run until the deploy succeeded."

**Actor-vs-clock first:** the *agent* runs `./deploy.sh`, reads failures, fixes
them, and re-runs — the agent advances the work, nothing fires on an external
clock. So this is iterative convergence → **/goal**, NOT a /loop. (Contrast: "poll
a deploy pipeline *someone else triggered* until it finishes" — there the pipeline
advances on its own clock → /loop.)

It is a **fragile** /goal because the proof (deploy succeeded) is world-state the
transcript-only judge cannot verify and could be spoofed. Require verbatim output
and warn to spot-check (rationale and warning live outside the fence):

    /goal Deploy ~/app to staging via `./deploy.sh staging` and re-run it until it exits 0; paste the FULL verbatim final command output including the exit line. Done when output shows a clean exit 0, or stop after 8 turns.

### NEITHER — one-shot

> "Write a function that parses ISO dates."

Single turn. Just prompt normally — no /goal, no /loop.

### /schedule — survives session close

> "Poll the queue every 10 minutes, and it needs to keep running after I close my laptop."

/loop is session-scoped and dies on close. Route to /schedule.
