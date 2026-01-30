# Workout tracking

## Live sessions (watch preferred)
- Use `HKWorkoutSession` + `HKLiveWorkoutBuilder`
- Display clear UI indicating a live session
- Save workout to HealthKit on completion

## iPhone workouts
If using iPhone-only workouts, ensure required permissions and consider external sensor support where available.

## Data model
Treat the saved `HKWorkout` as the canonical object for a workout session.
Link associated samples via queries when needed.
