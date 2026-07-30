# /agent-team:discuss — Phases and Subagent Briefs

Four phases: SEED → EXPLORE → VALIDATE → DELIVER. The conversation is the spine;
research and validation attach to it. Subagents run in the background via the Agent
tool — each has its own context window, so their exploration never crowds yours, and
their summaries (not their transcripts) are what you carry forward.

## Phase 1: SEED

Three things, in parallel:

**1a. Read references.** If the user provided `@files` or URLs, read them all before
responding. Your opening should connect the references to the idea, not just restate it.

**1b. Open the conversation.** State your interpretation of the idea in a sentence,
show you understand the intent, and ask the 1-2 questions that most shape direction —
the why behind the what. No checklists; more questions come naturally as the
conversation develops.

**1c. Launch background research.** Spawn both subagents now so findings arrive while
you talk:

Codebase scout (fresh mode):
```
You are the codebase scout for a /agent-team:discuss session exploring: [IDEA]
[IF REFERENCES: context materials: LIST]
Map what's relevant: what already exists that relates to this, the patterns and
conventions it would follow, natural integration points, constraints the architecture
imposes, partial implementations to build on. Reference file paths and line numbers;
summarize rather than quoting file contents. Return your findings as a summary —
they'll be woven into a planning conversation.
```

Codebase scout (revisit mode): same brief, but analyze the CURRENT implementation —
what was built and where, what it does well, what smells wrong (redundancy,
over-engineering, dead code), how it compares to project conventions and native
platform features, what you'd change starting fresh. Honest and specific.

Web researcher:
```
You are the web researcher for a /agent-team:discuss session exploring: [IDEA]
Research the landscape: how others solved similar problems, libraries or platform
features that exist for this, common pitfalls, current state of the relevant tools
(recent releases matter). Practical insights over exhaustive surveys — return the
handful of findings that would actually change a plan, with links.
```

## Phase 2: EXPLORE

The core of the command — a reactive conversation, not a script.

- Follow threads: when the user reveals something unexpected, pursue it.
- Weave in research as it lands: "the scout found [pattern] — does that change your
  thinking?" Extract the few findings that matter from each subagent result and carry
  those, not the raw report.
- Challenge gently when you see a simpler approach or a risk; summarize periodically
  ("so far I'm hearing…") to keep shared understanding explicit.
- Move on when you and the user agree on the core problem, the approach, and rough
  scope. Propose the transition: "I think we have a solid picture — let me draft the
  plan and have it stress-tested." If they want to keep exploring, keep exploring.

## Phase 3: VALIDATE

**3a. Draft the plan** from the conversation and research:

```markdown
## Plan: [Title]

### Problem
[what this solves, for whom, why it matters]

### Approach
[what emerged from the conversation, and why it beats the alternatives discussed]

### Scope
In: […]  Out: […]  Open questions: […]

### Technical Context
[patterns to follow, integration points, libraries — from scout + researcher]

### Risks
[what could go wrong, with impact]

### Effort
[Small / Medium / Large, one-line justification]
```

**3b. Adversarial pass.** Spawn one fresh-context challenger subagent:

```
You are the challenger for a /agent-team:discuss session. Try to break this plan:
[PLAN + brief scout/researcher summaries]

1. FEASIBILITY — can this be built in this codebase as described? Flag real gaps.
2. SIMPLER PATH — is there a dramatically simpler approach the conversation missed
   because it committed to a direction early?
3. NATIVE FEATURES — do the platforms/tools involved already ship something that
   replaces custom work proposed here? Check current docs and recent releases.
4. UNVERIFIED ASSUMPTIONS — what does the plan assume that nobody confirmed?
5. MISSING PIECES — edge cases, migration, testing, performance.
[REVISIT mode: also challenge whether change is needed at all — is the existing
implementation actually fine? "Keep it" is a valid verdict.]

Report only findings that would change the plan, each in a sentence or two with
severity. If it holds up, say "no plan-changing findings" and stop.
```

Tell the user the plan is being stress-tested while they review the draft.

**3c. Incorporate.** Fold real findings into the plan and tell the user what changed
and why. If the challenger surfaced a significantly better alternative, present the
choice (stick / pivot / explore further) rather than deciding silently. Findings that
check out clean need no mention.

## Phase 4: DELIVER

Present the validated plan (updated draft from Phase 3, plus a one-line validation
summary: what was confirmed, what changed) and close with the handoff block:

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
recommended_next: /agent-team:spec "[spec-ready feature request]" OR /agent-team:dev "[small validated change]"
</adlc-handoff>
```

Route by effort:
- **Small, well-defined** → "Ready to build: `/agent-team:dev [description]`" — the handoff
  carries the validated assumptions.
- **Medium/large or multi-phase** → recommend `/agent-team:spec "[feature]"`; /agent-team:spec inherits the
  handoff and produces the phased, goal-conditioned spec. Don't generate the spec
  inside /agent-team:discuss — one spec generator in the toolbox, not two.

## Error recovery

- A research subagent returns late or empty: proceed on the conversation; note the gap
  in the plan's Technical Context rather than blocking.
- Challenger finds a fatal flaw: present it plainly, don't bury it; explore
  alternatives with the user.
- Conversation circles: summarize what's agreed, name the specific open blocker.
- Scope keeps growing: refocus on the core, park extensions under "Deferred".
- Revisit mode concludes the original is fine: say so — validation is a result.
