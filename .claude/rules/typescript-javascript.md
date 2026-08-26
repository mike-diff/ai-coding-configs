---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/*.cjs"
---

# TypeScript / JavaScript Style

Loads only when Claude works with matching files.

- Use modern JavaScript/TypeScript (ES6+)
- Strict TypeScript: zero `any`, no `@ts-ignore`
- Prefer interfaces over types for object shapes; export types alongside implementations
- Prefer `const` over `let`, never `var`
- Use async/await over callbacks
- Comments: governed by the Comments section of `coding-standards`
- Keep functions focused and reasonably sized
