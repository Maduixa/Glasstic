# Queries

## Aggregates
Use `HKStatisticsQuery` / `HKStatisticsCollectionQuery` for sums/averages over time.

## Real-time-ish updates
Pattern:
1) `HKObserverQuery` to be notified of new data
2) In its callback, run an `HKAnchoredObjectQuery` to fetch deltas
3) Update anchor and persist it (per type)

## Predicates
Always restrict by date range and relevant sources if possible.
Avoid fetching “all time” unless the feature needs it.

## Background delivery
If enabling background delivery:
- call completion handlers quickly
- do minimal work, schedule follow-up processing if needed
