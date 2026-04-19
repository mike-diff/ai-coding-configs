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
