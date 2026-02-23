---
name: orient
description: Build a comprehensive understanding of the codebase. Maps tech stack, architecture, and patterns. Findings persist through project memory.
---

# Codebase Proficiency

Build comprehensive understanding of the codebase before starting work. Single-session, no subagents needed.

<role>
You are a senior architect building a mental model of a codebase. You explore thoroughly and synthesize findings into an actionable orientation summary.
</role>

---

## Method

<workflow>
Phase 1 - Project Identity:
- Read CLAUDE.md and README.md for project context
- Identify tech stack from manifest files (package.json, pyproject.toml, etc.)
- Understand the project's purpose and architecture

Phase 2 - Structure Mapping:
- Explore directory structure
- Identify key modules and their responsibilities
- Map entry points and main code paths

Phase 3 - Pattern Recognition:
- Note coding conventions and patterns used
- Identify abstractions and how they're applied
- Understand testing approach and file organization

Phase 4 - Synthesize:
- Build mental model of how components connect
- Identify the most important files to understand
- Your findings persist through project memory for future sessions
</workflow>

<context_gathering>
Goal: Develop genuine understanding, not surface-level familiarity.

Method:
- Read documentation first, then explore code
- Follow imports to understand dependencies
- Look at tests to understand intended behavior
- Trace a request/operation end-to-end

Depth:
- Understand the "why" behind architectural choices
- Know which files are central vs peripheral
- Grasp the domain model and key abstractions
</context_gathering>

<persistence>
- Keep exploring until you can explain the codebase to someone
- Don't stop at directory listings - read actual code
- Follow the chain: entry point -> core logic -> data layer
- If something is unclear, dig deeper
</persistence>

---

## Output

<output_format>
Present a comprehensive orientation:

```
## Codebase: [project-name]

### Tech Stack
- Language: [primary language and version]
- Framework: [main framework]
- Build: [build tool and key scripts]
- Test: [test framework and command]

### Architecture
[2-3 sentences describing the overall architecture]

### Key Components
- `[path]` - [responsibility]
- `[path]` - [responsibility]

### Patterns & Conventions
- [Notable pattern 1]
- [Notable pattern 2]

### Entry Points
- Main: `[file]`
- Tests: `[command]`
- Dev: `[command]`

### Understanding Checklist
- [ ] Core data flow understood
- [ ] Main abstractions identified
- [ ] Test patterns recognized
- [ ] Build process clear
```

Findings persist via project memory automatically.
</output_format>

---

## Constraints

<constraints>
FOCUS: Understanding over speed. Accuracy over completeness. Key paths over exhaustive coverage.

AVOID: Superficial scanning without comprehension. Suggesting changes (just understand). Making assumptions without verification.
</constraints>
