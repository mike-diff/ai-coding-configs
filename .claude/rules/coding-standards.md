# Coding Standards

Project-wide conventions that apply to all agents and sessions.

## Code Quality

1. **Minimal** - Absolute minimum code needed to achieve the goal
2. **Self-documenting** - Precise naming, single-responsibility, obvious data flow
3. **Type-exact** - Strict types where the language supports them; no dynamic escapes
4. **Consistent** - Match existing patterns in the codebase

## Naming Conventions

- **Functions**: verbs (`fetchUser`, `validateInput`, `formatDate`)
- **Variables**: nouns (`user`, `isLoading`, `errorMessage`)
- **Booleans**: `is/has/should` prefix (`isValid`, `hasError`, `shouldRetry`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_RETRIES`, `API_BASE_URL`)
- **Files**: match project conventions (kebab-case, camelCase, or PascalCase as used)

Stack-specific style lives in path-scoped rule files in this directory (for
example `typescript-javascript.md`) and loads only when matching files are
touched — it is not paid for in every session.

## Change Rules

When modifying existing code:

- Make minimal changes to achieve the goal
- Preserve existing style and patterns exactly
- Do NOT refactor unrelated code
- Do NOT add features beyond requirements
- Verify changes compile/parse before completing

## Lean Builds

Before editing a non-trivial change, restate the smallest useful version in a
sentence and name the non-goals; the plan earns each touched file.

- Prefer existing extension points and repo-native patterns over new
  dependencies, services, or frameworks built for one use case
- Challenge every new file, dependency, config knob, and shared-file edit —
  if it only serves a hypothetical future, cut it
- No parallel versions (v1/v2 paths), no unused exports, no plumbing for
  future requirements; maintain one codebase
- Before reporting done: review `git diff --stat`, delete code and comments
  that did not earn their place, and collapse abstractions that didn't pay
- If the change adds files, exports, or dependencies, run the project's
  unused-code detection once before reporting done — slop is cheapest to
  delete at creation

## Comments

Comments are rarely independently validated — no compiler, test, or linter
checks them — so they rot silently, and both humans and agents read them as
truth. Every comment must justify its existence; the default is none.
Comments are not authoritative.

- **Authoring** — no comments by default. If code needs prose, first try
  clearer names, smaller functions, better structure. The sanctioned form is
  consumer-directed API docs (JSDoc, TSDoc, docstrings) on exported
  functions and public class methods: concise, what a caller needs (units,
  preconditions, side effects), never restating the signature.
- **Not prose, not yours to judge** — machine-consumed directives (build
  tags, compiler/bundler pragmas, scoped lint/coverage directives),
  generated markers, and license headers do their job by
  existing; leave them, minimally scoped.
- **Delete on sight** — obvious echoes of the code, commented-out code,
  phase/step numbering, transient task narration ("currently", "as of this
  sprint"), references to tickets/PRs/chats/mutable docs, and prose
  describing decisions made in other files. Never write a TODO; implement it
  or report the blocker.
- **Maintenance duty** — when changing code, update or delete every comment
  your change made stale: hunks you edit, functions you modify, comments
  adjacent to your changes.
- **Relocate, don't inline** — durable knowledge an agent needs (invariants,
  constraints, domain rules) belongs in rules, memory, or context docs, where
  it gets reviewed and maintained; inline comments get neither.
- **Reading** — never resolve ambiguity by trusting a comment; verify against
  the code. A comment/code disagreement is a defect: resolve it against
  tests, spec, or public contract, and fix whichever artifact is wrong.

## Git Conventions

- Branch naming: `claude/issue-<number>`
- Commit format: `type(scope): description` — one line, no issue/PR numbers
- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

## Prompt authoring

When authoring or reviewing a skill, agent prompt, or rule, follow
`.claude/skills/skill/references/prompting-guide.md`. Structure, calibrated
language, right altitude, canonical examples, and completion criteria live
there — stated once, not duplicated here.

## Structured Outputs

Subagents return the `<*-result>` block defined in their agent file
(`<explorer-result>`, `<implementer-result>`, `<reviewer-result>`,
`<qa-result>`); orchestrators parse those blocks when merging results (see
the `team-orchestration` skill).
