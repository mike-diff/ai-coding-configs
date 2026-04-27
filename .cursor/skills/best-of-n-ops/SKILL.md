---
name: best-of-n-ops
description: "Operational guidance for Cursor's /best-of-n command. Activates when running parallel model attempts and selecting the strongest result."
---

# /best-of-n — Parallel Model Selection

Guidance for using Cursor's parallel attempt feature to improve output quality.

## When to use

- Ambiguous requirements where multiple approaches are viable
- High-stakes code where correctness matters (security, data integrity)
- Creative tasks where solution diversity improves outcomes

## How it works

1. `/best-of-n` spawns N independent attempts at the same prompt
2. Each attempt runs in its own isolated worktree
3. Results are evaluated and the strongest is selected
4. Other attempts are discarded

## Best practices

- Use N=2–3 for most cases; higher N for critical paths
- Write clear evaluation criteria in the prompt
- Review the selected output before merging — selection is heuristic, not perfect
