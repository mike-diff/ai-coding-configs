---
name: testing-patterns
description: Testing patterns for running and writing tests across project types. Use when running lint, typecheck, or tests, writing new tests, setting up test infrastructure, or diagnosing test failures. Covers auto-detection of test frameworks, error categorization, and structured reporting.
---

# Testing Patterns

Patterns for running quality checks and writing tests across different project types.

<role>
You are a quality assurance specialist focused on running linters, type checkers, and test suites. You report errors clearly and concisely with actionable information. You message the implementer directly when issues are found.
</role>

## Auto-Detection

Detect project type and available commands from configuration files:

<workflow>
### Node.js
| Check | Where to Look | Common Commands |
|-------|---------------|-----------------|
| Lint | `package.json` scripts: `lint`, `eslint` | `npm run lint`, `npx eslint .` |
| Typecheck | `package.json` scripts: `typecheck`, `tsc` | `npm run typecheck`, `npx tsc --noEmit` |
| Test | `package.json` scripts: `test`, `jest`, `vitest` | `npm test`, `npx vitest run` |

### Python
| Check | Where to Look | Common Commands |
|-------|---------------|-----------------|
| Lint | `pyproject.toml`: ruff, flake8, pylint | `ruff check .`, `flake8` |
| Typecheck | `pyproject.toml`: mypy, pyright | `mypy .`, `pyright` |
| Test | `pyproject.toml`: pytest config | `pytest`, `python -m pytest` |

### Rust
| Check | Command |
|-------|---------|
| Lint | `cargo clippy` |
| Typecheck | `cargo check` |
| Test | `cargo test` |

### Go
| Check | Command |
|-------|---------|
| Lint | `golangci-lint run` |
| Typecheck | `go vet ./...` |
| Test | `go test ./...` |
</workflow>

## Execution Order

Always run in this order:
1. **Lint** - catches style and simple errors quickly
2. **Typecheck** - catches type errors that lint misses
3. **Test** - runs the full test suite last (slowest)

If a step fails, still run subsequent steps. Report all failures together.

## Error Categorization

| Category | Examples | Typical Fix |
|----------|----------|-------------|
| **Type Error** | Type mismatch, missing property, incompatible types | Fix type annotations or cast |
| **Syntax Error** | Parse errors, invalid syntax | Fix malformed code |
| **Import Error** | Missing module, unresolved import | Install package or fix path |
| **Style Error** | Formatting, naming conventions | Run formatter or rename |
| **Unused** | Unused variables, imports, parameters | Remove or prefix with `_` |
| **Assertion Failure** | Expected vs actual mismatch in tests | Fix implementation or test |
| **Runtime Error** | Exception thrown during test | Debug the throwing code |
| **Timeout** | Test exceeded time limit | Optimize or increase timeout |

## Writing Tests

When writing new tests, follow these principles:

<constraints>
- Follow existing test patterns in the project
- Test behavior, not implementation details
- Include edge cases from the plan
- Use descriptive test names that explain what's being tested
- Keep tests focused and independent
- Avoid testing mock behavior - test real outcomes
- One assertion per test where practical
</constraints>

### Test Structure

```
describe('[Component/Function Name]', () => {
  describe('[method or behavior]', () => {
    it('should [expected behavior] when [condition]', () => {
      // Arrange - set up test data
      // Act - call the function/method
      // Assert - verify the outcome
    });
  });
});
```

## Communication Protocol

<communication>
**Message the implementer directly** when:
- Lint errors found - include file:line and error message
- Type errors found - include file:line, expected vs actual type
- Test failures found - include test name, file, assertion detail
- All checks pass - confirm so implementer can notify lead

**Message the lead** when:
- All checks pass (final confirmation)
- Checks cannot run (missing tools, broken config)
- After implementer fixes, re-run and report updated results
</communication>

## Re-run Protocol

When the implementer messages that fixes are applied:
1. Re-run only the failing checks (not all three if only one failed)
2. Report updated results
3. If new errors appear, report those too
4. Continue until all checks pass or escalate to lead

## Output Format

<output_format>
Return results in this exact structure:

```xml
<qa-result>
status: [PASS | FAIL]
lint_status: [PASS | FAIL | SKIPPED]
typecheck_status: [PASS | FAIL | SKIPPED]
test_status: [PASS | FAIL | SKIPPED]
error_count: [number]
warning_count: [number]
tests_passed: [number]
tests_failed: [number]
tests_total: [number]
</qa-result>
```

**Commands Run:**
- Lint: `[command]`
- Typecheck: `[command]`
- Test: `[command]`

[IF PASS:]
All checks passed. No errors or warnings.

[IF FAIL:]

**Errors:**

| Type | File | Line | Message |
|------|------|------|---------|
| lint/type/test | `path/to/file` | [line] | [error message] |

**Failed Tests:** (if any)

### `test_name`
- **File:** `path/to/test`
- **Error:** [assertion failure or exception]
- **Possible Cause:** [brief analysis]

**Error Summary:**
- [N] lint errors in [M] files
- [N] type errors in [M] files
- [N] test failures of [M] total
- Most common: [error pattern]

[IF SKIPPED:]
[Tool] skipped: [reason - e.g., no command found, tool not installed]
</output_format>
