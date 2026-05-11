# Judgment Guide

Detailed criteria for evaluating findings that require agent judgment. Tools find candidates — this guide helps decide what to do with them.

---

## Deduplication

**When to consolidate:**
- Identical or near-identical code serves the same purpose
- A shared version would be simpler, not more abstract
- All callers use the same parameters
- The duplication causes drift risk (fixes applied to one copy but not the other)

**When to leave alone:**
- The copies serve different purposes that happen to look similar
- A shared version would need configuration/parameters that obscure intent
- The duplication is intentional (e.g., similar algorithms with different edge case handling)
- Consolidation would create a dependency between unrelated modules

**Red flags — don't consolidate:**
- "This could be DRY" without a concrete shared version that's actually simpler
- Introducing an abstraction layer, interface, or strategy pattern just to share code
- The "shared" version has more branches/conditionals than either original

---

## Type Consolidation

**When to consolidate:**
- Structurally identical types in different files
- Types represent the same domain concept
- Drift between copies would cause real bugs (e.g., adding a field to one but not the other)
- The shared location makes semantic sense (e.g., a `types.ts` or `domain.ts`)

**When to leave alone:**
- Types are coincidentally similar but represent different concepts
- The types evolve independently (different teams, different APIs)
- Consolidation would create a coupling between unrelated modules
- The types have the same shape but different semantics (e.g., `UserId` vs `OrderId` both being `string`)

---

## Dead Code

**Safe to remove (high confidence):**
- Exported but never imported anywhere in the project
- Function/class defined but zero call sites
- Commented-out code blocks
- Disabled feature flags with no configuration path to enable them

**Verify before removing (medium confidence):**
- Exported — could be consumed by external packages or dynamic imports
- Referenced in test files only — tests may be testing the interface
- Part of a public API — even if unused internally, external consumers may depend on it
- Registered via plugin/extension system — may be loaded by name string
- Referenced in configuration files, docs, or examples

**Do not remove (skip):**
- Entry points or CLI commands
- Error classes in a shared library
- Types that are part of a public API contract
- Code behind feature flags (even if currently disabled)

---

## Circular Dependencies

**High priority to fix:**
- Cycles that cause runtime initialization errors
- Cycles between modules in different feature domains (indicates architectural issue)
- Cycles that prevent tree-shaking or lazy loading

**Low priority (may be acceptable):**
- Type-only circular imports (TypeScript erases these at compile time)
- Cycles within a single feature domain (may be intentional)
- Cycles introduced by re-exports (barrel files)

**Fix strategies (in order of preference):**
1. Extract shared code to a third module both depend on
2. Move the dependency to a parameter (dependency injection)
3. Use lazy imports (`import()` instead of static `import`)
4. Merge modules that are tightly coupled

---

## Type Strengthening

**Safe to fix:**
- `any` used for a value with a clearly inferable type
- `any` used as a return type where the actual return is specific
- Overly broad types that could be narrowed without breaking callers (e.g., `string` → specific union)
- `as any` casts that are clearly unnecessary

**Preserve as-is:**
- `unknown` at API boundaries (HTTP responses, user input, deserialization)
- `any` in generic constraints where the type is genuinely unknown
- `any` in test code mocking untyped dependencies
- `unknown` as a deliberate choice for type safety (it forces explicit narrowing)

**Medium risk (flag for review):**
- Changing a public function's parameter type (may break callers)
- Narrowing a return type that external code depends on
- Adding generics where `any` was used (changes API surface)

---

## Error Handling

**Keep try/catch when:**
- Handling errors at a boundary (API layer, I/O layer, serialization)
- Performing cleanup in `finally` blocks
- Recovering from expected failure modes (retry logic, fallback services)
- Logging errors for observability
- Displaying user-facing error messages
- Catching specific error types for specific handling

**Remove try/catch when:**
- Catch block is empty or only has a comment
- Error is logged but then execution continues as if nothing happened
- Catch catches `any`/`unknown` and does nothing useful with it
- The caught error is immediately re-thrown (just let it propagate)
- The "handling" is returning a default/fallback value that hides the problem
- The try/catch wraps code that cannot actually throw

**Replace when:**
- Broad `catch (e)` could be narrowed to a specific error type
- Multiple catch blocks could be consolidated
- Error handling could be moved to a higher level (middleware, wrapper)

---

## Slop and Comments

**Remove:**
- Comments that restate what the code does: `// increment counter` above `count++`
- Edit-history comments: "Previously this used X, changed to Y", "Moved from file Z"
- TODO/FIXME that are years old with no activity
- Stub comments: "TODO: implement this", "placeholder", "fill in later"
- Block comments that are just section dividers with no information
- Comments that describe the implementation instead of the intent
- Excessive inline comments that make the code harder to read

**Keep or improve:**
- Comments explaining *why*: "We use a 5-second timeout because the downstream service has a 10-second SLA"
- Comments explaining non-obvious constraints or invariants
- Comments documenting edge cases or known limitations
- Comments explaining business logic that isn't obvious from the code
- Public API documentation (JSDoc, docstrings, etc.)

**Improve by rewriting:**
- Comments that have useful intent buried in verbose language
- Comments that describe the "what" when they should describe the "why"
- Comments written for the original author, not for a new engineer

---

## Deprecated / Legacy Code

**Safe to remove:**
- Code commented out (not just comments about code)
- Dead branches in if/else that can never be reached
- Feature flag branches where the flag is always one value and the config path to change it is gone
- Migration code for a migration that's been completed
- Wrapper/adapter functions that just call through to the new version

**Verify before removing:**
- Deprecated functions with `@deprecated` — check if any callers remain
- Old API endpoints — check if any clients still use them
- Configuration options — check if any config files reference them
- Database columns — check if any queries reference them

**Do not remove:**
- Backwards compatibility shims for public APIs
- Code behind feature flags that could be re-enabled
- Migration tools that users may still need to run
- Fallback implementations used in specific environments
