# Authorization patterns

## Info.plist keys
- `NSHealthShareUsageDescription`: why you need read access
- `NSHealthUpdateUsageDescription`: why you need write access (if writing)

## Swift pattern (async/await)
Prefer wrapping callback APIs into `async` functions if needed.
Always check HealthKit availability:
- HealthKit not available on some devices / configurations

## UX
- Prompt at the moment of value (not on first launch) unless the whole app depends on it.
- Show a post-permission screen that confirms what’s enabled and how to change it.
