# SwiftFlux

A macOS-native RSS reader for [Miniflux](https://miniflux.app).

## Requirements

- macOS 14+
- Swift 6

## Build & Run

```bash
swift build                          # Debug build
swift build -c release               # Release build
./build-app.sh                       # Create SwiftFlux.app bundle
open SwiftFlux.app                   # Run the app
```

The app is a SwiftUI executable with no Xcode project. It targets macOS 14+ and uses strict Swift concurrency.
