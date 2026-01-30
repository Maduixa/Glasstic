# Risk matrix (health + AI + LiquidGlass)

| Domain | Risk | Failure mode | Mitigation |
|---|---|---|---|
| LiquidGlass UI | Perf/battery | Too many translucent layers, continuous animations | Use containers, avoid stacking, profile GPU/power, add feature flags |
| LiquidGlass UI | Accessibility | Low contrast, unreadable text | Test Reduce Transparency/Contrast, ensure semantic colors, add borders/tints |
| Watch companion | Reliability | Phone not reachable; stale state | Use appContext fallback, versioned schema, show last-updated |
| HealthKit | Privacy | Over-broad permissions; unexpected data access | Minimize types, explain rationale, gate features, no raw logs |
| HealthKit | Background delivery | Observer callbacks missed or slow | Use anchored queries, keep work minimal, retries on foreground |
| ML | Incorrect insights | False predictions shown as facts | Confidence thresholds, user correction, validation dataset |
| App Store | Rejection | Medical claims / unclear privacy | Conservative wording, review notes template, explicit privacy policy |
