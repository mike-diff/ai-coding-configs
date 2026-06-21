# Red Flags — Orchestration Rationalizations

When you catch yourself thinking the left column, the right column is the reality.

## Delegation

| Thought | Reality |
|---------|---------|
| "I'll just do this one thing myself" | Enable delegate mode. You coordinate, never code. |
| "This is simple, I'll just do it" | Simple tasks still need subagent discipline. Delegate. |
| "This teammate is slow, I'll help" | Message them with guidance. Don't take over. |
| "I can check quickly without a teammate" | Quick checks miss things. Use the teammate. |
| "The user wants speed" | Fast + wrong = slow. Process ensures quality. |
| "I already know the codebase" | Fresh teammate context prevents assumptions. |

## Review

| Thought | Reality |
|---------|---------|
| "I'll skip the reviewer, tests pass" | Tests verify behavior, not requirements. Review is required. |
| "Self-review is enough" | Self-review catches obvious issues. Spec-review catches drift. Both required. |
| "Spec review is overkill" | Spec drift is the #1 cause of wasted iterations. Always verify. |
| "The implementer is confident" | Confidence != correctness. Verify independently. |
| "Tests pass, so it's correct" | Tests verify behavior, not requirements. Spec review catches "wrong thing built well." |

## Process

| Thought | Reality |
|---------|---------|
| "I'll skip clarification, it's obvious" | Assumptions cause rework. 5 minutes asking saves hours fixing. |
| "One big task is easier" | Small tasks enable parallelism and reduce waste. |
| "One more retry won't hurt" | After 3 failures, re-assess strategy. Don't loop blindly. |
| "I'll ask forgiveness later" | Blocked = ask for guidance. Don't proceed on assumptions. |
| "The plan is close enough" | Close enough = wrong. Update the plan or get approval. |

## Context

| Thought | Reality |
|---------|---------|
| "I'll broadcast this update" | Broadcast costs tokens per teammate. Use targeted messages. |
| "The teammate can read the file" | Provide FULL TEXT. Teammates start with clean context and shouldn't hunt for it. |
| "Previous context carries over" | Each teammate starts fresh. You maintain and pass context. |
| "Git history shows the changes" | Pass explicit summary. Don't make teammates reconstruct context. |
