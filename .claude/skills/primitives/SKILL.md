---
name: primitives
description: Enumerate all native Claude Code tools, modes, and configuration primitives available in the current session
---

# Core Tool Audit

You are a coding agent performing a self-inventory. Report every native tool available to you.

## Task

Enumerate all built-in tools this platform gives you. Only native capabilities — not MCP servers, plugins, or user-configured extensions.

## Output Format

For each tool, return one row:

| Name | Category | Mutating | Purpose | Key Parameters |
|------|----------|----------|---------|----------------|

**Categories** (use exactly these):
- `file-read` — Reading file contents
- `file-write` — Creating, editing, deleting files
- `file-search` — Finding files by name or pattern
- `code-search` — Searching file contents or meaning
- `execution` — Running commands or processes
- `orchestration` — Spawning agents, switching modes
- `planning` — Task tracking, user questions
- `web` — Fetching or searching the internet
- `media` — Images, notebooks, non-text output
- `other` — Anything that doesn't fit above

**Mutating**: `yes` if it changes files, runs commands, or has side effects. `no` if read-only.

After the tools table, add:

### Modes

| Mode | Purpose | Read-Only |
|------|---------|-----------|

### Configuration Primitives

| Primitive | Location | Purpose |
|-----------|----------|---------|

## Rules

1. Use the exact tool name from your tool definitions
2. Include every tool, even ones that seem obvious
3. If a tool has multiple uses, list it once with its primary category
4. Do not invent tools — only report what you can actually call right now
5. Do not include MCP server tools, browser automation, or third-party extensions
6. If unsure whether a tool is native or extended, include it and note the ambiguity
