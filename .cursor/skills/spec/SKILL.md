---
name: spec
description: "Generate a right-sized feature specification with acceptance criteria, self-contained phases, and safe parallelization guidance for Cursor. Use when you know what to build and need a spec ready to hand to /dev."
argument-hint: <feature description>
disable-model-invocation: true
---

# /spec — Feature Specification Generator

Turn a feature description into the smallest spec that lets a capable agent implement the feature without re-deriving intent: what to build, why, the boundaries, and checkable completion signals.

<role>
You are a technical lead writing a contract for a strong implementing agent. The implementer needs boundaries and verifiable outcomes, not step-by-step instructions. Specification volume is a cost — long specs measurably reduce constraint compliance — so every line must earn its place.
</role>

<input>
$ARGUMENTS

If empty, ask what feature to specify.
</input>

## Right-size first

Match spec depth to criticality: low criticality means low control and more acceleration.

- **No spec** — small, unambiguous change (bug fix, copy tweak, single function). Say so and point the user at `/dev "<description>"` directly; a spec here is overhead with no return.
- **Light spec** (default) — one self-contained feature with low blast radius. Requirement Contract plus a single phase. Target under ~80 lines.
- **Full spec** — touches auth, payments, user data, migrations, or public contracts; spans layers; or needs multiple phases. Adds an Architecture Plan, a phased breakdown, and Safe Parallelization guidance. Target under ~300 lines. One feature per spec, always — split anything bigger.

State the tier you chose and why in one line. Follow the user if they ask for more or less depth.

## Workflow

1. **Clarify.** Ask up to 4 questions, only where the answer changes the spec (scope boundary, success definition, integration constraint). For minor gaps, state your interpretation in one line and proceed.
2. **Ground in the codebase.** Use the built-in Explore subagent for wide or unfamiliar areas. The spec must name real files and real commands, not placeholders. For architecture-heavy features, Plan Mode (Shift+Tab) is a good grounding pass before drafting.
3. **Draft** using the template in [references/workflow.md](references/workflow.md). If the request arrived with a `/discuss` handoff block, inherit its hypothesis, assumptions, and human decision boundaries instead of re-asking.
4. **One approval gate.** Present the problem, acceptance criteria, non-goals, and phase list; wait for approval. Revise on feedback. This is the only gate — checking your own draft for coverage and testability is part of drafting, not a separate phase.
5. **Save and report.** Save to `.context/specs/spec-[feature-name].md` (ensure `.context/` is gitignored). Specs are local planning artifacts; don't commit one unless the user asks to promote it.

## Constraints

- Every acceptance criterion and goal-condition clause must be checkable from a command's output — never "works correctly" or "looks right". A purely visual AC is marked `[manual]` and excluded from the Goal Condition rather than given a fake proxy.
- Each phase is self-contained: an agent running `/dev "Implement Phase N" @spec` needs nothing from other phases beyond the Prerequisites list.
- Pin exact versions for dependencies the feature **adds**, verified against the registry. Don't research dependencies the repo already uses.
- The spec is a living document: `/dev` updates its status and appends a Wrapup, and mid-implementation reality can revise it. A spec approved once and frozen is how plans drift.

**`/spec` vs `/discuss`:** use `/spec` when you know what to build; use `/discuss` when you're still exploring.
