---
paths:
  - "**/*.swift"
  - "**/*.md"
---

# Testing rules

- Add unit tests for:
  - HealthKit query predicates and data transformation logic
  - Core ML preprocessing/postprocessing
  - WatchConnectivity message encoding/decoding
- Add UI tests for critical flows (permission gating, main dashboard, watch pairing).
- Add accessibility audits (VoiceOver labels, contrast, dynamic type).
- For LiquidGlass, add snapshot tests across Light/Dark and Reduce Transparency.
