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
- Add JSDoc comments for public functions
- Include comments only where logic is non-obvious
- Keep functions focused and reasonably sized
