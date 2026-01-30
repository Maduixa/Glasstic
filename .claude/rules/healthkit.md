---
paths:
  - "**/*.swift"
  - "**/*.plist"
  - "**/*.entitlements"
---

# HealthKit rules

## Privacy first
- Request the minimum set of read/write types needed for the current feature.
- Processing should be on‑device by default; do not transmit health data off device unless explicitly required and disclosed.

## Authorization
- Always include correct Info.plist strings:
  - NSHealthShareUsageDescription
  - NSHealthUpdateUsageDescription (if writing)
- Ensure HealthKit capability is enabled for each relevant target.

## Queries
- Use the right tool for the job:
  - Statistics for aggregates
  - Anchored + Observer for near real‑time updates
- Always call observer completion handlers quickly; offload heavy work.

## Workouts
- Live monitoring should run within `HKWorkoutSession`/builder when appropriate.
- Handle “no data” and “permission denied” gracefully.
