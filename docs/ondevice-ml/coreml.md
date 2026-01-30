# Core ML integration

## Loading and caching
- Load once, store in a singleton or DI container.
- Consider using an actor for thread-safe inference if needed.

## Pre/post-processing
- Make preprocessing explicit (resize images, normalize values, shape arrays).
- Keep transformations testable (pure functions).

## Error handling
- Provide a safe fallback UX when inference fails or model unavailable.
- Never crash on malformed input.

## watchOS considerations
- Keep models small if running on watch.
- Prefer doing heavy inference on iPhone and sending results to watch.
