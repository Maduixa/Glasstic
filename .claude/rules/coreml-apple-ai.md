---
paths:
  - "**/*.swift"
---

# On-device ML / Apple AI rules

## Core ML integration
- Load models once; cache `MLModel` instances (avoid repeated loads).
- Run inference off the main thread unless it’s trivially fast.
- Validate input shape/types; avoid guessing model I/O.

## Privacy architecture
- Keep inference on-device by default.
- If storing ML outputs derived from health data, document the derivation and user value.
- Avoid “medical advice” phrasing; present insights as informational/wellness unless regulated.

## Deployment
- For large models, prefer on-demand resources / post-install download with user consent.
- Provide graceful failure if model unavailable.
