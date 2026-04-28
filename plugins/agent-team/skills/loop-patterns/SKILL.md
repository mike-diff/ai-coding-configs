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
