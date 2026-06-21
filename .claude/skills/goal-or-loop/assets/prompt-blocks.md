# Prompt Block Skeletons

Fill in the `[BRACKETS]` inline. The fenced block must contain ONLY the literal
command. Rationale goes ABOVE the fence; the stewardship note goes BELOW it.

The craft of the emitted command IS the product. A `/goal` whose condition the
transcript-only judge cannot confirm loops to its turn cap; a `/loop` with no real
stop runs until it auto-expires. Apply the craft requirements below, not just the
shape.

## Craft requirements

### /goal — the condition is read by a SEPARATE small judge model that sees only the transcript

- **G1 — one literal success predicate.** Quote the exact command and the exact
  pass string/exit, e.g. `` `pnpm test` exits 0 with 0 failures ``. Never "tests
  work" / "it passes". The judge pattern-matches transcript text.
- **G2 — name the proof artifact** the working model must surface into the
  transcript (e.g. "paste the final test summary", "paste the `tsc --noEmit`
  output", "show the grep count"). If the proof never enters the transcript the
  judge can never return `ok:true` and the goal burns turns to the cap.
- **G3 — side-effect guard** whenever the task mutates code (e.g. "and no test
  file is modified", "and nothing outside `src/` changes"). Without it the goal
  can be "met" by cheating (deleting the test, editing the assertion).
- **G4 — right-size the turn cap.** Small mechanical task ≈ 6–10 turns; multi-file
  migration ≈ 15–25. The cap is the only backstop against an unmeetable condition;
  do not paste a fixed default.
- **G5 — self-contained.** Repo / branch / paths inline.

### /loop — each tick re-reads fresh and the model self-paces unless you pin an interval

- **L1 — match the cadence.** Fixed external rhythm → put the real interval first
  (`5m`). Unknown/reactive rhythm → self-pace (no interval); don't invent a number.
- **L2 — one idempotent action per tick, with the exact command** to run.
- **L3 — explicit stop / omit-the-next-wakeup condition.**
- **L4 — a hard bound** beyond the ~1-week auto-expiry when open-ended ("stop at
  end of day", "after 20 checks").
- **L5 — self-contained.**

---

## /goal — verifiable end-state, provable in-transcript

Rationale (above fence): "[OBJECTIVE] has a literal, transcript-provable
done-signal ([EXACT COMMAND + PASS STRING]) and no external-clock wait → /goal."

    /goal In repo [REPO] on branch [BRANCH], [OBJECTIVE]. Run [EXACT COMMAND] and paste its final [PROOF ARTIFACT] into the transcript. Done when [EXACT COMMAND] shows [LITERAL PASS STRING/EXIT] and [SIDE-EFFECT GUARD, e.g. no test file is modified], or stop after [SIZED N] turns.

Stewardship (below fence): "Runs turn-after-turn unattended until the judge
confirms from the transcript or it hits the [N]-turn cap — context grows each
turn. Stop early with `/goal clear`. Check progress by running `/goal`."

---

## /loop cron — fixed cadence given

Rationale (above fence): "This is cadence-driven on a fixed [INTERVAL] → /loop
with an interval."

    /loop [INTERVAL e.g. 5m] In repo [REPO], [ONE IDEMPOTENT ACTION with EXACT COMMAND]. If [DONE/EVENT], report it and stop the loop. [HARD BOUND if open-ended].

Stewardship (below fence): "Fires every [INTERVAL] (and once immediately),
session-scoped — it dies when you close this session and auto-expires after about
a week. Each fire costs tokens. Stop it by pressing Esc while it waits, or closing the
session."

---

## /loop self-paced — waiting on an external clock / unknown cadence

Rationale (above fence): "Reaching the end-state means waiting on [EXTERNAL CLOCK,
e.g. CI / a deploy] whose timing is unknown, so cadence wins → self-paced /loop."

    /loop In repo [REPO], [WHAT TO CHECK with the EXACT COMMAND, self-contained]. If [DONE CONDITION], report and stop (omit the next wakeup). If [FAILURE], report and stop. Otherwise report status and wait for the next tick. [HARD BOUND, e.g. stop at end of day].

Note: "omit the next wakeup" = STOP. Use it ONLY on terminal branches (done /
failure). The keep-going branch must say "wait for the next tick", never "omit the
wakeup and check again" — that would end the loop instead of continuing it.

Stewardship (below fence): "Self-paces — the model picks the delay each turn
(clamped by the runtime) and ends by omitting the next wakeup. Session-scoped
(dies on close), auto-expires after about a week; each check costs tokens. Stop
it by pressing Esc while it waits, or closing the session."

Do NOT pin a second-level delay constant into the prompt; the model picks it at
runtime within the tool's clamp.

---

## SEQUENCE — terminal deliverable + ongoing watch

Note (above blocks): "Run block 1; when it ends, run block 2."

Block 1 (terminal, /goal):

    /goal In repo [REPO] on branch [BRANCH], [TERMINAL OBJECTIVE]. Run [EXACT COMMAND] and paste its final [PROOF ARTIFACT]. Done when [LITERAL PASS STRING] and [SIDE-EFFECT GUARD], or stop after [SIZED N] turns.

Block 2 (maintenance, /loop):

    /loop In repo [REPO], [WATCH OBJECTIVE with EXACT COMMAND, self-contained]. If [REGRESSION], report and stop (omit the next wakeup). Otherwise report status and wait for the next tick. [HARD BOUND].

Stewardship (below blocks): "Block 1 ends on verify or its turn cap; stop it with
`/goal clear`. Block 2 is session-scoped, costs tokens per check, and auto-expires
after about a week; stop it by pressing Esc while it waits, or closing the session."

---

## Fragile /goal — world-state relayed

Rationale (above fence): "The done-signal is world-state ([WHAT]) the judge can't
verify from the transcript and could be spoofed, so this /goal is FRAGILE — it
requires verbatim output and a spot-check."

    /goal [OBJECTIVE] via [EXACT COMMAND]; re-run it until it exits 0 and paste the FULL verbatim final command output including the exit/status line. Done when the output shows [LITERAL CLEAN RESULT incl. exit 0], or stop after [SIZED N] turns.

Stewardship (below fence): "WARNING: the judge only reads the transcript and can
be spoofed by a fabricated success line — spot-check the real [WORLD STATE]
yourself. Runs unattended until verify or the [N]-turn cap; stop with `/goal
clear`."
