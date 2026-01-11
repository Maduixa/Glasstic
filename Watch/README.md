# Glasstic Apple Watch App

A standalone Apple Watch app for tracking fasting sessions with real-time sync to the iPhone app.

## Features

### Main Watch App
- **Timer Display**: Shows elapsed time in hours and minutes
- **Zone Indicator**: Displays current fasting zone (Post-Meal, Early Fasting, Fat Burning, Deep Fast)
- **Progress Ring**: Visual progress through current zone with percentage
- **Streak Counter**: Shows current daily streak with flame icon
- **Start/Stop Controls**: Start and end fasting sessions directly from watch
- **Haptic Feedback**: Vibration feedback on state changes and zone transitions

### Complications
The app provides four complication families:

1. **Circular Gauge** - Progress percentage with elapsed time
2. **Rectangular Full** - Current zone, elapsed time, and progress bar
3. **Corner** - Compact elapsed time with progress indicator
4. **Inline** - Zone name and elapsed time in text format

### Watch Connectivity
- **Bidirectional Sync**: Sessions started on iPhone or Watch sync instantly
- **Real-time Updates**: Active session data syncs continuously
- **Offline Support**: Watch stores session data locally when iPhone is unreachable
- **Threshold Sync**: Custom fasting zone thresholds sync from iPhone

## Architecture

### Directory Structure
```
Watch/
├── App/
│   ├── GlassticWatchApp.swift       # App entry point
│   └── Info.plist                   # Watch app configuration
├── Views/
│   └── ContentView.swift            # Main UI with Active/Idle states
├── Models/
│   ├── WatchFastingStore.swift      # Watch-side state management
│   └── FastingZone+Watch.swift      # Watch-specific zone extensions
├── Services/
│   └── WatchConnectivityService.swift # WCSession management
└── Complications/
    └── GlassticComplicationProvider.swift # Widget/Complication views
```

### Services

#### WatchConnectivityService
Manages communication between iPhone and Watch using `WCSession`:
- `startFast()` - Sends start fast command to iPhone
- `endFast()` - Sends end fast command to iPhone
- `requestSync()` - Requests current state from iPhone
- Handles incoming messages from iPhone
- Automatically syncs on activation and reachability changes

#### WatchFastingStore
Local state management for watch app:
- Maintains active session state
- Calculates elapsed time and zone progress
- Timer-based updates every second
- Persists to UserDefaults for app restarts
- Provides computed properties for UI binding

### Models

#### WatchFastingSession
Lightweight session model for watch:
```swift
struct WatchFastingSession {
    let id: UUID
    let startDate: Date
    var note: String
}
```

#### Shared Models
The following models are shared between iOS and watchOS:
- `FastingZone` - Enum defining the four fasting zones
- `FastingThresholds` - Configurable hour thresholds for each zone

## Xcode Project Setup

### Adding Watch Target to Xcode

1. **Add watchOS Target**
   - File → New → Target
   - Select "Watch App" (watchOS)
   - Product Name: "Glasstic Watch App"
   - Bundle Identifier: `com.yourcompany.Glasstic.watchkitapp`
   - Organization Identifier: Match iOS app
   - Interface: SwiftUI
   - Language: Swift

2. **Add Widget Extension Target** (for complications)
   - File → New → Target
   - Select "Widget Extension" (watchOS)
   - Product Name: "Glasstic Complications"
   - Bundle Identifier: `com.yourcompany.Glasstic.watchkitapp.complications`
   - Include Configuration Intent: No

3. **Add Files to Targets**
   - Select all files in `Watch/` directory
   - In File Inspector, check the watchOS target
   - For shared models (FastingZone, FastingThresholds), check both iOS and watchOS targets

4. **Configure Shared Models**
   - In Xcode, select `FastingZone.swift` and `FastingThresholds.swift`
   - File Inspector → Target Membership
   - Check both "Glasstic" (iOS) and "Glasstic Watch App" (watchOS)

