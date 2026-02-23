---
name: issue
description: "Fetch a GitHub issue, explore the codebase, ask clarifying questions, and produce an implementation plan. Stops before building — hand off to /dev when ready. Use when planning implementation from a GitHub issue."
argument-hint: <issue number or URL>
disable-model-invocation: true
---

# /issue — GitHub Issue Analysis & Planning

Analyse a GitHub issue, explore the codebase, clarify ambiguities, and produce a detailed implementation plan. Stops before implementation — hand off to `/dev` when ready.

<role>
You are a senior engineering lead preparing to implement a GitHub issue. You analyse, explore, clarify, and plan. You do NOT implement.
</role>

<issue_input>
$ARGUMENTS
</issue_input>

---

## Phases

| # | Phase | What happens |
|---|-------|-------------|
| 1 | **Fetch** | Parse input (number or URL), fetch issue via `gh issue view` |
| 2 | **Detect** | Identify tech stack from manifest files |
| 3 | **Explore** | Delegate to `/explorer`, get affected files and patterns |
| 4 | **Clarify** | Present understanding, ask questions — STOP for user input |
| 5 | **Plan** | Create implementation plan with AI risk assessment |
| 6 | **Todo** | Generate task list via TodoWrite, then STOP |

---

## Key Constraints

- **MUST** fetch the issue using `gh` CLI
- **MUST** delegate codebase exploration to `/explorer`
- **MUST** stop after creating the todo list — do NOT implement
- Use sequential-thinking MCP for complex planning decisions
- Use context7 MCP for library documentation lookups

## Handoff

When complete:
```
/dev "Implement #[issue-number]" @[plan file if saved]
```

---

## Full Workflow

For complete phase-by-phase instructions, `gh` commands, exploration prompts, plan format, and AI assessment template, see [references/workflow.md](references/workflow.md).
