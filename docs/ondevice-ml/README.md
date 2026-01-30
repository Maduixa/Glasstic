# On-device AI (Core ML + Vision/NLP/SoundAnalysis)

## Goal
Deliver valuable insights while keeping sensitive data on-device.

## Core patterns
- Define a model I/O contract (inputs, shapes, preprocessing, outputs).
- Cache model instances; avoid repeated loads.
- Run inference off main; return results to main safely.
- Validate outputs with confidence thresholds; avoid overconfident UX.

## Frameworks
- Core ML: custom models and inference runtime
- Vision: pose/feature extraction that can feed a Core ML model
- NaturalLanguage: on-device text classification and tagging
- SoundAnalysis: on-device audio event classification (requires mic permission)

## Beta reality check
Apple may add new APIs or change signatures in betas.
Always verify against your local SDK headers and compile minimal examples.
