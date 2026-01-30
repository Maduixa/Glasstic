# Dual-target Xcode structure (AI-friendly)

## Goals
Make it easy for an AI agent to:
- know which target a file belongs to
- share code safely between iOS and watchOS
- avoid accidentally importing iOS-only frameworks in watch targets

## Recommended structure
- `Sources/Shared/` (or Swift package `SharedCore/`)
  - Models, message schemas, pure functions
- `Sources/iOS/`
  - iOS UI, HealthKit store queries for full history, ML
- `Sources/watchOS/`
  - watch UI, live sessions, lightweight queries
- `Sources/Widgets/` (optional)

## Target membership conventions
- File headers: include `// Target: iOS` or `// Target: watchOS`
- Separate folders/groups in Xcode matching filesystem paths

## Conditional compilation
Use `#if os(watchOS)` for small differences.
Avoid large platform forks in the same file when it becomes unreadable.

## “AI hygiene” tips
When asking an agent to implement something:
- Ask it to list files it will edit/create first.
- Demand target membership notes per file.
- Demand a build command to validate.
