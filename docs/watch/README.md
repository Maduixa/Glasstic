# watchOS companion architecture (watchOS 26+)

## Architecture choices
### Dependent (iPhone-first)
Watch UI is mostly a remote for iPhone app. Pros: full data + compute on phone. Cons: limited when phone not nearby.

### Independent (watch-first)
Watch can function without iPhone nearby. Pros: great for workouts. Cons: constrained storage/compute; long-term history usually lives on phone.

### Hybrid (recommended for health)
- Watch captures **live** metrics and workouts
- iPhone performs heavy analytics + long-term storage
- Watch shows top insights + controls

## Key primitives
- WatchConnectivity (`WCSession`) for sync and commands
- HealthKit on watch for live workout sessions
- WidgetKit for complications / Smart Stack surfaces

## UX constraints
- Glanceable: key metric in 1–2 seconds
- Minimal navigation depth
- Battery-sensitive; minimize background work
