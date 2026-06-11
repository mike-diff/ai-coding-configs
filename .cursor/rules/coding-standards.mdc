---
description: "Coding standards and conventions for all code changes"
globs:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.py"
  - "**/*.rs"
  - "**/*.go"
alwaysApply: false
---

# Coding Standards

<philosophy>
Write minimal, self-documenting code. Prioritize clarity over cleverness.
</philosophy>

## General Principles

<principles>
1. **Minimal**: Absolute minimum code needed
2. **Self-documenting**: Code explains itself through precise naming
3. **Type-Exact**: Strict types, zero `any` (TypeScript)
4. **Performant**: Follow framework best practices
5. **Consistent**: Match existing patterns in the codebase
</principles>

## Code Quality Rules

<code_rules>
### Naming
- Functions: verbs (`fetchUser`, `validateInput`, `handleSubmit`)
- Variables: nouns (`user`, `isLoading`, `errorMessage`)
- Booleans: `is/has/should` prefix (`isValid`, `hasError`, `shouldRetry`)
- Constants: UPPER_SNAKE_CASE

### Functions
- Single responsibility
- Pure when possible
- Max 30 lines (guideline, not rule)
- JSDoc for public APIs

### Comments
- Explain "why", not "what"
- No commented-out code
- TODO format: `TODO(owner): description`

### Error Handling
- Handle errors at appropriate boundaries
- Provide actionable error messages
- Don't swallow errors silently
</code_rules>

## TypeScript/JavaScript Specific

<typescript_rules>
- Prefer `const` over `let`, never `var`
- Use `async/await` over callbacks
- Strict TypeScript: no `any`, no `@ts-ignore`
- Prefer interfaces over types for objects
- Export types alongside implementations
</typescript_rules>

## Python Specific

<python_rules>
- Type hints on all function signatures
- Docstrings for public functions (Google or NumPy style)
- Use dataclasses or Pydantic for data structures
- Prefer pathlib over os.path
</python_rules>

## Making Changes

<change_rules>
When modifying existing code:
- Make minimal changes to achieve the goal
- Preserve existing style and patterns
- Don't refactor unrelated code
- Don't add features beyond requirements
- Verify changes don't break dependencies

When creating new code:
- Follow existing project structure
- Match patterns from similar files
- Include necessary imports
- Add appropriate tests
</change_rules>

## Anti-Patterns to Avoid

<anti_patterns>
- Over-engineering for hypothetical futures
- Adding unused abstractions
- Clever one-liners that obscure intent
- Magic numbers/strings without constants
- Deep nesting (max 3 levels)
- God objects/functions
- Premature optimization
</anti_patterns>
