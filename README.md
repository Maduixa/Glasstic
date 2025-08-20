# 🌟 Glasstic

**A beautiful intermittent fasting tracker with glassmorphic design**

Glasstic is an iOS app that brings elegance to intermittent fasting tracking through stunning glassmorphic UI design, comprehensive fasting zone monitoring, and AI-powered motivational guidance.

## ✨ Features

### 🎯 **Smart Fasting Tracking**
- **6 Comprehensive Fasting Zones**: From Anabolic (🍽️) to Deep Autophagy (✨)
- **Real-time Progress Monitoring**: Beautiful animated gauge showing your current zone
- **Flexible Fasting Plans**: 16:8, 18:6, 20:4, OMAD, or custom durations
- **Live Activities**: Track your fast directly from your lock screen (iOS 16+)

### 🤖 **AI-Powered Experience**
- **Dynamic Messages**: Contextual motivational and educational content
- **Zone-Specific Guidance**: Learn what's happening in your body during each phase
- **Rotating Content**: Fresh messages every 30 seconds to keep you engaged
- **Smart Notifications**: AI-generated completion alerts

### 🎨 **Glassmorphic Design**
- **Liquid Glass Aesthetic**: Consistent `.ultraThinMaterial` backgrounds
- **Smooth Animations**: Fluid transitions and haptic feedback
- **Gradient Overlays**: Zone-specific color gradients and glow effects
- **Interactive Elements**: Scale animations and visual feedback

### 🏆 **Gamification & Tracking**
- **Achievement System**: Unlock badges for milestones and streaks
- **Calendar Integration**: Visual history of your fasting journey
- **Streak Tracking**: Monitor consistency and build healthy habits
- **Progress Statistics**: Detailed insights into your fasting patterns

### ⌚ **Cross-Platform Integration**
- **Apple Watch Support**: Real-time synchronization with Watch app
- **HealthKit Integration**: Seamlessly sync with Apple Health
- **Data Persistence**: Secure local storage with App Groups support
- **Edit Functionality**: Adjust start times and past fasting sessions

## 🛠️ Technical Requirements

- **iOS 16.0+** (for Live Activities support)
- **Xcode 14+**
- **SwiftUI** framework
- **Apple Developer Account** (for device testing)

### Dependencies & Frameworks
- SwiftUI (UI framework)
- ActivityKit (Live Activities)
- HealthKit (Health data integration)
- WatchConnectivity (Apple Watch sync)
- UserNotifications (Local notifications)
- NaturalLanguage (AI message processing)

## 🚀 Installation & Setup

### Prerequisites
1. **Xcode** installed on your Mac
2. **iOS Simulator** or physical iOS device
3. **Apple Developer Account** (for device installation)

### Building the Project

```bash
# Clone the repository
git clone https://github.com/Maduixa/Glasstic.git
cd Glasstic

# Open in Xcode
open Glasstic.xcodeproj

# Build the project
xcodebuild -project Glasstic.xcodeproj -scheme Glasstic -configuration Debug build

# Run on simulator
xcrun simctl boot "iPhone 15 Pro"
xcodebuild -project Glasstic.xcodeproj -scheme Glasstic -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

### First Launch Setup
1. Grant **HealthKit permissions** when prompted
2. Complete the **onboarding flow** to learn about features
3. Choose your preferred **fasting plan**
4. Start your first fasting session!

## 📖 Usage Guide

### Starting a Fast
1. Open the app and tap **"Start Fast"**
2. Select your fasting plan (16:8, 18:6, 20:4, OMAD, or custom)
3. Watch the beautiful gauge fill as you progress through zones
4. Receive AI-generated motivation and education throughout your journey

### Fasting Zones Explained
- **🍽️ Anabolic (0-4h)**: Digestion and nutrient absorption
- **⚡ Catabolic (4-12h)**: Glycogen breakdown begins
- **🔥 Fat Burning (12-16h)**: Primary fat oxidation phase
- **🧠 Ketosis (16-24h)**: Ketone production for enhanced cognition
- **♻️ Autophagy (24-48h)**: Cellular cleaning and repair
- **✨ Deep Autophagy (48h+)**: Maximum cellular renewal

### Tracking & History
- View your fasting history in the **Calendar** tab
- Edit past fasting sessions by tapping on calendar entries
- Monitor your streak and achievement progress in **Profile**
- Adjust ongoing fast start time with the edit button

## 🏗️ Architecture Overview

### Core Components
- **FastingManager**: Central state management with ObservableObject pattern
- **AIMessageManager**: Dynamic content generation using NaturalLanguage
- **GamificationManager**: Badge system and progress tracking
- **HealthKitManager**: Apple Health integration
- **WatchConnectivityManager**: Apple Watch synchronization

### Key Design Patterns
- **State Synchronization**: Multi-layer approach with UserDefaults persistence
- **Timer Management**: Robust lifecycle handling with date-based calculations
- **Glassmorphic UI**: Consistent material design throughout the app
- **Cross-Platform Data Sharing**: App Groups for Watch extension support

## 🤝 Contributing

We welcome contributions to make Glasstic even better! Here's how you can help:

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes following the existing code style
4. Test thoroughly on both simulator and device
5. Submit a pull request with a clear description

### Code Style Guidelines
- Follow Swift conventions and SwiftUI best practices
- Maintain glassmorphic design consistency
- Ensure accessibility support
- Add appropriate comments for complex logic
- Test with different fasting durations and edge cases

### Areas for Contribution
- Additional fasting plans and customization options
- Enhanced Apple Watch complications
- More gamification features and achievements
- Improved accessibility features
- Additional language localizations

## 📝 License

This project is available under the MIT License. See the LICENSE file for more details.

## 🔗 Links

- **Issues**: Report bugs or request features
- **Discussions**: Join the community conversation
- **Wiki**: Detailed documentation and guides

---

**Made with ❤️ and SwiftUI**

*Transform your fasting journey with the beauty of glassmorphic design*