#!/usr/bin/env bash
set -euo pipefail

# Rough SDK symbol check. Best-effort; adjust paths for your local Xcode.
# Usage:
#   bash scripts/sdk_verify.sh glassEffect

SYMBOL="${1:-glassEffect}"

if command -v xcrun >/dev/null 2>&1; then
  SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
  echo "SDK: $SDK_PATH"
else
  echo "xcrun not found; install Xcode CLT."
  exit 1
fi

# Search SwiftUI swiftinterface first (fastest signal)
SWIFTUI_DIR="$(dirname "$SDK_PATH")/Developer/Library/Frameworks/SwiftUI.framework/Modules"
if [ -d "$SWIFTUI_DIR" ]; then
  echo "Searching in: $SWIFTUI_DIR"
  (command -v rg >/dev/null 2>&1 && rg -n "$SYMBOL" "$SWIFTUI_DIR") || grep -RIn "$SYMBOL" "$SWIFTUI_DIR" || true
else
  echo "SwiftUI module dir not found at expected location: $SWIFTUI_DIR"
  echo "Fallback: grep entire SDK (slow)"
  grep -RIn "$SYMBOL" "$SDK_PATH" || true
fi
