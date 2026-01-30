# Conversation playbooks (multi-turn)

## Playbook: add a new metric (e.g., HRV)
1) Ask agent to list required HealthKit types + unit handling
2) Ask for authorization delta + Info.plist string update
3) Ask for query implementation + caching strategy
4) Ask for UI display + LiquidGlass card
5) Ask for tests + edge cases (no data, denied permission)

## Playbook: fix a compile error from beta API churn
1) Paste compiler error + symbol name
2) Ask agent to propose 2–3 likely signature changes and how to verify in SDK
3) Ask agent to update code with conditional availability and fallback
4) Build again, repeat

## Playbook: App Store review prep
1) Ask reviewer agent for risk matrix delta
2) Generate review notes text
3) Verify privacy policy alignment and App Privacy responses
