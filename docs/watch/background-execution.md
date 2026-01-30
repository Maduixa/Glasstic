# watchOS background execution

## Tools
- `HKWorkoutSession` + live builder for continuous sensor access during workouts
- `WKExtendedRuntimeSession` for limited extended background processing (non-workout)
- Background refresh for periodic updates (budgeted)

## Guidance
- Use workout sessions only when aligned with user intent and UI indicates an active session.
- Avoid frequent refresh; update widgets/complications sparingly.
- Always test real-world scenarios (watch locked, AOD, low battery, low connectivity).
