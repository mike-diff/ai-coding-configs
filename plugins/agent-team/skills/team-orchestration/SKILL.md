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

**Rule of thumb:** If the task takes < 10 minutes for one agent, use a subagent instead of a team.

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
| Agent Skills | Domain knowledge (code-review, testing-patterns) | Auto-activated by task context |
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

> **Canonical source:** These are the minimal reusable templates. The `/agent-team:dev` and `/agent-team:discuss` skills contain extended, context-specific versions of these prompts with additional phase instructions, output budget rules, and mode-specific guidance. When working from those skills, follow their inline prompts. These templates are for ad-hoc team spawning outside of those workflows.

<spawn_schemas>
Use these templates when spawning teammates. Replace `[placeholders]` with actual values.

### Explorer Spawn

```
Spawn a read-only explorer teammate with the prompt:

"You are the explorer for this team.

Your task: Analyze the codebase for implementing this feature:
[FULL TASK SPEC - paste complete description]

Find: (1) Similar features and patterns, (2) Files to modify/create,
(3) Architecture patterns, (4) Dependencies, (5) Concerns.

Return findings in an <explorer-result> block. Message the lead when done."

Require plan approval before they make changes.
```

### Implementer Spawn

```
Spawn an implementer teammate with the prompt:

"You are the implementer for this team.

Your task: Implement changes for this feature:
[FULL TASK SPEC - paste complete description]

Implementation plan:
[PASTE PLAN FROM EXPLORER FINDINGS]

Work through the shared task list. Message the reviewer when each task is done.
Message the lead if blocked. Complete self-review before marking tasks done.

Return results in an <implementer-result> block."

Require plan approval before they make changes.
```

### Reviewer Spawn

```
Spawn a read-only reviewer teammate with the prompt:

"You are the reviewer for this team.

Your task: Verify implementation matches this spec:
[FULL TASK SPEC - paste complete description]

Two-pass review: (1) Spec compliance - does code match requirements exactly?
(2) Code quality - security, performance, patterns.

MESSAGE THE IMPLEMENTER DIRECTLY with findings. Do not relay through the lead.
Return results in a <reviewer-result> block. Message the lead with final status."
```

### QA Spawn

```
Spawn a QA teammate with the prompt:

"You are the QA teammate.

Your task: Run lint, typecheck, and tests for this project.
Wait for the reviewer to confirm COMPLIANT before running.

Auto-detect commands from package.json, pyproject.toml, or similar.
MESSAGE THE IMPLEMENTER DIRECTLY with any errors found.
Return results in a <qa-result> block. Message the lead with final status."
```

### COUNCIL Spawn Schemas (for /agent-team:discuss)

These teammates are spawned progressively per phase. All are read-only.

#### Scout Spawn (Phase 1)
```
Spawn a read-only scout teammate with the prompt:

"You are the codebase scout for a /agent-team:discuss session.
[PASTE IDEA + REFERENCES]

Explore the codebase for patterns, integration points, and constraints.
OUTPUT BUDGET: Keep response under 2000 tokens.
Return findings in a <scout-result> block. Message the lead when done."
```

#### Researcher Spawn (Phase 1)
```
Spawn a read-only researcher teammate with the prompt:

"You are the web researcher for a /agent-team:discuss session.
[PASTE IDEA + REFERENCES]

Research prior art, libraries, best practices, architectural patterns.
OUTPUT BUDGET: Keep response under 2000 tokens.
Return findings in a <research-result> block. Message the lead when done."
```

#### Challenger Spawn (Phase 3)
```
Spawn a read-only challenger teammate with the prompt:

"You are the plan challenger for a /agent-team:discuss session.
[PASTE DRAFT PLAN + FINDINGS SUMMARIES]

Stress-test: feasibility, accuracy, alternatives, risks, missing pieces.
OUTPUT BUDGET: Keep response under 1500 tokens.
Return findings in a <challenge-result> block. Message the lead when done."
```

#### Blind Spot Spawn (Phase 4)
```
Spawn a read-only blind spot teammate with the prompt:

"You are the blind spot investigator for a /agent-team:discuss session.
[PASTE VALIDATED PLAN SUMMARY + TECHNOLOGIES]

Check: native features, recent changes, simpler alternatives, unverified assumptions.
OUTPUT BUDGET: Keep response under 1000 tokens.
Return findings in a <blindspot-result> block. Message the lead when done."
```

#### Dependency Researcher Spawn (Phase 5 - optional)
```
Spawn a read-only dependency researcher teammate with the prompt:

"You are the dependency researcher for a /agent-team:discuss DEEPEN session.
[PASTE VALIDATED PLAN + SCOUT SUMMARY]

Research all external dependencies. Pin exact versions. Use context7 for docs.
OUTPUT BUDGET: Keep response under 2000 tokens.
Return findings in a <dependency-result> block. Message the lead when done."
```
</spawn_schemas>

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
3. **Skills auto-activate based on task context** - code-review and testing-patterns load when relevant
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

<red_flags>
### Delegation Rationalizations

| Thought | Reality |
|---------|---------|
| "I'll just do this one thing myself" | Enable delegate mode. You coordinate, never code. |
| "This is simple, I'll just do it" | Simple tasks still need subagent discipline. Delegate. |
| "This teammate is slow, I'll help" | Message them with guidance. Don't take over. |
| "I can check quickly without a teammate" | Quick checks miss things. Use the teammate. |
| "The user wants speed" | Fast + wrong = slow. Process ensures quality. |
| "I already know the codebase" | Fresh teammate context prevents assumptions. |

### Review Rationalizations

| Thought | Reality |
|---------|---------|
| "I'll skip the reviewer, tests pass" | Tests verify behavior, not requirements. Review is required. |
| "Self-review is enough" | Self-review catches obvious issues. Spec-review catches drift. Both required. |
| "Spec review is overkill" | Spec drift is the #1 cause of wasted iterations. Always verify. |
| "The implementer is confident" | Confidence ≠ correctness. Verify independently. |
| "Tests pass, so it's correct" | Tests verify behavior, not requirements. Spec review catches "wrong thing built well." |

### Process Rationalizations

| Thought | Reality |
|---------|---------|
| "I'll skip clarification, it's obvious" | Assumptions cause rework. 5 minutes asking saves hours fixing. |
| "One big task is easier" | Small tasks enable parallelism and reduce waste. |
| "One more retry won't hurt" | After 3 failures, re-assess strategy. Don't loop blindly. |
| "I'll ask forgiveness later" | Blocked = ask for guidance. Don't proceed on assumptions. |
| "The plan is close enough" | Close enough = wrong. Update the plan or get approval. |

### Context Rationalizations

| Thought | Reality |
|---------|---------|
| "I'll broadcast this update" | Broadcast costs tokens per teammate. Use targeted messages. |
| "The teammate can read the file" | Provide FULL TEXT. Teammates start with clean context and shouldn't hunt for it. |
| "Previous context carries over" | Each teammate starts fresh. You maintain and pass context. |
| "Git history shows the changes" | Pass explicit summary. Don't make teammates reconstruct context. |
</red_flags>
