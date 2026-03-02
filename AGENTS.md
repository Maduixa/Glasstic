# Glasstic — Project Knowledge Base

**Generated:** 2026-03-02 | **Commit:** 648f7a4 | **Branch:** fix/pill-menu-artifacts

## Overview

Single-screen fasting timer for iOS 26 showcasing Liquid Glass design. Workspace + SPM package layout: all feature code lives in the Swift package, app target is a thin shell.

**Stack:** Swift 6.2 · SwiftUI · iOS 26 only · SwiftData · Liquid Glass · Metal shaders
**Architecture:** Model-View (MV) with `@Observable` + typed `@Environment` injection — no ViewModels pattern

## Structure

```
Glasstic/                        # App shell — @main entry, legacy views (see Glasstic/AGENTS.md)
GlassticPackage/                 # All feature code — canonical location for new work
  Sources/GlassticFeature/       # Single library target (see GlassticFeature/AGENTS.md)
    Models/                      #   FastingSession (@Model, SwiftData)
    ViewModels/                  #   FastingStore (@Observable, @MainActor)
    Views/                       #   GlassmorphicGauge, reusable views
    Services/                    #   DataService (SwiftData persistence, singleton)
    Theme/                       #   AppTheme (@Observable, multi-theme palettes)
    Utilities/                   #   RefractiveGlass, GelPhysics, GlassButtonStyle
    Shaders/                     #   LiquidGlass.metal (refractive shader)
    ContentView.swift            #   945-line main view — session/settings/tabs
  Tests/GlassticFeatureTests/    # Swift Testing (stub only — needs real tests)
GlassticUITests/                 # UI automation target (stub)
Config/                          # xcconfig files + entitlements
docs/                            # Domain reference docs (see WHERE TO LOOK)
examples/                        # Reference implementations (HealthKit, WatchConnectivity, CoreML, Glass)
scripts/                         # sdk_verify.sh — verify beta API symbols
templates/                       # HealthKit entitlements + Info.plist templates
liquid-glass.md                  # PRIMARY Liquid Glass API reference (577 lines)
```

## Where to Look

| Task | Location | Notes |
|------|----------|-------|
| Add/modify features | `GlassticPackage/Sources/GlassticFeature/` | All new code goes here |
| App entry / environment setup | `Glasstic/GlassticApp.swift` | Injects FastingStore, AppTheme, modelContainer |
| Fasting logic / timer | `GlassticFeature/ViewModels/FastingStore.swift` | @Observable, @MainActor, delegates to DataService |
| Persistence | `GlassticFeature/Services/DataService.swift` | SwiftData ModelContainer, singleton |
| Theme system | `GlassticFeature/Theme/AppTheme.swift` | 5 themes (ocean/ember/forest/twilight/mono) |
| Glass effects | `liquid-glass.md` then `GlassticFeature/Utilities/RefractiveGlass.swift` | Metal shader in Shaders/ |
| Navigation UI | `GlassticFeature/ContentView.swift` | Custom BottomPillMenu (not TabView) |
| Build config | `Config/*.xcconfig` | Debug/Release/Shared/Tests configs |
| Entitlements | `Config/Glasstic.entitlements` | Edit XML directly to add capabilities |
| HealthKit docs | `docs/healthkit/` | Authorization, queries, workouts, review checklist |
| Watch docs | `docs/watch/` | WCSession, background execution, dual-target setup |
| ML docs | `docs/ondevice-ml/` | CoreML integration, deployment, privacy |
| Testing docs | `docs/testing/` | Unit, UI, accessibility, glass validation |
| Compliance docs | `docs/compliance/` | App Store review, risk matrix at `docs/risk-matrix.md` |

## Code Map — Key Types

