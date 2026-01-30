# Testing strategy overview

## Layers
- Unit tests: data transformation, model preprocessing, message encoding
- Integration tests: HealthKit queries (with abstraction/mocks), WCSession flows
- UI tests: main dashboard, permission gating, watch pairing
- Snapshot tests: LiquidGlass across light/dark + accessibility settings
- Accessibility audit: VoiceOver labels, contrast, Dynamic Type

## Principles
- Treat HealthKit and WCSession as I/O boundaries; mock where practical.
- Store minimal deterministic test fixtures.
