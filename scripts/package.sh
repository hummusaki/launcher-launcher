#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP="dist/Launcher Launcher.app"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/LauncherLauncher" "$APP/Contents/MacOS/LauncherLauncher"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
codesign --verify --strict "$APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" dist/LauncherLauncher-macOS.zip
shasum -a 256 dist/LauncherLauncher-macOS.zip > dist/SHA256SUMS.txt
