# WatchConnectivity patterns

## When to use what
- `sendMessage`: interactive request/response when counterpart reachable
- `updateApplicationContext`: “latest state” sync, delivered opportunistically
- `transferUserInfo`: queue non-urgent messages
- `transferFile`: large payloads

## Message schema strategy
- Version your messages:
  - `schemaVersion: 1`
  - `kind: "requestSteps"` / `"replySteps"`
- Keep payloads small
- Use Codable structs where possible

## Failure handling
- Not reachable: fall back to app context
- Timeouts: show UI “last updated” timestamp
- Conflicts: iPhone is source of truth for history; watch for live session
