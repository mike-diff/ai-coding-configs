---
description: "Required output formats for subagents in the /dev workflow"
globs:
  - ".cursor/agents/*.md"
alwaysApply: false
---

# Subagent Output Requirements

All subagents MUST return structured result blocks. The orchestrator verifies these before proceeding.

## Explorer Result

```xml
<explorer-result>
status: COMPLETE
files_analyzed: [number]
essential_files: [number]
patterns_found: [number]
</explorer-result>
```

Required sections:
- Summary (2-3 sentences)
- Essential Files (table)
- Patterns to Follow (numbered list)
- Files to Modify/Create
- Concerns

## Implementer Result

```xml
<implementer-result>
status: COMPLETE
files_modified: [number]
files_created: [number]
lines_changed: [number]
</implementer-result>
```

Required sections:
- Changes Made (per file)
- Implementation Notes
- Potential Issues
- Ready for Review checklist

## Checker Result

```xml
<checker-result>
status: [PASS | FAIL]
lint_status: [PASS | FAIL | SKIPPED]
typecheck_status: [PASS | FAIL | SKIPPED]
error_count: [number]
warning_count: [number]
</checker-result>
```

Required sections:
- Commands Run
- Errors (if any, with file/line/message)
- Warnings (if any)
- Summary

## Tester Result

```xml
<tester-result>
status: [PASS | FAIL]
total: [number]
passed: [number]
failed: [number]
skipped: [number]
</tester-result>
```

Required sections:
- Command Run
- Failed Tests (if any, with file/error)
- Summary

## Browser Result

```xml
<browser-result>
status: [PASS | FAIL | PARTIAL]
url_tested: [URL]
console_errors: [number]
interactions_tested: [number]
issues_found: [number]
</browser-result>
```

Required sections:
- Page Load status
- Visual Check
- Interactions Tested (table)
- Console errors
- Issues (if any)

## Scout Result (/discuss)

```xml
<scout-result>
status: COMPLETE
files_analyzed: [number]
patterns_found: [number]
integration_points: [number]
</scout-result>
```

Required sections:
- Summary (2-3 sentences)
- Existing patterns or current implementation analysis
- Integration points or issues found
- Constraints from architecture

## Research Result (/discuss)

```xml
<research-result>
status: COMPLETE
sources_consulted: [number]
libraries_found: [number]
key_insights: [number]
</research-result>
```

Required sections:
- Prior art summary
- Libraries/tools with versions
- Best practices and pitfalls
- Key insights (3-5 bullets)

## Challenge Result (/discuss)

```xml
<challenge-result>
status: COMPLETE
feasibility: [CONFIRMED | CONCERNS]
alternatives_found: [number]
risks_identified: [number]
missing_pieces: [number]
</challenge-result>
```

Required sections:
- Feasibility assessment
- Alternatives (if any)
- Risks with impact ratings
- Missing pieces

## Blind Spot Result (/discuss)

```xml
<blindspot-result>
status: COMPLETE
blind_spots_found: [number]
plan_changes_needed: [yes/no]
</blindspot-result>
```

Required sections:
- Native features check
- Recent changes check
- Simpler alternatives check
- Assumption verification

## Dependency Result (/discuss DEEPEN)

```xml
<dependency-result>
status: COMPLETE
dependencies_researched: [number]
versions_pinned: [number]
api_patterns_extracted: [number]
</dependency-result>
```

Required sections:
- Dependencies by phase
- Pinned versions
- Key API patterns per dependency

## Validation

The orchestrator validates:
1. Result block is present
2. Status field is valid
3. Required fields have values
4. Content matches status (e.g., FAIL has error details)

If validation fails, the orchestrator re-delegates with specific feedback.
