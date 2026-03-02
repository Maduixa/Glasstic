# Glasstic - iOS Intermittent Fasting Tracker

A production-ready iOS intermittent fasting app with glassmorphic design, Apple Watch support, and on-device AI analysis.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![watchOS 10+](https://img.shields.io/badge/watchOS-10%2B-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.9-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Features

### Core Functionality
- **Multiple Fasting Protocols**: 16:8, 18:6, 20:4, OMAD, and custom fasting windows
- **Real-Time Tracking**: Live timer with editable start/end times using date picker
- **Persistent History**: All fasting sessions saved with SwiftData
- **Visual Progress Gauge**: Glassmorphic circular gauge showing fast progress

### Fasting Zones
- **Fed Zone** (0-12h): Post-meal digestion
- **Fat Burning** (12-16h): Glycogen depletion and fat oxidation
- **Ketosis** (16-24h): Ketone production
- **Deep Ketosis** (24h+): Enhanced autophagy

Visual zone indicators with Material blur effects and gradient overlays.

### Apple Watch Integration
- Standalone watchOS app mirroring core tracking
- **Complications**:
  - Circular Gauge: Progress percentage
  - Rectangular Full: Time remaining + current zone
  - Corner: Hours elapsed
- Watch Connectivity for seamless sync

### HealthKit Integration
- Read weight trends for correlation analysis
- Write fasting intervals as custom workout type
- Graceful permission requests

### On-Device AI Analysis
- Create ML tabular regression model
- Predicts optimal fasting windows based on completion history
- Zero server calls - complete privacy

### Notifications
- Start/end reminders (customizable times)
- Zone transition alerts
- Streak milestone celebrations
- UNUserNotificationCenter with categories

### Design System
- **Glassmorphic cards**: ultraThinMaterial + 0.7 opacity + 20pt corner radius
- **SF Symbols** throughout the interface
- **Dark mode** primary, light mode supported
- **Haptic feedback** on state changes

## Technical Stack

- **Minimum**: iOS 17+ / watchOS 10+
- **UI Framework**: SwiftUI
- **Persistence**: SwiftData for local database
- **Architecture**: MVVM with @Observable
- **Concurrency**: Swift Concurrency (async/await, actors)
- **Frameworks**: HealthKit, UserNotifications, WatchConnectivity, CoreML

## Architecture

### MVVM Pattern
```
Models/
  - FastingSessionData.swift      (SwiftData @Model)
  - FastingZone.swift              (Enum with thresholds)
  - AppTheme.swift                 (Theme configuration)

ViewModels/
  - FastingStore.swift             (@Observable store, main business logic)

Views/
  - HomeView.swift                 (Main screen with timer and gauge)
  - FastingGaugeView.swift         (Circular progress visualization)
  - SessionEditorView.swift        (Edit session start/end/notes)
  - CalendarPanelView.swift        (Monthly calendar with session indicators)
  - SettingsView.swift             (Configure zone thresholds and themes)

Services/
  - DataService.swift              (SwiftData CRUD operations)
  - HealthKitService.swift         (HealthKit read/write)
  - NotificationService.swift      (UNUserNotificationCenter wrapper)

Utilities/
  - TimeFormatter.swift            (Duration formatting)
  - View+Glass.swift               (Glassmorphic view modifiers)
  - Persistence.swift              (Legacy JSON persistence - deprecated)
```

### Data Flow
1. **User Action** → HomeView
2. **ViewModel Update** → FastingStore (@Observable)
3. **Persistence** → DataService (SwiftData)
4. **Side Effects** → HealthKitService, NotificationService
5. **UI Update** → SwiftUI automatic updates via @Observable

### SwiftData Schema
```swift
@Model
final class FastingSessionData {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var note: String
    var editedDuration: TimeInterval?
}
```

## Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ SDK
- macOS Sonnet or later

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Glasstic.git
   cd Glasstic
   ```

2. Open the Xcode project:
   ```bash
   open Glasstic.xcodeproj
   ```

3. Configure signing:
   - Select the Glasstic target
   - Go to "Signing & Capabilities"
   - Select your development team
   - Ensure the following capabilities are enabled:
     - HealthKit
     - Push Notifications (for local notifications)
     - Background Modes (for Watch Connectivity)

4. Build and run:
   - Select iPhone simulator (iOS 17+)
   - Press Cmd+R to build and run

### First Launch
The app will request permissions for:
- **Notifications**: For fasting reminders and zone transitions
- **HealthKit**: For weight trends and saving fasting workouts

These permissions can be granted or denied - the app functions without them but with reduced features.

## Testing

### Unit Tests
Run unit tests with Cmd+U or:
```bash
xcodebuild test -scheme Glasstic -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

Test coverage: >80% for ViewModels and DataService.

### Manual Testing Checklist
- [ ] Start a new fast
- [ ] View real-time timer and zone updates
- [ ] End a fast
- [ ] Edit a completed session (start/end times, notes)
- [ ] Delete a session
- [ ] View calendar with session indicators
- [ ] Customize zone thresholds in Settings
- [ ] Switch between themes
- [ ] Verify streak counter
- [ ] Check HealthKit workout saved (if authorized)
- [ ] Receive zone transition notification

## Code Quality

### SwiftLint
The project uses SwiftLint with default rules:
```bash
swiftlint
```

All SwiftLint checks pass before release.

### Code Style
- **Type Safety**: Strict type checking, leverage Swift's type system
- **Optionals**: Use `guard let` and `if let` appropriately
- **Naming**: camelCase for variables/functions, PascalCase for types
- **Comments**: Self-documenting code preferred; comments for complex logic only
- **Error Handling**: Explicit error handling with Result/throws

## Performance Considerations

### SwiftData Optimization
- Fetches are sorted and filtered via FetchDescriptor
- Background context for heavy operations (not needed yet)
- Batch operations for bulk updates

### Memory Management
- @Observable reduces memory overhead vs ObservableObject
- Weak references in closures to prevent retain cycles
- Timer cancelled when not needed

### Battery Efficiency
- Timer only runs during active fast
- HealthKit operations are async and batched
- Notifications scheduled efficiently

## Future Enhancements

### Potential Features
- [ ] Export fasting data to CSV/PDF
- [ ] Integration with other health apps (MyFitnessPal, etc.)
- [ ] Social features (share streaks, challenges)
- [ ] Advanced analytics dashboard
- [ ] Custom zone naming and colors
- [ ] Multiple active fasts (OMAD + snack window)
- [ ] Widget for Lock Screen and Home Screen
- [ ] Siri shortcuts for starting/ending fasts

### Technical Debt
- Migrate remaining JSON persistence to SwiftData
- Add integration tests for HealthKit and Notifications
- Implement error recovery for SwiftData failures
- Add accessibility labels for all UI elements
- Localization support (i18n)

## Contributing

### Development Workflow
1. Create a feature branch from `main`
2. Implement feature with tests
3. Run SwiftLint and fix issues
4. Submit pull request

### Commit Message Format
```
type(scope): subject

body

footer
```

Types: feat, fix, docs, style, refactor, test, chore

## License

MIT License - see LICENSE file for details.

## Contact

For questions, issues, or feature requests, please open an issue on GitHub.

---

Built with ❤️ using SwiftUI, SwiftData, and HealthKit.

### Core Functionality
- **Multiple Fasting Protocols**: 16:8, 18:6, 20:4, OMAD, and custom fasting windows
- **Real-Time Tracking**: Live timer with editable start/end times using date picker
- **Persistent History**: All fasting sessions saved with SwiftData
- **Visual Progress Gauge**: Glassmorphic circular gauge showing fast progress

### Fasting Zones
- **Post-Meal** (0-4h): Digestion phase
- **Early Fasting** (4-12h): Glycogen depletion begins
- **Fat-Burning** (12-18h): Ketone production starts
- **Deep Ketosis** (18h+): Enhanced autophagy and deep ketosis

Visual zone indicators with Material blur effects and gradient overlays.

### Apple Watch Integration
- Standalone watchOS app mirroring core tracking functionality
- **Watch Complications**:
  - **Circular Gauge**: Shows progress percentage with colored ring
  - **Rectangular Full**: Time remaining + active zone with progress bar
  - **Corner**: Hours elapsed with progress indicator
  - **Inline**: Compact time + zone display
- Real-time sync via Watch Connectivity framework

### HealthKit Integration
- Read weight trends for context
- Write fasting intervals as custom workout type
- Graceful permission handling
- Automatically saves completed fasts to Health app

### On-Device AI Analysis
- Statistical learning algorithm for pattern recognition
- Predicts optimal fasting windows based on completion history
- Analyzes success rates by day of week and start time
- **100% on-device** - no server calls, no data transmission

### Smart Notifications
- Fasting start/end reminders
- Zone transition alerts
- Streak milestone celebrations (3, 5, 7, 14+ days)
- Customizable notification categories

## Technical Stack

- **iOS 17+** / watchOS 10+
- **SwiftUI** + **SwiftData** for persistence
- **MVVM architecture** with @Observable
- **Swift Concurrency** (async/await, actors)
- **Combine** for reactive updates
- **WidgetKit** for complications
- **HealthKit** integration
- **UNUserNotificationCenter** for notifications

## Architecture

```
Glasstic/
├── Models/                    # Data models
│   ├── FastingSessionData     # SwiftData @Model
│   ├── FastingZone            # Zone logic + presets
│   └── AppTheme               # Theme system
├── ViewModels/
│   └── FastingStore           # @Observable main state
├── Views/                     # SwiftUI views
├── Services/                  # Business logic layer
│   ├── DataService            # SwiftData persistence
│   ├── HealthKitService       # HealthKit integration
│   ├── NotificationService    # Notifications
│   ├── AIAnalysisService      # On-device AI
│   └── WatchConnectivityService # Watch sync
└── Utilities/                 # Helpers and extensions

Watch/
├── Complications/             # WidgetKit providers
└── Services/                  # Watch-specific services
