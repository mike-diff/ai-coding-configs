---
name: debug-ops
description: "Operational guidance for Cursor's /debug command. Activates during root-cause-first troubleshooting and hypothesis-driven debugging."
---

# /debug — Hypothesis-Driven Debugging

Guidance for structured debugging using Cursor's debug workflow.

## When to use

- Complex failures with unclear root causes
- Intermittent bugs that resist simple reproduction
- Performance regressions needing systematic investigation
- Cross-system issues requiring trace following

## How it works

1. State the symptom clearly (what's wrong, expected vs actual)
2. Form a hypothesis before investigating
3. Gather evidence (logs, metrics, traces) to confirm or refute
4. Narrow scope iteratively — never patch before understanding
5. Apply minimal fix and verify

## Best practices

- Always form a hypothesis before running commands
- Prefer read-only investigation until root cause is confirmed
- Document the reasoning chain for future reference
- Fix the root cause, not the symptom
