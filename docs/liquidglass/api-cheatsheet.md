# LiquidGlass SwiftUI Cheat Sheet (iOS 26+)

> **Authoritative reference:** See `liquid-glass.md` in the project root for comprehensive documentation.

## Core API

```swift
// Basic glass effect (default: .regular variant, .capsule shape)
.glassEffect()
.glassEffect(.regular)
.glassEffect(.regular, in: .capsule)

// With custom shape
.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
.glassEffect(.regular, in: .circle)
.glassEffect(.regular, in: .rect(cornerRadius: 16))

// With tint (reserve for primary actions)
.glassEffect(.regular.tint(.blue))

// Interactive (adds touch feedback: scaling, bouncing, shimmer)
.glassEffect(.regular.interactive())

// Combined
.glassEffect(.regular.tint(.blue).interactive())
```

## Glass Variants

| Variant | Use Case |
|---------|----------|
| `.regular` | Default for most UI |
| `.clear` | Media-rich backgrounds |
| `.identity` | No effect (for conditional toggle) |

## Button Styles

```swift
Button("Secondary") { }
    .buttonStyle(.glass)

Button("Primary") { }
    .buttonStyle(.glassProminent)
```

## Grouping (Required for Multiple Glass Elements)

```swift
GlassEffectContainer {
    HStack {
        Button("A") { }.glassEffect(.regular.interactive())
        Button("B") { }.glassEffect(.regular.interactive())
    }
}
```

## Morphing Transitions

```swift
@Namespace private var namespace

GlassEffectContainer(spacing: 30) {
    Button("Toggle") { }
        .glassEffect()
        .glassEffectID("toggle", in: namespace)
}
```

## Compatibility Pattern

```swift
if #available(iOS 26.0, *) {
    content.glassEffect(.regular.interactive())
} else {
    content.background(.ultraThinMaterial).clipShape(Capsule())
}
```

## Best Practices

- Use glass for **navigation/controls only**, never content
- Always use `.interactive()` for touch targets
- Group adjacent glass in `GlassEffectContainer`
- Reserve tinting for primary actions
- Never stack glass on glass
