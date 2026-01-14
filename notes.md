
  ---
  Project Prompt: Glasstic - iOS Intermittent Fasting Tracker

  Build a production-ready iOS intermittent fasting app called "Glasstic" (or "Liquid Glass") with Apple Watch support and glassmorphic design.

  Core Requirements

  1. Fasting Tracking
  - Start/stop fasting timer with real-time elapsed time display
  - Support multiple fasting protocols: 16:8, 18:6, 20:4, OMAD (23h), and custom windows
  - Editable session start/end times using date pickers
  - Optional notes for each session
  - Persistent history of all fasting sessions

  2. Fasting Zones System
  Implement four metabolic zones with customizable hour thresholds:
  - Post-Meal Zone (default 0-4h): Digestion phase
  - Early Fasting Zone (default 4-12h): Glycogen depletion
  - Fat-Burning Zone (default 12-18h): Fat oxidation
  - Deep Ketosis Zone (default 18h+): Enhanced autophagy

  Each zone should have:
  - Display name
  - 2-3 contextual nudge messages (e.g., "Let digestion settle; hydrate lightly")
  - Visual progress indicator within the zone

  3. UI/UX Design
  - Glassmorphic aesthetic: Ultra-thin material blur, 70% opacity, 20pt corner radius
  - Theme system: Multiple color themes with gradient backgrounds
    - Each theme: name, accent color, gradient colors, material bias (thin/regular/thick)
    - Theme picker with visual swatches
  - Home screen components:
    - Large timer display (MM:SS or HH:MM format, monospaced digits)
    - Current zone badge with pill-shaped background
    - Contextual nudge message card
    - Circular progress gauge showing zone progress
    - Start/End fast button with accent color gradient
    - Streak counter with fire emoji
    - Calendar panel showing monthly history
    - AI insights card (optional analysis)
  - Dark mode primary with gradient overlays

  4. Data Persistence
  - Use SwiftData (@Model) for all session storage
  - Schema:
  @Model class FastingSessionData {
      id: UUID
      startDate: Date
      endDate: Date?
      note: String
      editedDuration: TimeInterval?
  }
  - CRUD operations through DataService
  - Support editing completed sessions

  5. Apple Watch Integration
  - Standalone watchOS app (watchOS 10+)
  - Mirror core tracking functionality
  - Watch Connectivity for sync between phone and watch
  - Complications:
    - Circular gauge: Progress percentage
    - Rectangular: Time remaining + zone name
    - Corner: Hours elapsed
  - Minimal interface optimized for glanceable info

  6. HealthKit Integration
  - Request authorization gracefully (optional)
  - Read weight trends for correlation
  - Write fasting intervals as custom workout type
  - Handle permission denial gracefully

  7. Notifications
  - Zone transition alerts
  - Customizable start/end reminders
  - Streak milestone celebrations
  - Use UNUserNotificationCenter with categories

  8. AI Analysis (Optional)
  - On-device CoreML tabular regression model
  - Predict optimal fasting windows based on completion history
  - Zero server calls for complete privacy
  - Display insights in dedicated card

  9. Calendar View
  - Monthly calendar grid
  - Visual indicators for days with fasting sessions
  - Tap to edit/view session details
  - Add manual sessions for past dates

  10. Settings
  - Customize zone threshold hours with sliders
  - Preset buttons for common protocols
  - Validation: ensure thresholds don't overlap
  - Theme selection

  Technical Stack

  - Minimum: iOS 17+ / watchOS 10+
  - SwiftUI with @Observable pattern (not ObservableObject)
  - SwiftData for persistence
  - MVVM architecture
  - Swift Concurrency (async/await)
  - Frameworks: HealthKit, UserNotifications, WatchConnectivity, CoreML (optional)

  Architecture Pattern

  Models/
    - FastingSessionData (SwiftData @Model)
    - FastingZone (enum with thresholds)
    - AppTheme (theme configuration)

  ViewModels/
    - FastingStore (@Observable) - main business logic

  Views/
    - HomeView (main screen)
    - FastingGaugeView (circular progress)
    - SessionEditorView (edit sessions)
    - CalendarPanelView (monthly calendar)
    - SettingsView (configure thresholds/themes)
    - ThemePickerView (theme selection)
    - AIInsightsView (optional AI predictions)

  Services/
    - DataService (SwiftData CRUD)
    - HealthKitService (HealthKit wrapper)
    - NotificationService (notifications wrapper)
    - iOSWatchConnectivityService (phone side sync)
    - WatchConnectivityService (watch side sync)

  Utilities/
    - TimeFormatter (duration formatting)
    - View+Glass (glassmorphic modifiers)

  Key Features Summary

  ✅ Real-time timer with zone indicators
  ✅ Glassmorphic design with multiple themes
  ✅ Full Apple Watch app with complications
  ✅ HealthKit integration for weight trends
  ✅ Editable session history with calendar view
  ✅ Customizable zone thresholds
  ✅ Streak tracking
  ✅ Local notifications
  ✅ On-device AI predictions (optional)
  ✅ SwiftData persistence
  ✅ 80%+ test coverage for ViewModels/Services

  Deliverables

  - Fully functional iOS app (iPhone + iPad)
  - Apple Watch companion app
  - Unit tests for core logic
  - README with setup instructions
  - SwiftLint compliant code