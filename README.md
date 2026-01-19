# Glasstic - Liquid Glass iOS App

Single-screen fasting timer showcasing iOS 26 Liquid Glass styling. The app targets iOS 26 only and uses a workspace + SPM package layout; all feature code lives in the Swift package.

## Requirements
- Xcode (iOS 26 SDK) with Swift 6.2 toolchain
- Deployment target: iOS 26
- Open `Glasstic.xcworkspace`

## Build & Run
- Simulator (recommended): use the XcodeBuildMCP helpers, e.g. `build_run_sim` with scheme `Glasstic` and an iOS 26 simulator.
- Xcode: open the workspace, select scheme `Glasstic`, run on any iOS 26 simulator/device.

## Project Structure
```
Glasstic.xcworkspace   # open this
Glasstic/              # thin app shell (@main)
GlassticPackage/       # feature code and tests (Swift Package)
GlassticUITests/       # UI automation target
Config/                # xcconfigs and entitlements
```

## Current UI
- Glassy progress ring showing elapsed time vs target (target is adjustable in Settings)
- Zone-aware knob uses the fasting emoji and the counter uses smooth numeric transitions
- CTA below the gauge (cyan for start, muted red for end) aligned above the glass pill nav
- Bottom glass pill navigation with four tabs (Session, Insights, Rhythm, Settings) plus a drag-to-focus magnifying effect

## Notes for contributors
- Keep feature work in `GlassticPackage/Sources/GlassticFeature/`
- Package manifest is `// swift-tools-version: 6.2` with `.iOS(.v26)`
- If you add assets, prefer SPM resources under the package
- Follow the Liquid Glass theme (cyan accent on a dark glass background) unless intentionally changing the palette
