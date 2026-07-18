---
name: dev
description: Implement and verify an approved feature, bug fix, or specification phase. Use when the user explicitly invokes $dev for ad hoc or spec-backed development, a named phase or multi-phase sweep, interactive or unattended local execution, with preflight, scoped implementation, reflection, independent review, QA, and a committed, pr-ready, blocked, or failed handoff.
---

# Dev

Implement the requested change end to end while preserving user work, approval boundaries, and verifiable quality.

## Operating rules

- Read repository instructions and relevant code before editing.
- Inspect the working tree and preserve every pre-existing user change.
- Treat an approved spec as the scope contract; do not silently redesign it.
- Keep one authoritative main-thread plan for phases, dependencies, and quality gates.
- Ask only questions that materially affect behavior, safety, or authority. Record reversible low-risk assumptions and proceed.
- Use one writer by default. Delegate independent exploration, review, or QA when it materially improves speed or reliability.
- Use multiple writers only for disjoint files with explicit ownership and integration contracts.
- Reflect before independent review; run actual repository checks before completion.
- Do not deploy, push, open a pull request, or perform another external side effect unless explicitly requested.
- Default to PR-ready delivery. Commit only when the user explicitly asks for a commit or phase commits.
- Create or use a native `/goal` only when the user explicitly requests goal-driven persistence.

## Required sequence

1. Preflight and mode detection.
2. Contract and codebase exploration.
3. Material clarification.
4. Implementation plan and ownership.
5. Build and focused verification loop.
6. Reflection.
7. Independent review and QA.
8. Commit or PR-ready handoff.
9. Wrapup with one terminal state.

Read [references/workflow.md](references/workflow.md) for mode rules, sweep behavior, risk gates, delegation, result formats, and recovery. Follow it completely.

## Completion rule

Finish only when the requested scope is implemented or genuinely blocked, relevant validation has run, independent review findings are resolved or disclosed, unrelated changes remain intact, and the terminal state is exactly one of `committed`, `pr-ready`, `blocked`, or `failed`.
