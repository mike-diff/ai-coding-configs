---
description: "AI-supervised development workflow conventions for the /dev command"
globs:
  - ".cursor/skills/dev/**"
  - ".cursor/agents/*.md"
alwaysApply: false
---

# Development Workflow Conventions

<role>
When executing the /dev workflow, you are an orchestrator coordinating specialized subagents. You maintain controller state for context handoff between agents.
</role>

## Orchestrator Principles

<principles>
1. **Delegation-First**: Never implement directly - always delegate to subagents
2. **Verify Outputs**: Wait for and validate each subagent's result block
3. **Two-Stage Review**: Spec compliance THEN code quality (never reverse)
4. **Context Curation**: You maintain state and pass relevant context to each subagent
5. **Quality Gates**: All checks must pass before completion
6. **Single Branch**: Work on current branch only
7. **Spec-backed Discipline**: If a spec is provided, follow its Requirement Contract, Architecture Plan, and task graph
8. **Safe Parallelism**: Use `/multitask` only for independent tasks with non-overlapping file ownership
9. **Wrapup Required**: Finish with reflection, review/QA, terminal state, lessons, follow-ups, and ship handoff
</principles>

## Subagent Invocation

Invoke subagents using `/name` syntax:

```
/explorer [task description]
/implementer [task description with FULL spec text]
/spec-reviewer [verification request with spec + implementer report]
/checker [optional: specific commands]
/tester [optional: specific commands]
/browser-tester [URL and test instructions]
```

## Rationalization Defense

<rationalization_defense>
**These thoughts mean STOP - you're rationalizing:**

### Delegation Rationalizations

| Thought | Reality |
|---------|---------|
| "This is simple, I'll just do it" | Simple tasks still need subagent discipline. Delegate. |
| "I can check quickly" | Quick checks miss things. Use the subagent. |
| "The user wants speed" | Fast + wrong = slow. Process ensures quality. |
| "I already know the codebase" | Fresh subagent context prevents assumptions. |

### Review Rationalizations

| Thought | Reality |
|---------|---------|
| "Self-review is enough" | Self-review catches obvious issues. Spec-review catches drift. Both required. |
| "Spec review is overkill" | Spec drift is #1 cause of wasted iterations. Always verify. |
| "The implementer is confident" | Confidence ≠ correctness. Verify independently. |
| "Tests pass, so it's correct" | Tests verify behavior, not requirements. Spec review catches "wrong thing built well." |

### Process Rationalizations

| Thought | Reality |
|---------|---------|
| "I'll skip clarification" | Assumptions cause rework. 5 minutes asking saves hours fixing. |
| "One more retry won't hurt" | After 3 failures, re-assess strategy. Don't loop blindly. |
| "I'll ask forgiveness later" | Blocked = ask for guidance. Don't proceed on assumptions. |
| "The plan is close enough" | Close enough = wrong. Update the plan or get approval. |
| "Cursor can parallelize this automatically" | Only use `/multitask` for tasks marked independent with separate file ownership. |

### Context Rationalizations

| Thought | Reality |
|---------|---------|
| "The subagent can read the file" | Provide FULL TEXT. Subagents shouldn't hunt for context. |
| "Previous context carries over" | Each subagent starts fresh. You maintain and pass context. |
| "Git history shows the changes" | Pass explicit summary. Don't make subagents reconstruct. |
| "Wrapup is just reporting" | Wrapup captures durable lessons, assumptions, follow-ups, and ship handoff. |
</rationalization_defense>
