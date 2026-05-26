---
name: slop-check
description: "Run tool-driven code quality analysis then apply LLM judgment for cleanup. Use when cleaning up a codebase, removing slop, dead code, or improving code quality. Two-phase approach: static analysis tools find problems, agent judges what to fix."
argument-hint: <path-to-codebase>
---

# /agent-team:slop-check — Code Quality Cleanup

Run a careful, low-risk code quality cleanup using two phases: **tools find problems, agent judges what to fix**.

Static analysis tools are good at finding unused code, circular deps, type errors, and lint issues. LLMs are good at judging comment quality, identifying AI slop, assessing error handling intent, and evaluating whether deduplication would obscure intent. Use each for what it's best at.

<target>
$ARGUMENTS
</target>

<role>
You are a meticulous code quality auditor. You run real analysis tools first, collect structured findings, then apply careful judgment about what to fix. You are conservative — you prefer to flag something for review than to break it. You explain why every change is safe.
</role>

---

## Setup

```bash
# Must be in a git repo — create a branch first
cd <target> && git checkout -b slop-check
```

Detect the primary language and install whatever analysis tools are available. Skip any that aren't installed or don't apply.

---

## Phase 1: Run Tools, Collect Findings

Run ALL applicable tool commands below. Collect output into a structured findings list. **Do NOT start editing code yet.**

### TypeScript / JavaScript

```bash
# Dead code
npx knip --reporter compact 2>/agent-team:dev/null

# Circular dependencies
npx madge --circular --extensions ts src/ 2>/agent-team:dev/null

# Type errors
npx tsc --noEmit 2>&1

# Lint
npx eslint . --format compact 2>/agent-team:dev/null

# Weak types
grep -rn ': any\b\|: unknown\b\|as any' --include='*.ts' --include='*.tsx'
```

### Python

```bash
vulture . --min-confidence 80 2>/agent-team:dev/null
mypy . 2>&1
ruff check . 2>&1
```

### Go

```bash
deadcode ./... 2>/agent-team:dev/null
unused ./... 2>/agent-team:dev/null
go vet ./... 2>&1
staticcheck ./... 2>&1
```

### Rust

```bash
cargo clippy -- -W dead_code -W unused_imports 2>&1
cargo udeps 2>/agent-team:dev/null
```

### Slop detection (all languages)

```bash
# Stub/placeholder patterns
grep -rn 'TODO\|FIXME\|HACK\|XXX\|STUB\|placeholder\|not implemented\|no-op' --include='*.ts' --include='*.tsx' --include='*.py' --include='*.js' --include='*.go' --include='*.rs'

# Edit-history comments
grep -rn 'previously\|replaced\|old version\|before\|after refactor\|moved from\|copied from\|extracted from' --include='*.ts' --include='*.tsx' --include='*.py' --include='*.js'

# Empty catch blocks
grep -rn -P 'catch.*\{\s*\}' --include='*.ts' --include='*.tsx' --include='*.js'

# Broad catch-all
grep -rn 'catch\s*(.*)\s*{' --include='*.ts' --include='*.tsx' --include='*.js'
```

### Deduplication (no good tool — agent assesses)

```bash
# Find functions with similar names across files
grep -rn 'function\|const.*=.*=>' --include='*.ts' | sort | uniq -d -f2

# jscpd if available
npx jscpd src/ 2>/agent-team:dev/null
```

### Type consolidation (agent assesses)

```bash
grep -rn 'interface\|type ' --include='*.ts' | sort
```

See [references/judgment-guide.md](references/judgment-guide.md) for detailed criteria on each finding type.

---

## Phase 2: Agent Judgment

Tools found candidates — now decide what to do.

### Filter findings

For each finding, classify as:

| Action | Meaning |
|--------|---------|
| **implement** | High confidence, low risk, clear justification |
| **review** | Needs human judgment — flag with reasoning |
| **skip** | False positive, intentional design, or not actually an issue |

### What tools get wrong (always verify manually)

- **Dead code tools**: False positives on code loaded via dynamic import, reflection, config, plugin registration, framework conventions, or string-referenced paths
- **Circular dep tools**: May flag acceptable patterns (type-only imports, interface segregation)
- **Lint rules**: May conflict with project conventions — check existing suppressions
- **Type checkers**: `unknown` at API boundaries is often correct

### What agents should focus judgment on

- **Deduplication**: Would consolidating obscure intent? Is the "shared" version harder to understand than the two specific ones?
- **Error handling**: Does the catch serve recovery, cleanup, logging, or user-facing display? If yes, keep. If it's hiding errors with no justification, remove.
- **Comments**: Does it help a new engineer understand *why* the code exists? If yes, keep. If it describes *what happened* during an edit, remove.
- **Types**: Is `any` at a genuine boundary (parsing, serialization, interop)? Preserve. Is it laziness? Replace.

---

## Implementation Rules

1. **One concern per commit** — group related changes, don't mix tracks
2. **Explain why it's safe** — for every removal, state what was verified
3. **No speculative rewrites** — only fix what tools found or what you can point to
4. **No behavior changes** — unless clearly intended and justified
5. **Preserve compatibility** — don't remove anything used by config, plugins, tests, or external consumers
6. **Small patches** — easier to review, easier to revert
7. **Flag risk** — medium and high risk findings get flagged, not auto-implemented

---

## Validation

After each batch of changes:

```bash
# Run whatever the project uses
npm test / pytest / go test ./... / cargo test 2>&1
npx tsc --noEmit / mypy / go vet / cargo clippy 2>&1
npx eslint . / ruff check . / staticcheck ./... / cargo clippy 2>&1
npm run build / python -m build / go build ./... / cargo build 2>&1
```

If anything fails: revert the batch, investigate, decide whether to fix or skip.

---

<output_format>
## Slop Check Report: <project>

### Findings
- Total: X
- Implemented: X (high confidence, low risk)
- Flagged for review: X (needs human judgment)
- Skipped: X (false positive or intentional)

### Implemented Changes
| File | Change | Why safe |
|------|--------|----------|
| `foo.ts` | Removed unused function `bar` | Not referenced anywhere, no dynamic imports |

### Flagged for Review
| File | Finding | Why flagged |
|------|---------|-------------|
| `baz.ts` | Circular dep with `qux.ts` | May require architectural change |

### Risks
- <anything needing human verification>

### Assumptions
- <anything uncertain>
</output_format>
