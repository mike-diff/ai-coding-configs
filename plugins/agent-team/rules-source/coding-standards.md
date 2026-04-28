# Coding Standards

Project-wide conventions that apply to all agents and sessions.

## Code Quality

1. **Minimal** - Absolute minimum code needed to achieve the goal
2. **Self-documenting** - Precise naming, single-responsibility, obvious data flow
3. **Type-exact** - Strict types, zero `any` in TypeScript
4. **Consistent** - Match existing patterns in the codebase

## Naming Conventions

- **Functions**: verbs (`fetchUser`, `validateInput`, `formatDate`)
- **Variables**: nouns (`user`, `isLoading`, `errorMessage`)
- **Booleans**: `is/has/should` prefix (`isValid`, `hasError`, `shouldRetry`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_RETRIES`, `API_BASE_URL`)
- **Files**: match project conventions (kebab-case, camelCase, or PascalCase as used)

## Change Rules

When modifying existing code:

- Make minimal changes to achieve the goal
- Preserve existing style and patterns exactly
- Do NOT refactor unrelated code
- Do NOT add features beyond requirements
- Verify changes compile/parse before completing

## Code Style

- Use modern JavaScript/TypeScript (ES6+)
- Prefer `const` over `let`, never `var`
- Use async/await over callbacks
- Add JSDoc comments for public functions
- Include comments only where logic is non-obvious
- Keep functions focused and reasonably sized

## Git Conventions

- Branch naming: `claude/issue-<number>`
- Commit format: `type(scope): description (#issue-number)`
- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

## Prompt Structures

Structure prompts with XML tags to separate concerns:
```xml
<role>Who the agent is</role>
<capabilities>What it can do</capabilities>
<constraints>What it must NOT do</constraints>
<workflow>Steps with named phases</workflow>
<output_format>Expected response shape</output_format>
```

**Order matters.** Role first, constraints second, instructions third. Boundaries before actions prevents the agent from acting before understanding its limits.

**Be specific, not verbose.** "Do NOT implement code" beats "Please refrain from writing any implementation code unless explicitly asked to do so." Shorter instructions are followed more reliably.

**Use named phases** for multi-step workflows: `<phase name="explore">`.

**Hard gates for mandatory steps.** "STOP. You MUST do X before proceeding to Y." Soft language like "before wrapping up" gets skipped.

**End with scope constraints.** Agents expand scope naturally; explicit constraints pull them back.

## Structured Outputs

All teammates must return structured result blocks:

- Explorer: `<explorer-result>` block
- Implementer: `<implementer-result>` block with self-review table
- Reviewer: `<reviewer-result>` block with compliance status
- QA: `<qa-result>` block with pass/fail status
