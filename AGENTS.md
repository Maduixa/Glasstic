# AI Agent Guide for Glasstic

**Read this first to understand the codebase structure and available resources.**

Always use Context7 MCP when I need library/API documentation, code generation, setup or configuration steps without me having to explicitly ask.

## Project Overview

- **Platform**: iOS 26+ / watchOS 26+
- **Language**: Swift 6.1+ with strict concurrency
- **UI Framework**: SwiftUI with Liquid Glass design system
- **Architecture**: Model-View (MV) pattern using @Observable and @State
- **Features**: Health tracking, Watch companion, on-device ML
- **Testing**: Swift Testing framework (@Test, #expect)

## Quick Architecture Facts

- All features live in `GlassticPackage/` (Swift Package)
- App target is minimal wrapper in `Glasstic/`
- iOS 26+ APIs with fallbacks for older versions
- Strict Swift Concurrency (async/await, @MainActor, actors)
- No ViewModels - use SwiftUI native state management

---

## Reference Documents by Domain

### 🔷 Liquid Glass (iOS 26+)

**Read these when implementing translucent UI, glass effects, or morphing transitions:**

- **[liquid-glass.md](./liquid-glass.md)** - **PRIMARY REFERENCE**
  Comprehensive API documentation with signatures, variants, modifiers, best practices, common patterns, and code examples. Always consult this first for glass-related work.

- **[docs/liquidglass/README.md](./docs/liquidglass/README.md)** - Design intent and implementation guidance

- **[docs/liquidglass/api-cheatsheet.md](./docs/liquidglass/api-cheatsheet.md)** - Quick reference patterns

- **[docs/liquidglass/performance.md](./docs/liquidglass/performance.md)** - Performance considerations

- **[examples/LiquidGlassCard.swift](./examples/LiquidGlassCard.swift)** - Working code example

**Critical API Pattern:**
```swift
.glassEffect(.regular.interactive())  // ✅ Correct
.glassEffect(.regular, in: .capsule)  // ✅ Correct
```

---

### ❤️ HealthKit Integration

**Read these when working with health data, authorization, or queries:**

- **[docs/healthkit/README.md](./docs/healthkit/README.md)** - Overview and setup

- **[docs/healthkit/authorization.md](./docs/healthkit/authorization.md)** - Permission patterns

- **[docs/healthkit/queries.md](./docs/healthkit/queries.md)** - Data querying strategies

- **[docs/healthkit/workouts.md](./docs/healthkit/workouts.md)** - Workout handling

- **[docs/healthkit/review-checklist.md](./docs/healthkit/review-checklist.md)** - App Store compliance

- **[examples/HealthStoreManager.swift](./examples/HealthStoreManager.swift)** - Working implementation

- **[templates/healthkit-entitlements.entitlements](./templates/healthkit-entitlements.entitlements)** - Required entitlements

- **[templates/Info.plist.healthkit.md](./templates/Info.plist.healthkit.md)** - Required privacy strings

---

### ⌚ watchOS Companion

**Read these when implementing Watch app features or connectivity:**

- **[docs/watch/README.md](./docs/watch/README.md)** - Watch app overview

- **[docs/watch/watchconnectivity.md](./docs/watch/watchconnectivity.md)** - WCSession patterns

- **[docs/watch/dual-target-xcode.md](./docs/watch/dual-target-xcode.md)** - Xcode project setup

- **[docs/watch/background-execution.md](./docs/watch/background-execution.md)** - Background delivery

- **[examples/WatchConnectivityPhone.swift](./examples/WatchConnectivityPhone.swift)** - iOS side

- **[examples/WatchConnectivityWatch.swift](./examples/WatchConnectivityWatch.swift)** - watchOS side

- **[examples/StepComplicationWidget.swift](./examples/StepComplicationWidget.swift)** - Complication example

---

### 🧠 On-Device ML (Core ML)

**Read these when implementing ML features or model integration:**

- **[docs/ondevice-ml/README.md](./docs/ondevice-ml/README.md)** - ML overview

- **[docs/ondevice-ml/coreml.md](./docs/ondevice-ml/coreml.md)** - Core ML integration

- **[docs/ondevice-ml/deployment.md](./docs/ondevice-ml/deployment.md)** - Model deployment

- **[docs/ondevice-ml/privacy.md](./docs/ondevice-ml/privacy.md)** - Privacy considerations

- **[examples/CoreMLInference.swift](./examples/CoreMLInference.swift)** - Working example

---

### 🔬 Testing & Quality

**Read these when writing tests or ensuring quality:**

- **[docs/testing/README.md](./docs/testing/README.md)** - Testing overview

- **[docs/testing/unit-tests.md](./docs/testing/unit-tests.md)** - Swift Testing patterns

- **[docs/testing/ui-tests.md](./docs/testing/ui-tests.md)** - UI automation

- **[docs/testing/accessibility-audit.md](./docs/testing/accessibility-audit.md)** - Accessibility checklist

- **[docs/testing/liquidglass-validation.md](./docs/testing/liquidglass-validation.md)** - Glass effect testing

- **[docs/testing/ml-validation.md](./docs/testing/ml-validation.md)** - ML model validation

---

### 📋 App Store & Compliance

**Read these when preparing for submission or review:**

- **[docs/compliance/README.md](./docs/compliance/README.md)** - Compliance overview

- **[docs/compliance/app-store-review.md](./docs/compliance/app-store-review.md)** - Review guidelines

- **[docs/risk-matrix.md](./docs/risk-matrix.md)** - Risk assessment

---

### 🔄 Workflows & Patterns

**Read these to understand development processes:**

- **[docs/workflows/agentic-workflow.md](./docs/workflows/agentic-workflow.md)** - Iteration loop (prompt → plan → implement → verify → harden)

- **[docs/workflows/prompt-templates.md](./docs/workflows/prompt-templates.md)** - Common task patterns

- **[docs/workflows/conversation-playbooks.md](./docs/workflows/conversation-playbooks.md)** - Conversation strategies

- **[docs/workflows/mcp.md](./docs/workflows/mcp.md)** - MCP integration

---

## Development Rules (Auto-Loaded)

These rules automatically apply when working on Swift files (if using Claude Code):

- **[.claude/rules/swift-style.md](./.claude/rules/swift-style.md)** - Swift style guide
- **[.claude/rules/swiftui-liquidglass.md](./.claude/rules/swiftui-liquidglass.md)** - Glass usage rules
- **[.claude/rules/healthkit.md](./.claude/rules/healthkit.md)** - HealthKit constraints
- **[.claude/rules/watchos.md](./.claude/rules/watchos.md)** - watchOS guidelines
- **[.claude/rules/coreml-apple-ai.md](./.claude/rules/coreml-apple-ai.md)** - ML best practices
- **[.claude/rules/testing.md](./.claude/rules/testing.md)** - Testing standards
- **[.claude/rules/compliance.md](./.claude/rules/compliance.md)** - Compliance rules

---

## Specialist Agents (Documentation)

Role descriptions for domain specialists (`.claude/agents/`):

- **ios-architect** - File structure, build, architecture decisions
- **liquidglass-ui-engineer** - Glass components, accessibility, performance
- **healthkit-specialist** - Authorization, queries, compliance
- **watchos-specialist** - Connectivity, glanceable UI, complications
- **ondevice-ml-specialist** - Core ML pipelines, validation
- **appstore-reviewer** - Compliance, App Store risk assessment

---

## Utilities

- **[scripts/sdk_verify.sh](./scripts/sdk_verify.sh)** - Verify SDK symbols (usage: `bash scripts/sdk_verify.sh glassEffect`)
- **[docs/00_INDEX.md](./docs/00_INDEX.md)** - Full documentation index
- **[docs/diagrams/architecture.md](./docs/diagrams/architecture.md)** - Architecture diagrams

---

## Default Development Workflow

1. **Clarify** - Understand feature intent and constraints
2. **Plan** - List files to create/edit, verify APIs exist in SDK
3. **Implement** - Minimal working slice
4. **Build & Test** - Use XcodeBuildMCP tools to build and run
5. **Harden** - Add tests, accessibility, performance checks
6. **Commit** - Small, focused commits

---

## Critical Guidelines

### Liquid Glass
- Use for **navigation/controls only**, never content areas
- Always use `.interactive()` for touch targets
- Group multiple glass elements in `GlassEffectContainer`
- Verify API availability with `scripts/sdk_verify.sh`

### HealthKit
- Minimize data access - request only what's needed
- Process health data on-device
- Never log sensitive information
- Follow App Store review checklist

### Swift Concurrency
- All UI updates use `@MainActor`
- Use `.task { }` on views, not `Task { }` in `onAppear`
- Prefer async/await over completion handlers
- Ensure Sendable conformance for cross-actor types

### Testing
- Use Swift Testing framework (`@Test`, `#expect`)
- Test accessibility with Reduce Transparency/Contrast ON
- Profile performance for glass-heavy screens
- Validate ML models before deployment

---

## For AI Coding Assistants

**When starting work on this repo:**

1. Read this AGENTS.md file first
2. Check `liquid-glass.md` for glass-related tasks
3. Consult domain-specific docs in `docs/[domain]/`
4. Use examples in `examples/` as starting points
5. Verify beta APIs with `scripts/sdk_verify.sh`

**When unsure:**
- Read the relevant `docs/` section
- Check existing code patterns in `GlassticPackage/Sources/`
- Consult `CLAUDE.md` for project structure

---

## Cross-Tool Compatibility

This documentation structure works across:
- ✅ Claude Code (auto-loads `.claude/rules/`)
- ✅ Cursor (reads AGENTS.md)
- ✅ GitHub Copilot (context from markdown files)
- ✅ Aider (can reference docs)
- ✅ Any AI assistant (just point to this file)
