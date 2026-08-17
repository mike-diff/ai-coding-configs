# MCP Response Caching

<purpose>
Prevent context window bloat during research-heavy `/agent-team:discuss` sessions by
caching large MCP tool responses to files. This enables:
- Re-reading cached data without re-calling MCP tools
- Surviving context compaction without data loss
- Reducing token usage across long sessions and multi-agent workflows
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

## When NOT to Cache

Don't cache:
- Small responses (< 100 lines)
- One-time lookups you won't reference again
- Rapidly changing data (live server status)
- Sensitive information (credentials, tokens)

## Research sessions

`/agent-team:discuss` runs background research subagents that can pull large MCP payloads
into the lead's context. Apply caching aggressively during long research-heavy
sessions when context pressure is highest — and have researchers return
summaries with cache paths, not full payloads, in their results.

`.context/` is ephemeral session data and belongs in `.gitignore`.
