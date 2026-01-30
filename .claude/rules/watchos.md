---
paths:
  - "**/*.swift"
---

# watchOS companion rules

## UX
- Glanceable first: show key metric in 1–2 seconds.
- Avoid deep navigation; prefer 1–2 levels max.
- Touch targets must remain large; keep layouts simple.

## Connectivity
- Use `sendMessage` for interactive requests; fall back to `updateApplicationContext` for state sync.
- Handle not‑reachable cases explicitly.
- Keep payloads small; use transfers for large items.

## Background / runtime
- Only use extended runtime or workout sessions when justified.
- Be battery‑aware; minimize refresh frequency.

## Multi-target project
- Always specify which target a file belongs to.
- Shared code should live in a common module or shared group with `#if os(watchOS)` guards as needed.
