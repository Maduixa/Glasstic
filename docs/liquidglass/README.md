# LiquidGlass (iOS 26+ / watchOS 26+) — engineering guide

## Intent
LiquidGlass is a translucent, depthful material intended primarily for **chrome** (toolbars, tab bars, floating controls) and secondary surfaces.
Use it to create hierarchy: controls float over content.

## SwiftUI API surface (verify in your SDK)
Common patterns you will likely use:
- `.glassEffect(...)` on a shape-backed background
- `GlassEffectContainer { ... }` to group multiple glass elements
- `.buttonStyle(.glass)` for system-consistent controls (watchOS may prefer this)

> Reality check: these APIs may move during beta. Validate names/signatures in your local SwiftUI module.

## Design tokens
Apple typically does not expose raw blur radii as stable tokens. Treat “blur/material” as system-managed.
What you *should* tokenize:
- Corner radius (per component category)
- Internal padding
- Border stroke width/opacity
- Shadow radius/offset (subtle)
- Animation cadence (use standard SwiftUI animation curves; avoid continuous loops)

## Accessibility
Must pass:
- Reduce Transparency
- Increase Contrast
- Reduce Motion
- Dynamic Type

Fallback strategy:
- If Reduce Transparency: use more opaque backgrounds (system will often adjust materials automatically; ensure contrast remains)
- If glass unavailable: fall back to `.ultraThinMaterial` (or flat color) while keeping layout identical.

## watchOS parity
On watchOS:
- Use glass sparingly. Outdoor use + small screens demand contrast.
- Prefer large, simple shapes; avoid text over complex backgrounds.
- Let system widget/complication containers handle background when possible.

## Implementation guidance
- Prefer glass for navigation chrome and small floating components.
- Avoid glass as a full-screen background (performance + legibility risk).
- Group adjacent glass with `GlassEffectContainer`.
- Avoid stacking multiple translucent layers.
