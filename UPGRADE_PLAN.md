# Liquid Glass Upgrade Plan ✅ COMPLETED

This document outlines the changes that were made to upgrade Glasstic from custom frosted glass/glassmorphism effects to Apple's native iOS 26 Liquid Glass design language.

**Status: Implemented and running in simulator**

## Current State Analysis

The app currently uses a mix of:
- **Material-based frosted glass** (`View+Glass.swift`) — old iOS blur materials
- **Custom glassmorphism effects** with gradients, blend modes, and opacity overlays
- **Simulated refraction** via chromatic aberration, caustics, and specular highlights
- **Magnifying/focus effects** in the bottom pill menu
- **Custom ripple and fresnel rim effects**

These need to be replaced with native `.glassEffect()` APIs.

---

## Files Requiring Changes

### 1. `Glasstic/Utilities/View+Glass.swift`
**Problem:** Uses `Material` (`.thinMaterial`, `.ultraThinMaterial`) for frosted glass effect.

**Changes:**
- Replace `GlassCardModifier` to use native `.glassEffect()` instead of `Material`
- Remove the `material` parameter entirely
- Use `.glassEffect(.regular, in: .rect(cornerRadius:))` for cards

```swift
// BEFORE
.background(material, in: RoundedRectangle(cornerRadius: cornerRadius))

// AFTER  
.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
```

---

### 2. `GlassticPackage/Sources/GlassticFeature/Utilities/View+Glassmorphic.swift`
**Problem:** Custom `LiquidGlassStyle` with overlay gradients simulating refraction.

**Changes:**
- Remove `LiquidGlassStyle` struct (use native `GlassEffectStyle`)
- Simplify `liquidGlass()` modifier to only call native `.glassEffect()`
- Remove all overlay gradients with `.blendMode(.plusLighter)`
- Remove the manual stroke/fill overlays
- Keep `GlassEffectContainer` but make it use native `GlassEffectContainer` from SwiftUI

```swift
// BEFORE - custom implementation
.glassEffect(.regular, in: shape)
.overlay(shape.stroke(style.tintColor.opacity(0.25), lineWidth: 1))
.background(shape.fill(style.tintColor.opacity(0.06)))
.overlay(LinearGradient(...).blendMode(.plusLighter))

// AFTER - native only
.glassEffect(.regular.tint(tintColor), in: shape)
```

---

### 3. `GlassticPackage/Sources/GlassticFeature/ContentView.swift`
**Problem:** Most complex file with extensive custom effects.

**Remove these custom views entirely:**
- [ ] `ChromaticAberrationEdge` — simulates refraction
- [ ] `AmbientChromaticEdge` — simulates refraction  
- [ ] `FresnelRimHighlight` — simulates glass rim lighting
- [ ] `SpecularHighlightLayer` — custom specular highlights
- [ ] `SubtleCausticsLayer` — custom caustics
- [ ] `LiquidRippleEffect` — custom ripple on tap

**Simplify `BottomPillMenu`:**
- Remove magnifying/focus scaling effect on drag
- Remove custom refraction layers
- Use native `GlassEffectContainer` + `.glassEffect(.regular.interactive())` for tabs
- Use `glassEffectID` with `@Namespace` for tab selection morphing

**Simplify `SettingsPanel`:**
- Remove custom `liquidGlass()` with overlays
- Use native `.glassEffect(.regular, in: .rect(cornerRadius: 22))`

**Simplify `StatusPill`:**
- Replace custom `liquidGlass()` with native `.glassEffect(.regular.tint(color), in: .capsule)`

---

### 4. `GlassticPackage/Sources/GlassticFeature/Views/GlassmorphicGauge.swift`
**Problem:** Heavy use of gradients and blend modes to simulate glass ring.

**Changes:**
- Remove `glassHighlightGradient` overlay with `.blendMode(.screen)`
- Remove the black opacity shadow overlay on the ring
- Simplify track to a single styled stroke
- Keep the progress gradient but remove glass simulation overlays
- Simplify inner circle — remove multiple overlay layers
- Use native glass effect for the inner display area if desired

```swift
// BEFORE - multiple glass simulation layers
Circle().stroke(Color.white.opacity(0.3)...).blendMode(.screen)
Circle().trim(...).stroke(glassHighlightGradient...).blendMode(.screen)

// AFTER - clean, minimal approach
Circle().stroke(trackColor, style: StrokeStyle(...))
// Let the background show through naturally
```

---

### 5. `Glasstic/Views/HomeView.swift`
**Problem:** Uses `.glassCard(material:)` which applies frosted Material.