| Symbol | Type | Location | Role |
|--------|------|----------|------|
| `FastingStore` | @Observable class | `GlassticFeature/ViewModels/` | Central state: timer, progress, start/end fasting |
| `FastingSession` | @Model class | `GlassticFeature/Models/` | SwiftData entity: startDate, endDate, duration |
| `DataService` | @MainActor class | `GlassticFeature/Services/` | Singleton persistence layer, provides ModelContainer |
| `AppTheme` | @Observable class | `GlassticFeature/Theme/` | Current theme selection, palette access |
| `AppThemeStyle` | enum | `GlassticFeature/Theme/` | 5 color themes with zone/background palettes |
| `ContentView` | struct (View) | `GlassticFeature/` | Main view: tab switching, session UI, settings |
| `GlassmorphicGauge` | struct (View) | `GlassticFeature/Views/` | Progress ring with zone-aware styling |
| `BottomPillMenu` | struct (View) | `GlassticFeature/ContentView.swift` | Glass pill nav with drag-to-focus magnifier |
| `RefractiveGlass` | utilities | `GlassticFeature/Utilities/` | Refractive glass shader helpers |
| `GelPhysics` | @Observable class | `GlassticFeature/Utilities/` | Physics simulation for gel/spring effects |

## Conventions

**State flow:** `GlassticApp` creates `@State FastingStore` + `@State AppTheme` → injects via `.environment()` → views read via `@Environment(Type.self)`

**Concurrency:** Every UI-facing class is `@MainActor`. Timer callbacks marshal via `Task { @MainActor in }`. No GCD, no Combine.

**Persistence:** SwiftData only. `DataService.shared` is the single access point. `UserDefaults` for preferences (target duration, theme selection).

**Package.swift:** `// swift-tools-version: 6.2`, single target `GlassticFeature`, platform `.iOS(.v26)`.

## Anti-Patterns (This Project)

- **No ViewModels pattern** — use `@Observable` stores + SwiftUI state. Never create `*ViewModel` classes.
- **No `Task {}` in `onAppear`** — always use `.task { }` modifier for lifecycle-managed async work.
- **No glass on content** — Liquid Glass is navigation/controls only. Never apply to cards, lists, or content surfaces.
- **No glass stacking** — avoid glass-on-glass (performance + contrast problems).
- **No force unwraps** — use `guard let` with explicit error paths.
- **No health data logging** — never log HealthKit samples or identifiers in release.
- **No CoreData** — SwiftData only for persistence.
- **No Combine** — Swift Concurrency (async/await) only.

## Gotchas

- **Two FastingStore implementations exist**: `GlassticPackage/.../FastingStore.swift` (@Observable, canonical) and `Glasstic/ViewModels/FastingStore.swift` (legacy ObservableObject). The package version is authoritative — the app shell version is leftover.
- **ContentView.swift is 945 lines** — contains BottomPillMenu, SettingsPanel, PlaceholderTab, LiquidBackground, action button, session editing. Needs decomposition.
- **Test suite is a stub** — `GlassticFeatureTests.swift` has one empty placeholder test. No real test coverage.
- **Package excludes files**: `exclude: ["CLAUDE.md", "Glasstic", "GlassticPackage"]` in Package.swift — watch for stray files.
- **Metal shader** at `Shaders/LiquidGlass.metal` — custom refractive glass effect used by bottom pill menu.

## Commands

```bash
# Build (via XcodeBuildMCP — preferred)
# build_sim_name_ws(workspacePath: "Glasstic.xcworkspace", scheme: "Glasstic", simulatorName: "iPhone 16")

# Verify beta API symbol exists in SDK
bash scripts/sdk_verify.sh glassEffect

# Tests (via XcodeBuildMCP)
# test_sim_name_ws(workspacePath: "Glasstic.xcworkspace", scheme: "Glasstic", simulatorName: "iPhone 16")

# Open workspace
open Glasstic.xcworkspace
```

## Reference Docs Index

| Domain | Primary Doc | Examples |
|--------|------------|----------|
| Liquid Glass | `liquid-glass.md` | `examples/LiquidGlassCard.swift` |
| HealthKit | `docs/healthkit/README.md` | `examples/HealthStoreManager.swift` |
| watchOS | `docs/watch/README.md` | `examples/WatchConnectivity*.swift` |
| Core ML | `docs/ondevice-ml/README.md` | `examples/CoreMLInference.swift` |
| Testing | `docs/testing/README.md` | — |
| Compliance | `docs/compliance/README.md` | `docs/risk-matrix.md` |
| Workflows | `docs/workflows/agentic-workflow.md` | `docs/workflows/prompt-templates.md` |

## Rules (Auto-Loaded by Claude Code)

`.claude/rules/`: swift-style, swiftui-liquidglass, healthkit, watchos, coreml-apple-ai, testing, compliance — applied automatically on `.swift` and `.md` files.
