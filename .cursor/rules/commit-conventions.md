---
description: "Git commit message conventions"
globs:
  - ".git/**"
alwaysApply: false
---

# Commit Conventions

<format>
All commits follow Conventional Commits format:

```
type(scope): description

[optional body]

[optional footer]
```
</format>

## Commit Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `docs` | Documentation only changes |
| `test` | Adding or correcting tests |
| `chore` | Maintenance tasks (deps, configs, scripts) |
| `style` | Formatting, whitespace, no code change |
| `perf` | Performance improvement |
| `ci` | CI/CD configuration changes |
| `revert` | Reverting a previous commit |

## Scope

Scope is optional but recommended. Use:
- Feature area: `auth`, `api`, `ui`, `db`
- Component: `button`, `modal`, `form`
- Module: `utils`, `hooks`, `services`

## Description Rules

<description_rules>
- Use imperative mood: "add" not "added" or "adds"
- Lowercase first letter
- No period at end
- Max 50 characters (hard limit: 72)
- Be specific: "fix login timeout" not "fix bug"
</description_rules>

## Examples

<examples>
Good:
```
feat(auth): add JWT token refresh
fix(api): handle null response from user endpoint
refactor(hooks): extract useDebounce from useSearch
docs(readme): add installation instructions
test(auth): add tests for password reset flow
chore(deps): update react to v19
```

Bad:
```
Fixed stuff
WIP
Update code
feat: Added new feature for the login page that allows users to reset their password
```
</examples>

## Body (Optional)

Use body for:
- Explaining "why" not "what"
- Breaking changes
- Related issues

```
fix(api): handle rate limiting gracefully

The external API started returning 429 responses during peak hours.
Added exponential backoff with max 3 retries.

Closes #123
```

## Breaking Changes

For breaking changes, add `!` after type/scope and explain in footer:

```
feat(api)!: change response format for user endpoint

BREAKING CHANGE: user.name is now user.fullName
```
