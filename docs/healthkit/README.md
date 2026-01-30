# HealthKit integration (iOS 26+ / watchOS 26+)

## Setup checklist
1. Enable HealthKit capability in Xcode (iOS + watch targets as needed).
2. Add Info.plist usage strings (share/update).
3. Request authorization for minimal read/write types.
4. Implement queries (stats, anchored, observer) with explicit predicates.
5. Add a review checklist (privacy + user value).

## Key principles
- Minimize data access; request only what you use.
- Handle authorization denial gracefully.
- Use aggregates when possible (avoid pulling raw samples you don’t need).
- Never block observer completions; offload heavy work.
