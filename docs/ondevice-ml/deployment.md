# Model deployment strategies

## Bundled
Pros: offline, simplest. Cons: app size.
Best for <= ~20–50MB models.

## On-demand
Pros: small initial download; can update independently. Cons: needs networking + caching complexity.
Use when:
- model is large
- feature is optional

## Updates
- Version your model bundle and outputs.
- Avoid breaking changes in output schema without app update.
