# Documentation index

This repo is organized so that Claude Code can load only what it needs.

## Recommended order
1. `docs/workflows/agentic-workflow.md`
2. `docs/liquidglass/README.md`
3. `docs/watch/README.md`
4. `docs/healthkit/README.md`
5. `docs/ondevice-ml/README.md`
6. `docs/testing/README.md`
7. `docs/compliance/README.md`
8. `docs/risk-matrix.md`
9. `docs/diagrams/architecture.md`

## Quick links by domain
- LiquidGlass
  - `liquid-glass.md` (authoritative reference - project root)
  - `docs/liquidglass/api-cheatsheet.md` (quick reference)
  - `docs/liquidglass/performance.md`
- Watch app
  - `docs/watch/watchconnectivity.md`
  - `docs/watch/dual-target-xcode.md`
- HealthKit
  - `docs/healthkit/authorization.md`
  - `docs/healthkit/queries.md`
  - `docs/healthkit/workouts.md`
- On-device ML
  - `docs/ondevice-ml/coreml.md`
  - `docs/ondevice-ml/deployment.md`
  - `docs/ondevice-ml/privacy.md`
- Workflows
  - `docs/workflows/prompt-templates.md`
  - `docs/workflows/conversation-playbooks.md`
- Testing
  - `docs/testing/liquidglass-validation.md`
  - `docs/testing/ml-validation.md`

## How to keep facts correct in betas
Treat any forward-looking API as **untrusted until verified**:
- Search in Xcode: “Jump to Definition” / Quick Help.
- Compile a minimal snippet in a scratch target.
- Grep SDK swiftinterface (see `scripts/sdk_verify.sh`).
