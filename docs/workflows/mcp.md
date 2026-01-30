# MCP & automation notes (optional)

If you run Claude Code with tool permissions enabled, you can:
- run `xcodebuild` for compile checks
- use `xcrun simctl` for simulator automation
- script screenshot capture for LiquidGlass snapshot baselines

## Security
Prefer allowlisted commands only.
Deny access to provisioning and secret keys (see `.claude/settings.json`).
