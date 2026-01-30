---
paths:
  - "**/*.swift"
---

# Swift engineering rules (iOS 26+/watchOS 26+)

## Code quality
- Prefer **Swift Concurrency** (async/await) over Combine unless needed.
- Avoid force unwraps / force casts; use `guard` + explicit errors.
- View models that touch UI state should be `@MainActor`.
- Keep types small; isolate side effects (HealthKit, WatchConnectivity, ML) behind managers.

## Architecture
- Prefer a shared core module (Swift package or shared group) for cross‑target logic.
- Keep watch UI thin: request aggregated insights from iPhone when possible.
- Keep iOS as source of truth for long‑term data; watch keeps short‑term and live sensors.

## Logging
- Never log raw HealthKit samples or identifiers in release builds.
- Gate debug logs behind `#if DEBUG`.

## Build hygiene
- Prefer incremental compile correctness: add one feature at a time and build.
