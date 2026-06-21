---
name: team-orchestration
description: Team formation and orchestration patterns for Claude Code Agent Teams. Use when spawning agent teams, coordinating teammates, managing shared task lists, enforcing quality gates, running build loops with delegate mode, or choosing between FLAT, HIERARCHICAL, and COUNCIL team patterns.
---

# Team Orchestration

Patterns and protocols for forming and managing Claude Code Agent Teams.

<role>
You are a senior engineering lead who orchestrates agent teams. You coordinate work, assign tasks, synthesize results, and ensure quality. You NEVER implement code directly - you delegate everything to specialized teammates.

Enable delegate mode (Shift+Tab) to restrict yourself to coordination-only tools.
</role>

---

## Team Patterns

<team_patterns>
Choose the right pattern based on the task:

### FLAT Pattern
```
You (lead, delegate mode)
  ├── Explorer (read-only)
  ├── Implementer (full access)
  ├── Reviewer (read-only)
  └── QA (read-only + shell)
```
**When:** Single-domain features, bug fixes, refactors within one layer.
**Teammates:** 4. **Token cost:** Moderate.

### HIERARCHICAL Pattern
```
You (lead, delegate mode)
  ├── Explorer (read-only)
  ├── Backend Implementer (full access)
  ├── Frontend Implementer (full access)
  ├── Test Writer (full access)
  └── Reviewer (read-only)
```
**When:** Cross-layer features spanning backend + frontend + tests. Auto-detected by `/agent-team:dev`.
**Teammates:** 5. **Token cost:** Higher.
**Critical:** No two teammates edit the same file.

### COUNCIL Pattern
```
You (lead, normal mode)
  ├── Scout (read-only)
  ├── Researcher (read-only)
  ├── Challenger (read-only)
  ├── Blind Spot (read-only)
  └── Dependency Researcher (read-only)
```
**When:** Research, specification, code review, investigation.
**Teammates:** 2-5 (progressively spawned). **Token cost:** Lower (read-only).
**Lead mode:** Normal (NOT delegate) - lead converses with user and reads references.

For `/agent-team:discuss`, the COUNCIL pattern uses **progressive spawning** - teammates are
spawned and shut down as phases progress, rather than all at once. This keeps
resource usage low and avoids context pollution from stale teammates.

### Decision Matrix

| Task | Pattern | Why |
|------|---------|-----|
| Rough idea, "what if..." | Progressive COUNCIL (`/agent-team:discuss`) | Spawn/shutdown per phase during interview |
| Complex idea needing spec | Progressive COUNCIL (`/agent-team:discuss` + DEEPEN) | Adds dependency researcher, produces phased spec |
| Single-layer feature | FLAT (`/agent-team:dev`, auto-detected) | Simple coordination, lower cost |
| Fullstack feature (FE + BE) | HIERARCHICAL (`/agent-team:dev`, auto-detected) | Separate file ownership per layer |
| Bug with unclear cause | FLAT or COUNCIL | Competing hypotheses in parallel |
| Code review | COUNCIL | Multiple review lenses simultaneously |
| Simple bug fix | No team (subagent) | Team overhead exceeds benefit |

**Rule of thumb:** If the task takes < 10 minutes for one agent, use a subagent instead of a team. Subagents can spawn their own subagents (up to 5 levels deep, Claude Code 2.1.172+), so a single subagent can still delegate narrow lookups without team overhead.

**Two commands cover everything:**
- `/agent-team:discuss` - ideation, planning, and optional deep specs (COUNCIL)
- `/agent-team:dev` - implementation with auto-detected team shape (FLAT or HIERARCHICAL)
</team_patterns>

---

## Native Context Protocol

<native_context>
Teammates automatically receive project context through native Claude Code features. No manual file injection is needed.

### What Auto-Loads

| Feature | What It Provides | How |
|---------|-----------------|-----|
| `CLAUDE.md` | Project overview, tech stack, conventions | Auto-loaded at session start |
| `.claude/rules/` | Coding standards, git conventions, output formats | Auto-loaded for all sessions |
| Agent Skills | Domain knowledge (review-patterns, testing-patterns) | Auto-activated by task context |
| MCP Servers | Tool access (context7, browser, etc.) | Available to all teammates |
| `memory: project` | Persistent learnings from previous sessions | Loaded per-agent automatically |

### What This Means for Spawn Prompts

Spawn prompts should contain ONLY:
1. **Role assignment** - what this teammate does
2. **Full task spec** - complete description of the work
3. **Communication protocol** - who to message, when

Everything else (agent definition, skills, memory, rules, CLAUDE.md) loads automatically.
</native_context>

---

## Spawn Schemas

`/agent-team:dev` and `/agent-team:discuss` carry the **authoritative** spawn prompts inline (in
`dev/references/workflow.md` and `discuss/references/phases.md`) — when working
from those skills, follow theirs. For **ad-hoc** team spawning outside those
workflows, use the minimal reusable templates in
[references/spawn-schemas.md](references/spawn-schemas.md) (Explorer, Implementer,
Reviewer, QA, and the COUNCIL roles).

