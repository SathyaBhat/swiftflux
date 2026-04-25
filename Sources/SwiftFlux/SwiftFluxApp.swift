import SwiftUI
import AppKit

@main
struct SwiftFluxApp: App {
    @StateObject private var appState = AppState()

    init() {
        NSApplication.shared.applicationIconImage = NSImage(named: "AppIcon")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
                .frame(width: 400, height: 250)
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var serverURL: String {
        didSet {
            UserDefaults.standard.set(serverURL, forKey: "serverURL")
        }
    }

    @Published var apiToken: String {
        didSet {
            if !apiToken.isEmpty {
                KeychainHelper.shared.save(apiToken, service: "SwiftFlux", account: "apiToken")
            }
        }
    }

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    init() {
        self.serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? "https://miniflux.sathyabh.at"
        self.apiToken = KeychainHelper.shared.read(service: "SwiftFlux", account: "apiToken") ?? ""
        self.isAuthenticated = !self.apiToken.isEmpty
    }
}
