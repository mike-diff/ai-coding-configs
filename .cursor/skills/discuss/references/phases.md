# /discuss — Phases

Four phases: SEED → EXPLORE → VALIDATE → DELIVER. The conversation is the spine;
research and validation attach to it.

## Phase 1: SEED

Three things, in parallel:

**1a. Read references.** If the user provided `@files` or URLs, read them all before
responding. Your opening should connect the references to the idea, not just restate it.

**1b. Open the conversation.** State your interpretation of the idea in a sentence,
show you understand the intent, and ask the 1-2 questions that most shape direction —
the why behind the what. No checklists; more questions come naturally as the
conversation develops.

**1c. Start research.** Dispatch the built-in Explore subagent to map what's relevant:
what already exists that relates to the idea, the patterns and conventions it would
follow, natural integration points, constraints the architecture imposes. (Revisit
mode: analyze the CURRENT implementation instead — what was built and where, what it
does well, what smells wrong, what you'd change starting fresh.) In parallel, research
the external landscape with web search: how others solved this, libraries or platform
features that exist, common pitfalls, recent releases that matter.

## Phase 2: EXPLORE

The core of the command — a reactive conversation, not a script.

- Follow threads: when the user reveals something unexpected, pursue it.
- Weave in research as it lands: "the scout found [pattern] — does that change your
  thinking?" Carry the few findings that matter, not raw reports.
- Challenge gently when you see a simpler approach or a risk; summarize periodically
  ("so far I'm hearing…") to keep shared understanding explicit.
- Move on when you and the user agree on the core problem, the approach, and rough
  scope. Propose the transition: "I think we have a solid picture — let me draft the
  plan and have it stress-tested." If they want to keep exploring, keep exploring.

## Phase 3: VALIDATE

**3a. Draft the plan:**

```markdown
## Plan: [Title]

### Problem
[what this solves, for whom, why it matters]

### Approach
[what emerged from the conversation, and why it beats the alternatives discussed]

### Scope
In: […]  Out: […]  Open questions: […]

### Technical Context
[patterns to follow, integration points, libraries — from research]

### Risks
[what could go wrong, with impact]

### Effort
[Small / Medium / Large, one-line justification]
```

**3b. Adversarial pass.** Stress-test the draft with fresh eyes — a readonly
`/spec-reviewer` dispatch over the plan, or a deliberate refute pass:

1. FEASIBILITY — can this be built in this codebase as described? Flag real gaps.
2. SIMPLER PATH — is there a dramatically simpler approach the conversation missed
   because it committed to a direction early?
3. NATIVE FEATURES — do the platforms/tools involved already ship something that
   replaces custom work proposed here? Check current docs and recent releases.
4. UNVERIFIED ASSUMPTIONS — what does the plan assume that nobody confirmed?
5. MISSING PIECES — edge cases, migration, testing, performance.
   (Revisit mode: also challenge whether change is needed at all — "keep it" is a
   valid verdict.)

**3c. Incorporate.** Fold real findings into the plan and tell the user what changed
and why. If a significantly better alternative surfaced, present the choice (stick /
pivot / explore further) rather than deciding silently.

## Phase 4: DELIVER

Present the validated plan (updated draft plus a one-line validation summary: what was
confirmed, what changed) and close with the handoff block:

```xml
<adlc-handoff>
problem: [the workflow break or user pain this solves]
target_user: [who benefits]
hypothesis: [We believe X will improve Y by Z]
success_metrics:
  - [observable outcome or proof artifact]
assumptions:
  - [assumption] — [verified / likely / risk]
risks:
  - [risk and mitigation]
human_decisions_required:
  - [decision that must not be made autonomously later]
recommended_next: /spec "[spec-ready feature request]" OR /dev "[small validated change]"
</adlc-handoff>
```

Route by effort:
- **Small, well-defined** → "Ready to build: `/dev [description]`" — the handoff
  carries the validated assumptions.
- **Medium/large or multi-phase** → recommend `/spec "[feature]"`; /spec inherits the
  handoff and produces the phased spec. One spec generator in the toolbox, not two.

## Error recovery

- Research returns late or empty: proceed on the conversation; note the gap in the
  plan's Technical Context rather than blocking.
- The adversarial pass finds a fatal flaw: present it plainly, don't bury it; explore
  alternatives with the user.
- Conversation circles: summarize what's agreed, name the specific open blocker.
- Scope keeps growing: refocus on the core, park extensions under "Deferred".
- Revisit mode concludes the original is fine: say so — validation is a result.