Spawn prompts contain only role + full task spec + communication protocol;
everything else loads automatically (see Native Context Protocol above).

---

## Communication Protocol

<communication_protocol>
### Direct Messaging (Preferred)

These messages go teammate-to-teammate, NOT through the lead:

| From | To | When |
|------|----|------|
| Reviewer | Implementer | Spec findings, code quality issues |
| QA | Implementer | Lint errors, test failures with file:line |
| Implementer | Reviewer | "Fixes applied, ready for re-review" |
| Test Writer | Implementer | "Need X exported for testing" |

### Lead Messages

These go to/from the lead:

| From | To | When |
|------|----|------|
| Any teammate | Lead | Task complete, blocker found, need scope change |
| Lead | Any teammate | New task assignment, scope clarification |
| Lead | User | Clarification needed, progress update |

### Broadcast (Use Sparingly)

Send to all teammates only for:
- Major scope change affecting everyone
- New constraint discovered
- Team-wide blocker

Token cost scales with team size. Prefer targeted messages.
</communication_protocol>

---

## Task Decomposition

<task_decomposition>
### Creating the Shared Task List

Break work into tasks that are:
- **Self-contained**: One deliverable per task (a function, a component, a test file)
- **Claimable**: Any teammate in the right role can pick it up
- **Verifiable**: Clear definition of done
- **Right-sized**: Not too small (coordination overhead) or too large (risk of waste)

### Guidelines

- Aim for 5-6 tasks per teammate
- Mark dependencies between tasks (blocked tasks can't be claimed)
- Assign domain labels so implementers self-claim from their domain
- Include review and QA tasks that depend on implementation tasks

### Example Task List

```
1. [backend] Implement auth middleware - depends on: none
2. [backend] Add user model and migration - depends on: none
3. [frontend] Create login form component - depends on: none
4. [frontend] Add auth context provider - depends on: 1
5. [testing] Write auth middleware tests - depends on: 1
6. [testing] Write login form tests - depends on: 3
7. [review] Review all implementation - depends on: 1,2,3,4
8. [qa] Run lint, typecheck, tests - depends on: 7
```
</task_decomposition>

---

## Quality Gates

<quality_gates>
A task is NOT complete until:

### Implementation Tasks
- [ ] Code changes are made
- [ ] Self-review checklist completed
- [ ] `<implementer-result>` block returned
- [ ] Reviewer messaged and confirmed COMPLIANT
- [ ] QA ran and all checks pass

### Review Tasks
- [ ] All requirements verified against actual code
- [ ] Scope creep check performed
- [ ] Code quality pass completed
- [ ] `<reviewer-result>` block returned
- [ ] Findings communicated directly to implementer

### QA Tasks
- [ ] Lint, typecheck, and tests all executed
- [ ] `<qa-result>` block returned
- [ ] Errors communicated directly to implementer
- [ ] Re-run after fixes confirms clean

### Team Completion
- [ ] All tasks marked complete
- [ ] Lead has synthesized results
- [ ] Discovered issues documented
- [ ] Team cleaned up
</quality_gates>

---

## Variance Reduction

<variance_reduction>
The #1 risk with agent teams is inconsistency. Reduce variance:

1. **Every teammate reads CLAUDE.md** - project context loads automatically
2. **Every teammate has project-scoped memory** - persistent learnings across sessions
3. **Skills auto-activate based on task context** - review-patterns and testing-patterns load when relevant
4. **Rules in `.claude/rules/` auto-load** - coding standards are consistent for all teammates
5. **Every teammate receives the FULL task spec** - not a summary, not a file reference
6. **Spawn prompts use the schemas above** - consistent role assignment
7. **Structured output blocks are required** - `<*-result>` format enforced
8. **Quality gates are non-negotiable** - hooks enforce completion criteria

The platform handles context injection. Spawn prompts focus on task and communication.
</variance_reduction>

---

## Delegate Mode

<delegate_mode>
After spawning your team, press Shift+Tab to enable delegate mode.

This restricts you to coordination-only tools:
- Spawning and shutting down teammates
- Sending and receiving messages
- Managing the task list

You CANNOT read files, write code, or run commands. This prevents the common failure mode where the lead starts implementing instead of coordinating.

If you need to check something, ask a teammate to check it for you.
</delegate_mode>

---

## Team Lifecycle

<lifecycle>
1. **Analyze** - Understand the task, choose a pattern
2. **Spawn** - Create teammates using schemas above
3. **Delegate** - Enable delegate mode, create task list
4. **Monitor** - Track progress, redirect as needed
5. **Synthesize** - Compile results from all teammates
6. **Cleanup** - Shut down all teammates (via `shutdown_request`), then call `TeamDelete`

Always shut down all teammates before running cleanup. Teammates should not run cleanup.
</lifecycle>

---

## Red Flags

When you catch yourself rationalizing your way out of delegation, review, process
discipline, or context-passing, check it against
[references/red-flags.md](references/red-flags.md) — the common orchestration
rationalizations and why each one is wrong. The cardinal rule: you coordinate,
you never code.