5. **Update iOS App Capabilities**
   - Select iOS target → Signing & Capabilities
   - Add "Background Modes" capability
   - Enable "Remote notifications" (if not already enabled)

6. **Configure Watch Connectivity**
   - Ensure iOS app has `WCSession` configured (already done via `iOSWatchConnectivityService`)
   - No additional Info.plist entries needed for modern WatchConnectivity

### Build Settings

**Watch App Target:**
- Deployment Target: watchOS 10.0+
- Swift Language Version: Swift 5
- Enable SwiftUI: Yes
- Supported Device Family: Apple Watch

**Complications Target:**
- Same as Watch App
- Link with Watch App binary

## iOS Integration

The iOS app integrates Watch Connectivity via `iOSWatchConnectivityService.swift`:

### Key Integration Points

1. **FastingStore Configuration**
   ```swift
   // In FastingStore init()
   watchConnectivity.configure(with: self)
   ```

2. **Session Start Notification**
   ```swift
   // When fast starts on iOS
   watchConnectivity.notifySessionStarted(startDate: now)
   ```

3. **Session End Notification**
   ```swift
   // When fast ends on iOS
   watchConnectivity.notifySessionEnded()
   ```

4. **Threshold Updates**
   ```swift
   // When user changes zone thresholds
   watchConnectivity.syncToWatch()
   ```

### Message Protocol

**iPhone → Watch:**
- `sessionStarted` - New fast started with `startDate`
- `sessionEnded` - Active fast ended
- `syncUpdate` - Full state sync (active session, thresholds, streak)

**Watch → iPhone:**
- `startFast` - User started fast on watch
- `endFast` - User ended fast on watch
- `requestSync` - Watch requesting current state

## UI Design

### Glassmorphic Style
The watch app matches the iOS glassmorphic aesthetic:
- Gradient colors based on fasting zones
- Semi-transparent overlays
- Smooth animations (0.5s ease-in-out)
- Zone-specific color schemes

### Color Palette
- **Post-Meal**: Light blue (0.8, 0.9, 1.0)
- **Early Fasting**: Medium blue (0.6, 0.8, 1.0)
- **Fat Burning**: Deep blue (0.4, 0.6, 1.0)
- **Deep Fast**: Dark blue (0.3, 0.5, 0.9)

### Haptic Feedback
- `WKHapticType.start` - When fast starts
- `WKHapticType.success` - When fast ends
- `WKHapticType.notification` - On zone transitions

## Testing

### Simulator Testing
1. Run iPhone app in iOS Simulator
2. Run Watch app in watchOS Simulator
3. Both simulators must be paired (Xcode does this automatically)
4. Test starting fast on each device - should sync to other

### Device Testing
1. Pair physical Apple Watch with iPhone
2. Install both apps via Xcode
3. Test sync with iPhone in pocket (not on charger)
4. Test complications by adding to watch face

### Complication Testing
1. Long-press watch face
2. Tap "Edit"
3. Select complication slot
4. Scroll to "Glasstic"
5. Choose complication style
6. Verify updates every minute during active fast

## Known Limitations

1. **Sync Delay**: When iPhone is unreachable, changes sync when devices reconnect
2. **Complication Updates**: Limited to ~50 updates per day by watchOS
3. **Background Refresh**: watchOS may pause app when not in foreground
4. **Battery Impact**: Active timer uses more battery; complications are more efficient

## Future Enhancements

- [ ] Watch-native history view
- [ ] Customizable haptic patterns
- [ ] Apple Health integration from watch
- [ ] Siri shortcuts for watch
- [ ] Watch face recommendations
- [ ] Multiple timer complications
- [ ] Graphical complications (watchOS 10+)

## Dependencies

- watchOS 10.0+ (for modern SwiftUI features)
- WatchConnectivity framework
- WidgetKit (for complications)
- ClockKit (for complication timeline)

## License

Part of the Glasstic project. See main project LICENSE file.