**Changes:**
- Replace all `.glassCard(material:)` calls with native glass:
  ```swift
  // BEFORE
  .glassCard(material: store.selectedTheme.materialBias.material)
  
  // AFTER
  .padding()
  .glassEffect(.regular, in: .rect(cornerRadius: 26))
  ```
- Remove `FluidThemeBackground` radial gradients with `.blendMode(.screen)` if they simulate glass
- Update button to use `.buttonStyle(.glassProminent)` instead of custom gradient background

---

### 6. `Glasstic/Views/FastingGaugeView.swift`
**Problem:** Uses blur and opacity for pulsing glass effect.

**Changes:**
- Remove the blur overlay for the active segment pulse:
  ```swift
  // REMOVE this
  .blur(radius: 22)
  .opacity(pulse ? 0.6 : 0.2)
  ```
- Keep progress visualization but without glass simulation
- Zone legend items: replace `Color.white.opacity()` backgrounds with clean styling or subtle glass

---

### 7. `Glasstic/Views/SettingsView.swift`
**Problem:** Uses `.presentationBackground(.thinMaterial)` for sheet.

**Changes:**
- Consider using default presentation or `.presentationBackground(.clear)` with glass content
- Ensure form sections use native glass if glass styling is desired

---

### 8. `Glasstic/Models/AppTheme.swift`
**Problem:** Has `materialBias` property that returns different `Material` types.

**Changes:**
- Remove `materialBias` property entirely (no longer needed)
- Or repurpose to return `GlassEffectStyle` variants (`.regular`, `.prominent`)

---

## New Patterns to Adopt

### Native Glass Cards
```swift
VStack {
    // content
}
.padding()
.glassEffect(.regular, in: .rect(cornerRadius: 26))
```

### Interactive Glass Buttons
```swift
Button("Action") { }
    .buttonStyle(.glassProminent)

// Or custom:
Button(action: {}) {
    Label("Start", systemImage: "play.fill")
        .padding()
}
.glassEffect(.regular.interactive(), in: .capsule)
```

### Grouped Glass Elements
```swift
GlassEffectContainer(spacing: 16) {
    HStack(spacing: 16) {
        TabButton(...)
        TabButton(...)
    }
}
```

### Morphing Transitions
```swift
@Namespace private var tabAnimation

// Selected tab
.glassEffect(.prominent.interactive(), in: .capsule)
.glassEffectID("selectedTab", in: tabAnimation)

// With animation
.animation(.smooth, value: selectedTab)
```

---

## Implementation Order

### Phase 1: Foundation (Utilities)
1. Update `View+Glass.swift` — replace Material with native glassEffect
2. Simplify `View+Glassmorphic.swift` — remove custom overlays
3. Update `GlassButtonStyle.swift` if needed

### Phase 2: Main UI (Package)
4. Clean up `ContentView.swift`:
   - Remove all refraction/caustic views
   - Simplify BottomPillMenu
   - Update SettingsPanel and StatusPill
5. Simplify `GlassmorphicGauge.swift` — remove glass simulation overlays

### Phase 3: App Shell
6. Update `HomeView.swift` — replace glassCard calls
7. Update `FastingGaugeView.swift` — remove blur effects
8. Update `SettingsView.swift` — clean up presentation
9. Update `AppTheme.swift` — remove materialBias

### Phase 4: Polish
10. Review all views for consistency
11. Ensure proper `GlassEffectContainer` grouping
12. Add morphing transitions where appropriate
13. Test on device for proper glass rendering

---

## Files to Delete (or gut)

These custom effect views in `ContentView.swift` should be completely removed:
- `ChromaticAberrationEdge`
- `AmbientChromaticEdge`  
- `FresnelRimHighlight`
- `SpecularHighlightLayer`
- `SubtleCausticsLayer`
- `LiquidRippleEffect`

---

## Testing Checklist

- [ ] All glass effects render correctly on iOS 26 simulator
- [ ] No frosted/blur materials remain
- [ ] No custom refraction/chromatic aberration effects
- [ ] No magnifying/scaling effects on menus
- [ ] Buttons use native glass styles
- [ ] Glass containers properly group elements
- [ ] Morphing transitions work smoothly
- [ ] App builds without warnings
- [ ] Performance is acceptable (no heavy custom rendering)

---

## Reference

See `.amp/skills/swiftui-expert-skill/references/liquid-glass.md` for native API documentation.

Key APIs:
- `.glassEffect(_ style: GlassEffectStyle, in shape: Shape)`
- `GlassEffectContainer(spacing:) { }`
- `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)`
- `.glassEffectID(_:in:)` with `@Namespace`
- `GlassEffectStyle.regular` / `.prominent` / `.tint(_:)` / `.interactive()`
