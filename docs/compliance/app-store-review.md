# App Store review notes template (copy/paste)

## HealthKit usage
- Reads: <list HK types> for <user value>
- Writes: <list HK types> for <user value>
- The app functions with limited features if permission is denied (explain).

## On-device AI
- All inference is performed on-device (Core ML / Vision / NLP).
- No raw health data is transmitted off-device (if true).

## Apple Watch companion
- Watch uses WCSession for requesting aggregates and for syncing state.
- Watch records live workout metrics (if applicable) and saves to HealthKit.

## Reviewer steps
1) Launch app → Go to Dashboard
2) Tap “Connect Health” → grant permission
3) Start a sample workout / view metric cards
