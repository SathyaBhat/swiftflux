# AGENTS.md

## Project Overview
SwiftFlux is a macOS-native Miniflux RSS reader. It is a SwiftUI executable built with Swift Package Manager, targeting macOS 14+ with Swift 6 strict concurrency.

## Build & Run
- **Build release binary:** `swift build -c release`
- **Build debug binary:** `swift build`
- **Create `.app` bundle:** `./build-app.sh` — manually assembles `SwiftFlux.app` from the release binary, `Resources/Info.plist`, and `Resources/AppIcon.icns`. Launch with `open SwiftFlux.app`.
- There is no Xcode project or `.xcodeproj`.

## Architecture & Entrypoints
- **Entry point:** `Sources/SwiftFlux/SwiftFluxApp.swift` (`@main` `SwiftFluxApp`).
- **App state:** `AppState` is a `@StateObject` singleton that holds `serverURL` (UserDefaults) and `apiToken` (Keychain). It is injected via `.environmentObject(_:)`.
- **Networking:** `MinifluxClient` (`@MainActor`) wraps the Miniflux REST API v1 using `URLSession` and `X-Auth-Token` auth. All JSON coding keys use snake_case mapping.
- **Main UI:** `MainView` uses `NavigationSplitView` with a `SidebarView`, `EntryListView`, and `EntryDetailView`. `MainViewModel` (`@MainActor`) coordinates data loading and entry actions.
- **UI convention:** Dark-only. Every top-level view sets `.preferredColorScheme(.dark)` and `.background(Color.black)`. Maintain this when adding new windows or sheets.

## Testing
- There is no test target in `Package.swift` and no `Tests/` directory.

## Resources & Icons
- `generate_icon.py` requires Pillow (`pip install pillow`) and generates `Resources/Icon.iconset/` from a drawn canvas. The `build-app.sh` script expects a pre-built `Resources/AppIcon.icns`.
- `Resources/Info.plist` defines the bundle metadata (identifier `com.swiftflux.app`, category `public.app-category.news`).

## Persistent State
- `serverURL` is stored in `UserDefaults` under key `"serverURL"`.
- `apiToken` is stored in the macOS Keychain via `KeychainHelper` (service `"SwiftFlux"`, account `"apiToken"`).
- **Default server:** `https://miniflux.sathyabh.at`

## Concurrency Rules
- All view models (`AppState`, `MainViewModel`) and `MinifluxClient` are `@MainActor`. Do not remove this annotation; the codebase relies on Swift 6 strict concurrency.
