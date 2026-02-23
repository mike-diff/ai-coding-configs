# MCP Response Caching

<purpose>
Prevent context window bloat by caching large MCP tool responses to files. This enables:
- Re-reading cached data without re-calling MCP tools
- Surviving context compaction without data loss
- Reducing token usage across long /discuss sessions and multi-agent workflows
</purpose>

## When to Cache

Cache MCP responses when:
- Response exceeds **100 lines** of content
- Response contains **structured data** you'll reference multiple times
- Using tools that return large payloads:
  - `context7` documentation lookups
  - `browser` page snapshots or content extractions
  - `sequential-thinking` multi-step reasoning chains
  - Any MCP tool returning JSON > 2KB

## Caching Protocol

<protocol>
### Step 1: Detect Large Response

After an MCP tool call, check if the response is large:
- More than 100 lines
- Contains documentation, page content, or structured data
- Will likely be referenced again

### Step 2: Save to Cache

```bash
mkdir -p .context/mcp-cache

# Format: [mcp-server]-[tool]-[descriptor]-[timestamp].md
cat > .context/mcp-cache/context7-query-react-hooks-20260116.md << 'EOF'
# MCP Cache: context7 query-docs
# Query: "React hooks patterns"
# Cached: 2026-01-16T14:30:00Z

[Full response content here]
EOF
```

### Step 3: Note the Cache Path

When caching, note the file path in your response:
```
📦 Cached to `.context/mcp-cache/context7-query-react-hooks-20260116.md`
```

### Step 4: Reference from Cache

For subsequent references, read from cache instead of re-calling:
```bash
cat .context/mcp-cache/context7-query-react-hooks-20260116.md
```
</protocol>

## Cache Directory Structure

```
.context/
└── mcp-cache/
    ├── context7-query-[topic]-[timestamp].md
    ├── browser-snapshot-[page]-[timestamp].md
    ├── browser-content-[page]-[timestamp].md
    └── thinking-[task]-[timestamp].md
```

## Cache Naming Convention

| MCP Server | Tool | Filename Pattern |
|------------|------|------------------|
| context7 | query-docs | `context7-query-[topic]-[ts].md` |
| context7 | resolve-library-id | `context7-resolve-[lib]-[ts].md` |
| browser (Chrome) | snapshot | `browser-snapshot-[page]-[ts].md` |
| browser (Chrome) | content | `browser-content-[page]-[ts].md` |
| sequential-thinking | sequentialthinking | `thinking-[task]-[ts].md` |

## When NOT to Cache

Don't cache:
- Small responses (< 100 lines)
- One-time lookups you won't reference again
- Rapidly changing data (live server status)
- Sensitive information (credentials, tokens)

## /discuss Sessions

The `/discuss` command spawns 4-5 research agents, each capable of pulling large MCP payloads into the lead's context. Apply caching aggressively during DEEPEN phases when context pressure is highest.

## Add to .gitignore

The `.context/` directory contains ephemeral session data:

```bash
echo ".context/" >> .gitignore
```

```gitignore
# Claude Code AI context management (ephemeral)
.context/
```
