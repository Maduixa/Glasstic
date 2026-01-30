# Info.plist HealthKit strings (template)

Add these to the iOS app target Info.plist (and to watch target if the watch app queries HealthKit directly):

```xml
<key>NSHealthShareUsageDescription</key>
<string>This app reads your health data to provide personalized insights.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>This app writes workouts/metrics to Health so they appear in your Health app.</string>
```

Adjust strings to be specific and truthful (list the types you access and why).
