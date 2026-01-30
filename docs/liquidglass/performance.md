# LiquidGlass performance guidance

## Known cost drivers
- Multiple independent glass layers sampling different backdrops
- Continuous animations on glass surfaces
- Large fullscreen translucent regions
- Stacking glass-on-glass (nested blur sampling)

## Guardrails
- Prefer **one** glass region per screen section (group via container).
- Avoid indefinite animations (pulsing, rotating, shimmering).
- If you need “attention”, animate briefly then settle.
- Profile on:
  - iPhone baseline: iPhone 14+
  - Worst-case: an older supported device (or simulate thermal constraints)

## Instrumentation
- Use Instruments to check:
  - Core Animation FPS
  - GPU utilization
  - Energy impact
- Consider a feature flag to disable glass for A/B profiling.

## Degradation strategy
- Provide a “Reduce effects” toggle (developer/debug menu) to quickly isolate perf.
- Honor Reduce Transparency and Reduce Motion; avoid fighting the system.
