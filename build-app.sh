#!/bin/bash
set -e

echo "Building SwiftFlux..."
swift build -c release

echo "Creating app bundle..."
APP_DIR="SwiftFlux.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp ".build/release/SwiftFlux" "$APP_DIR/Contents/MacOS/SwiftFlux"
cp "Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

# Touch the bundle so macOS re-reads metadata (helps with icon cache)
touch "$APP_DIR"

echo "Done! Launch with: open SwiftFlux.app"
echo ""
echo "If the dock icon is still blank, try:"
echo "  rm -rf ~/Library/Saved\\ Application\\ State/com.swiftflux.app.savedState"
echo "  killall Dock"
