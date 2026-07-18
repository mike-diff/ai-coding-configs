# Discuss workflow

## Contents

- [Mode detection](#mode-detection)
- [Phase 1: Seed](#phase-1-seed)
- [Phase 2: Explore](#phase-2-explore)
- [Phase 3: Validate](#phase-3-validate)
- [Phase 4: Deliver](#phase-4-deliver)
- [Error recovery](#error-recovery)

## Mode detection

Detect one or more modes from the request:

- **Fresh**: shape a new idea and find the smallest valuable form.
- **Revisit**: compare an existing implementation with its intended outcome and decide whether change is worthwhile.
- **Reference-driven**: study supplied files, documents, or URLs before forming questions or conclusions.

For revisit work, inspect actual code and regression risk. For reference-driven work, cite the supplied material and identify conflicts between sources rather than silently choosing one.

## Phase 1: Seed

1. Restate the idea in one sentence.
2. Identify the likely problem, beneficiary, and uncertain decision.
3. Read all supplied references.
4. Ask one to three questions about the highest-leverage unknowns, usually why the change matters, what outcome proves it, and what is out of scope.
5. Stop and wait when an answer materially changes the direction.

Use research only when it improves the decision. For a non-trivial codebase or a question with independent evidence lanes, ask at most two read-only subagents to work in parallel:

```text
Codebase scout: Inspect the repository for the supplied idea. Return at most five
findings covering existing behavior, patterns, integration points, likely files,
and constraints. Cite paths and line numbers. Do not edit anything.

External researcher: Verify the current platform, dependency, or prior-art facts
needed for the supplied idea. Return at most five findings with authoritative
links and dates. Do not provide a broad survey.
```

Wait for requested results. Summarize each result in three to five bullets before continuing. If delegation is unavailable or adds little value, perform the same lenses sequentially in the main thread.

## Phase 2: Explore

Continue a reactive conversation rather than a fixed questionnaire:

- Follow new information that changes the problem or approach.
- Weave research findings into the next question.
- Surface a simpler option or a conflicting constraint when found.
- Periodically summarize the current problem, approach, scope, and remaining uncertainty.
- Keep each turn to at most three questions.

Move to validation when all of these are understood:

- the user or workflow experiencing the problem;
- the observable outcome that matters;
- the proposed approach and meaningful alternatives;
- in-scope, out-of-scope, and deferred work;
- human decisions that implementation must not make.

If these are not clear, continue exploring. Do not implement.

## Phase 3: Validate

Draft this plan:

```markdown
## Plan: [title]

### Problem
[Who experiences what problem and why it matters]

### Proposed approach
[Smallest useful approach]

### Why this approach
[Tradeoffs and rejected alternatives]

### Scope
- In: [items]
- Out: [items]
- Deferred: [items]

### Technical context
- Existing patterns: [paths]
- Integration points: [paths or systems]
- External facts: [source links where relevant]
- Constraints: [constraints]

### Success signals
- [observable metric, command, or proof artifact]

### Risks
- [risk, impact, mitigation]

### Human decisions
- [approval boundary or None]
```

Run a fresh challenger lens. Prefer a read-only subagent for medium or large work:

```text
Stress-test the draft plan. Return only findings that could change it. Check
feasibility, accuracy against the repository, simpler alternatives, regression
risk, missing failure paths, and unverified assumptions. Rate material risks.
Do not edit anything. Keep the response under 1,000 words.
```

For revisit mode, also ask whether keeping the current implementation or making a smaller targeted fix has greater net value. Incorporate valid findings. If a materially different alternative remains, present it to the user and wait for the decision.

## Phase 4: Deliver

Present the validated plan with risks, mitigations, unresolved questions, and a validation summary. Then complete a **mandatory blind-spot** check before recommending build work.

Use a fresh read-only subagent when useful, otherwise run the lens sequentially:

```text
Find only blind spots that would change this validated plan. Check current native
platform features, recent material changes, dramatically simpler approaches,
and assumptions nobody verified. Use authoritative sources for current claims.
Return "No material blind spots found" when appropriate. Do not edit anything.
```

Update the plan for confirmed findings. Label uncertain findings as caveats rather than facts.

End with exactly one handoff form:

```xml
<adlc-handoff>
problem: [one-sentence user or workflow problem]
target_user: [primary user or actor]
hypothesis: [why the proposed change should improve the outcome]
success_metrics:
  - [measurable signal or proof artifact]
core_workflow_break: [what is manual, repeated, missing, or broken]
assumptions:
  - [assumption] — [verified / likely / risk]
risks:
  - [risk and mitigation]
human_decisions_required:
  - [decision requiring the user, or None]
recommended_next: $spec [spec-ready feature request]
</adlc-handoff>
```

For a small, fully bounded change, the final line may instead be:

```text
recommended_next: $dev [small validated change]
```

Route medium, large, cross-layer, risky, or multi-phase work to `$spec`. Do not duplicate full spec generation inside this workflow.

## Error recovery

- Missing research result: continue with the available evidence and name the gap.
- Contradictory sources: show the conflict and ask which authority controls when it is a product decision.
- Fatal flaw: recommend against the plan or return to exploration.
- Expanding scope: restate the core outcome and move extensions to Deferred.
- Quiet user: summarize the current state and the single decision needed next.
- Context pressure: retain the validated plan, decisions, and short research summaries; discard raw intermediate output.
