---
paths:
  - "**/*.swift"
---

# SwiftUI + LiquidGlass rules

## Usage
- Use LiquidGlass for **chrome** and floating controls, not for primary content surfaces.
- Prefer `GlassEffectContainer` when multiple glass elements share the same backdrop.
- Avoid stacking glass-on-glass (performance + contrast risk).

## Accessibility
- Must be usable with:
  - Reduce Transparency ON
  - Increase Contrast ON
  - Reduce Motion ON
  - Dynamic Type large sizes
- Provide fallback styling when glass is disabled or unavailable.

## Performance
- Avoid continuous animations on glass views.
- Profile GPU / power for screens with multiple glass elements.
- On watchOS, be conservative: small screens + outdoor use demand contrast.
