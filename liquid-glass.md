# Liquid Glass Reference for iOS 26+

A comprehensive reference for implementing Apple's Liquid Glass design system in SwiftUI. This document is designed for AI agents and developers working on iOS 26+ applications.

## Overview

Liquid Glass is a digital meta-material introduced in iOS 26 that dynamically bends and shapes light through **lensing**—concentrating light rather than scattering it like traditional blur effects. It creates translucent navigation surfaces that adapt to background content in real-time.

### Core Design Principle

**Liquid Glass belongs to the navigation layer only.**

```
┌─────────────────────────────────────┐
│      Glass Navigation Layer         │  ← Liquid Glass lives here
│  (toolbars, tabs, floating buttons) │
├─────────────────────────────────────┤
│                                     │
│         Content Layer               │  ← Never apply glass here
│    (lists, cards, main content)     │
│                                     │
└─────────────────────────────────────┘
```

## Quick Start

```swift
import SwiftUI

// Basic glass effect (uses .regular variant, .capsule shape)
Text("Glass Text")
    .padding()
    .glassEffect()

// With tint color
Button("Action") { }
    .glassEffect(.regular.tint(.purple))

// Interactive (adds scaling, bouncing, shimmer on touch)
Button("Tap Me") { }
    .glassEffect(.regular.interactive())

// Combined
Button("Primary") { }
    .glassEffect(.regular.tint(.blue).interactive())
```

---

## Glass Variants

Three primary variants control transparency and visual treatment:

| Variant | Use Case | Transparency |
|---------|----------|--------------|
| `.regular` | Default for most UI | Medium, full adaptivity |
| `.clear` | Media-rich backgrounds | High, requires bold foreground |
| `.identity` | No effect (conditional toggle) | None |

### Usage

```swift
// Regular (default)
.glassEffect()
.glassEffect(.regular)

// Clear - use only when:
// 1. Background is media-rich
// 2. Some dimming is acceptable
// 3. Content above is bold/high-contrast
.glassEffect(.clear)

// Identity - for conditional toggling
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
.glassEffect(reduceTransparency ? .identity : .regular)
```

**Important:** Never mix variants in the same interface.

---

## Shapes

Specify custom shapes for the glass effect:

```swift
// Default capsule
.glassEffect()
.glassEffect(.regular, in: .capsule)

// Circle
.glassEffect(.regular, in: .circle)

// Rounded rectangle
.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
.glassEffect(.regular, in: .rect(cornerRadius: 16))

// Container-concentric (aligns with parent container corners)
.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))

// Ellipse
.glassEffect(.regular, in: .ellipse)

// Continuous capsule
.glassEffect(.regular, in: .capsule(style: .continuous))
```

**Tip:** Use `.containerConcentric` for seamless corner alignment across different device sizes.

---

## Modifiers

### Tinting

Add color to glass effects. Use sparingly—only for primary actions:

```swift
// Basic tint
.glassEffect(.regular.tint(.blue))

// With opacity
.glassEffect(.regular.tint(.purple.opacity(0.8)))
```

**Guideline:** When everything is tinted, nothing stands out. Reserve tinting for primary actions only.

### Interactive

Adds touch feedback behaviors (iOS only):

- Scaling on press
- Bouncing on release
- Shimmering effect
- Illumination from touch point

```swift
.glassEffect(.regular.interactive())

// Combined with tint
.glassEffect(.regular.tint(.orange).interactive())
```

**Always use `.interactive()` for:**
- Buttons
- Touch targets
- Any interactive control

### Chaining

Modifiers can be chained in any order:

```swift
.glassEffect(.regular.tint(.blue).interactive())
.glassEffect(.regular.interactive().tint(.blue))  // Same result
```

---

## Implementation Notes

- Apply `glassEffect` after layout and styling modifiers so the glass samples the final shape.
- Use `GlassEffectContainer` to group multiple glass elements and avoid glass-on-glass artifacts.
- Reserve `.interactive()` for touchable elements only; leave static surfaces non-interactive.

### Compatibility Pattern (iOS < 26)

Use a conditional modifier to fall back to a material + gradient approximation on older OS versions.

