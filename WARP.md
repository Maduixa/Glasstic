# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Glasstic is an iOS intermittent fasting tracking application built with SwiftUI. It features a glassmorphic UI design with animated visual elements, comprehensive fasting tracking, gamification features, HealthKit integration, and Apple Watch connectivity.

## Common Commands

### Build & Run
```bash
# Build the project
xcodebuild -project Glasstic.xcodeproj -scheme Glasstic -configuration Debug build

# Build for release
xcodebuild -project Glasstic.xcodeproj -scheme Glasstic -configuration Release build

# Clean build folder
xcodebuild -project Glasstic.xcodeproj -scheme Glasstic clean

# Run on simulator (replace device ID)
xcrun simctl boot "iPhone 15 Pro"
xcodebuild -project Glasstic.xcodeproj -scheme Glasstic -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Open in Xcode
open Glasstic.xcodeproj
```

### Code Analysis
```bash
# Find Swift files
find . -name "*.swift" -type f

# Search for specific patterns in code
grep -r "FastingState" --include="*.swift" .
grep -r "@Published" --include="*.swift" .
grep -r "ObservableObject" --include="*.swift" .
```

## Architecture Overview

### Core Components

**App Entry Point**
- `App.swift` / `GlassticApp.swift`: Main app entry point using SwiftUI App protocol

**Main State Management**
- `FastingManager` (in ContentView.swift): Central ObservableObject managing fasting sessions, timers, and state persistence
- Uses UserDefaults with App Group for data sharing with Watch extension
- Handles Live Activity creation/updates for iOS 16+ Dynamic Island integration

**Manager Layer** (Singleton Pattern)
- `HealthKitManager`: HealthKit integration for saving fasting data as HKCategorySample
- `NotificationManager`: Local notifications for fasting completion
- `GamificationManager`: Achievement system with persistent UserProfile storage
- `WatchConnectivityManager`: WatchConnectivity framework for Apple Watch sync

**Data Models**
- `FastingZone`: Defines fasting phases (Anabolic, Catabolic, Fat Burning, Ketosis, Autophagy, Deep Autophagy) with durations, colors, and educational content
- `FastingPlan`: Predefined fasting schedules (16:8, 18:6, 20:4, OMAD)
- `UserProfile`: Codable gamification data (streaks, badges, completion stats)
- `FastingActivityAttributes`: ActivityKit Live Activity attributes for iOS 16+

**UI Layer** (SwiftUI)
- `ContentView`: Main fasting interface with glassmorphic design
- `GaugeView`: Animated circular progress gauge with wave animation
- `PlanSelectorView`: Fasting plan selection with preset and custom options
- `OnboardingView`, `CalendarView`, `ProfileView`: Supporting views

### Key Patterns

**State Synchronization**
The app uses a multi-layer state sync approach:
1. FastingManager publishes state changes via @Published properties
2. Changes trigger UserDefaults persistence and Watch connectivity updates
3. Timer-based updates occur every 1 second with Live Activity updates every 30 seconds

**Glassmorphic UI Design**
- Consistent use of `.ultraThinMaterial` backgrounds
- `LinearGradient` overlays with opacity variations
- `Circle().stroke()` with gradient borders for glass effects
- Custom `WaveShape` animation in gauge visualization

**Timer Management**
- Robust timer lifecycle handling with cleanup on state changes
- Date-based elapsed time calculation for accuracy across app launches
- Automatic fasting completion when goal duration is reached

**Cross-Platform Integration**
- App Groups for data sharing between main app and potential extensions
- WatchConnectivity for real-time Watch app synchronization
- ActivityKit for Live Activities (requires iOS 16+)
- HealthKit integration with proper authorization flow

### Data Flow

1. User selects fasting plan → `FastingManager.startFasting()`
2. Timer starts, Live Activity created, notification scheduled
3. Every second: elapsed time calculated from start date
4. Every 30 seconds: Live Activity updated with current zone and progress
5. On completion: HealthKit save, gamification processing, Live Activity ended

### Dependencies & Frameworks

- SwiftUI (UI framework)
- ActivityKit (Live Activities)
- HealthKit (Health data integration)
- WatchConnectivity (Apple Watch sync)
- UserNotifications (Local notifications)
- Foundation (Core functionality)

### File Structure Logic

- `/Models`: Data structures and business logic entities
- `/Managers`: Service layer singletons handling external integrations
- `/Views`: SwiftUI views organized by feature/screen
- Root level: Main app files and primary ContentView

The architecture follows SwiftUI best practices with clear separation between UI, business logic, and data persistence layers. The glassmorphic design system is consistently applied throughout the UI components.
