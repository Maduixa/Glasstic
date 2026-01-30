# Agentic workflow (prompt → code → build → test → ship)

## Operating model
Treat the AI as a set of specialists + reusable skills:
- Architect: file map, boundaries, buildability
- UI: LiquidGlass components + accessibility
- HealthKit: auth + queries + review safety
- watchOS: connectivity + glanceable UI
- ML: Core ML pipeline + validation
- Reviewer: compliance + App Store risk

## Default iteration loop
1) Prompt: define intent + acceptance criteria
2) Plan: list files + target membership
3) Implement: minimal slice
4) Verify: build + run
5) Harden: tests + accessibility + perf
6) Document: update docs + checklists

## “Reality Check” rule
For anything beta‑specific:
- confirm symbol existence in local SDK (grep / build)
- prefer small proof-of-life before building full feature

## Deliverable format expectations from the AI
- Provide code as complete files (with filenames) or patch-like blocks.
- Include a short test plan.
- Include a failure-mode list.