```swift
extension View {
    @ViewBuilder
    func glassedEffect(in shape: some Shape, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            self.background {
                shape
                    .fill(.ultraThinMaterial)
                    .fill(
                        .linearGradient(
                            colors: [
                                .primary.opacity(0.08),
                                .primary.opacity(0.05),
                                .primary.opacity(0.01),
                                .clear,
                                .clear,
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .stroke(.primary.opacity(0.2), lineWidth: 0.7)
            }
        }
    }
}
```

---

## Button Styles

iOS 26 provides dedicated button styles:

```swift
// Glass button (secondary actions)
Button("Cancel") { }
    .buttonStyle(.glass)

// Glass prominent (primary actions)
Button("Submit") { }
    .buttonStyle(.glassProminent)

// With tint
Button("Primary Action") { }
    .buttonStyle(.glassProminent)
    .tint(.purple)
```

| Style | Use Case | Visual |
|-------|----------|--------|
| `.glass` | Secondary actions | Translucent |
| `.glassProminent` | Primary actions | More opaque |

---

## GlassEffectContainer

Groups multiple glass elements with shared sampling region. **Critical for:**

1. Preventing glass-on-glass rendering issues
2. Enabling morphing transitions
3. Consistent visual blending

### Basic Usage

```swift
GlassEffectContainer {
    HStack(spacing: 20) {
        Button("Edit") { }
            .glassEffect(.regular.interactive())
        Button("Share") { }
            .glassEffect(.regular.interactive())
    }
}
```

### Spacing Parameter

Controls morphing threshold—elements within this distance blend together:

```swift
GlassEffectContainer(spacing: 30) {
    HStack(spacing: 20) {
        Image(systemName: "pencil")
            .glassEffect(.regular.interactive())
        Image(systemName: "eraser")
            .glassEffect(.regular.interactive())
    }
}
```

- **Large spacing (30+):** Elements merge when close
- **Small spacing (10):** Elements stay separate unless overlapping
- **Default:** System determines appropriate spacing

---

## Morphing Transitions

Create fluid animations between glass elements.

### Requirements

1. Elements in same `GlassEffectContainer`
2. Unique `glassEffectID` with shared namespace
3. Animation wrapping state changes

### Implementation

```swift
struct MorphingExample: View {
    @State private var isExpanded = false
    @Namespace private var namespace

    var body: some View {
        GlassEffectContainer(spacing: 30) {
            HStack {
                Button(isExpanded ? "Collapse" : "Expand") {
                    withAnimation(.bouncy) {
                        isExpanded.toggle()
                    }
                }
                .glassEffect()
                .glassEffectID("toggle", in: namespace)

                if isExpanded {
                    Button("Action 1") { }
                        .glassEffect()
                        .glassEffectID("action1", in: namespace)

                    Button("Action 2") { }
                        .glassEffect()
                        .glassEffectID("action2", in: namespace)
                }
            }
        }
    }
}
```

### Animation Curves

Recommended curves for morphing:

```swift
withAnimation(.bouncy) { }           // Preferred for glass
withAnimation(.spring) { }           // Natural feel
withAnimation(.easeInOut) { }        // Subtle transitions
```

---

## Text & Icon Rendering

Text automatically receives **vibrant treatment**—color and saturation adjust based on background.

### Best Practices

```swift
// High contrast text for legibility
Text("Glass Label")
    .font(.title).bold()
    .foregroundStyle(.white)
    .glassEffect()

// Icons with interaction
Image(systemName: "star.fill")
    .font(.title2)
    .foregroundStyle(.white)
    .glassEffect(.regular.interactive())
```

---

## Accessibility

System automatically adapts glass appearance without additional code:

| Setting | Automatic Behavior |
|---------|-------------------|
| Reduce Transparency | Increases frosting |
| Increase Contrast | Adds stark borders |
| Reduce Motion | Tones down animations |

### Manual Override (Rare)

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

