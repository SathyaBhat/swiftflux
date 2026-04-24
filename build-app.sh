#!/bin/bash
set -e

echo "Building SwiftFlux..."
swift build -c release

echo "Creating app bundle..."
APP_DIR="SwiftFlux.app"
mkdir -p "$APP_DIR/Contents/MacOS"
cp ".build/release/SwiftFlux" "$APP_DIR/Contents/MacOS/SwiftFlux"

echo "Done! Launch with: open SwiftFlux.app"
