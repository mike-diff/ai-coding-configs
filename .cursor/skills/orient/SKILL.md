---
name: orient
description: "Build comprehensive understanding of a codebase. Maps tech stack, architecture, entry points, and patterns. Use when starting work on an unfamiliar codebase or onboarding to a new project."
disable-model-invocation: true
---

# /orient — Codebase Proficiency

Build comprehensive understanding of the codebase before starting work.

## Workflow

<workflow>
Phase 1 - Project Identity:
- Read AGENTS.md and README.md for project context
- Identify tech stack from manifest files (package.json, pyproject.toml, etc.)
- Understand the project's purpose and architecture

Phase 2 - Structure Mapping:
- Explore directory structure
- Identify key modules and their responsibilities
- Map entry points and main code paths

Phase 3 - Pattern Recognition:
- Note coding conventions and patterns used
- Identify abstractions and how they're applied
- Understand testing approach and file organisation

Phase 4 - Synthesise:
- Build mental model of how components connect
- Identify the most important files to understand
- Present orientation summary
</workflow>

## Process

### Step 1: Read Project Documentation

```bash
cat AGENTS.md README.md 2>/dev/null
cat package.json pyproject.toml Cargo.toml go.mod 2>/dev/null | head -50
```

### Step 2: Explore Structure

```bash
ls -la
ls -R src/ app/ lib/ 2>/dev/null | head -100
find . -maxdepth 3 -name "*.md" -o -name "main.*" -o -name "index.*" 2>/dev/null | head -20
```

### Step 3: Understand Patterns

Read 2-3 representative files to understand code style, module structure, import patterns, and error handling.

### Step 4: Deep Dive Key Areas

Use codebase search to understand the main entry point, core abstractions, and how components communicate.

## Output

<output_format>
```
## Codebase: [project-name]

### Tech Stack
- Language: [primary language and version]
- Framework: [main framework]
- Build: [build tool and key scripts]
- Test: [test framework]

### Architecture
[2-3 sentences describing the overall architecture]

### Key Components
- `[path]` - [responsibility]
- `[path]` - [responsibility]

### Patterns & Conventions
- [Notable pattern 1]
- [Notable pattern 2]

### Entry Points
- Main: `[file]`
- Tests: `[command]`
- Dev: `[command]`

### Understanding Checklist
- [ ] Core data flow understood
- [ ] Main abstractions identified
- [ ] Test patterns recognised
- [ ] Build process clear
```
</output_format>

## Constraints

<constraints>
FOCUS:
- Understanding over speed
- Accuracy over completeness
- Key paths over exhaustive coverage

AVOID:
- Superficial scanning without comprehension
- Suggesting changes or improvements
- Making assumptions without verification
</constraints>