.glassEffect(reduceTransparency ? .identity : .regular)
```

**Guideline:** Let accessibility adapt automatically; override only when necessary.

---

## API Reference

### glassEffect

```swift
func glassEffect<S: Shape>(
    _ glass: Glass = .regular,
    in shape: S = .capsule,
    isEnabled: Bool = true
) -> some View
```

### glassEffectID

```swift
func glassEffectID<ID: Hashable>(
    _ id: ID,
    in namespace: Namespace.ID
) -> some View
```

### GlassEffectContainer

```swift
struct GlassEffectContainer<Content: View>: View {
    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content)
}
```

### Glass Struct

```swift
struct Glass {
    static var regular: Glass
    static var clear: Glass
    static var identity: Glass

    func tint(_ color: Color) -> Glass
    func interactive() -> Glass
}
```

---

## Best Practices

### Do

- Use glass for navigation/control layers only
- Group multiple glass elements in `GlassEffectContainer`
- Apply `.interactive()` to all touch targets
- Use `.containerConcentric` for corner alignment
- Let accessibility settings adapt automatically
- Use high-contrast foreground colors (`.white`)
- Reserve tinting for primary actions only

### Don't

- Apply glass to content layers (lists, cards, tables)
- Stack glass on glass (use container instead)
- Mix glass variants in the same interface
- Overuse tinting (defeats the purpose)
- Apply glass to full-screen backgrounds
- Use glass on scrollable content areas

---

## Common Patterns

### Floating Action Button

```swift
struct FloatingActionButton: View {
    var body: some View {
        Button {
            // Action
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundStyle(.white)
        }
        .glassEffect(.regular.tint(.blue).interactive())
    }
}
```

### Custom Toolbar

```swift
struct CustomToolbar: View {
    var body: some View {
        GlassEffectContainer(spacing: 20) {
            HStack(spacing: 16) {
                ForEach(ToolbarItem.allCases) { item in
                    Button {
                        // Action
                    } label: {
                        Image(systemName: item.icon)
                            .foregroundStyle(.white)
                    }
                    .glassEffect(.regular.interactive())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}
```

### Tab Bar with Morphing

```swift
struct MorphingTabBar: View {
    @State private var selectedTab = 0
    @Namespace private var tabNamespace

    let tabs = ["house", "magnifyingglass", "person"]

    var body: some View {
        GlassEffectContainer(spacing: 30) {
            HStack(spacing: 24) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, icon in
                    Button {
                        withAnimation(.bouncy) {
                            selectedTab = index
                        }
                    } label: {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(selectedTab == index ? .white : .white.opacity(0.6))
                    }
                    .glassEffect(
                        selectedTab == index
                            ? .regular.tint(.blue).interactive()
                            : .regular.interactive()
                    )
                    .glassEffectID("tab-\(index)", in: tabNamespace)
                }
            }
            .padding()
        }
    }
}
```

### Conditional Glass (Compatibility)

```swift
struct CompatibleGlassView: View {
    var body: some View {
        Button("Action") { }
            .modifier(GlassModifier())
    }
}

struct GlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive())
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }
}
```

---

## Platform Requirements

- iOS 26.0+
- iPadOS 26.0+
- macOS 26.0+ (Tahoe)
- watchOS 26.0+
- tvOS 26.0+
- visionOS 26.0+
- Xcode 26+

---

## Free Upgrades

Recompiling with Xcode 26 automatically applies Liquid Glass to system components without code changes:

- NavigationBar
- TabBar
- Toolbar
- Sheets
- Popovers
- Menus
- Alerts
- Context menus

---

## Sources

- [Apple Developer Documentation: Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/liquid-glass)
- [Apple Developer Documentation: Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [WWDC25 Session 219: Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)
- [WWDC25 Session 323: Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [LiquidGlassReference](https://github.com/conorluddy/LiquidGlassReference)
- [LiquidGlassCheatsheet](https://github.com/GonzaloFuentes28/LiquidGlassCheatsheet)
- [Livsy Code: Implementing the glassEffect in SwiftUI](https://livsycode.com/swiftui/implementing-the-glasseffect-in-swiftui/)
- [Dimillian Skills: SwiftUI Liquid Glass](https://github.com/Dimillian/Skills/tree/main/swiftui-liquid-glass)
