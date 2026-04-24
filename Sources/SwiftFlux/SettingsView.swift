import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingLogoutConfirmation = false

    var body: some View {
        Form {
            Section {
                TextField("Server URL", text: $appState.serverURL)
                    .textFieldStyle(.roundedBorder)

                SecureField("API Token", text: $appState.apiToken)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Miniflux Server")
            } footer: {
                Text("Enter your self-hosted Miniflux server URL and API token. Generate an API token from Miniflux Settings > API Keys.")
                    .font(.caption)
            }

            if let user = appState.currentUser {
                Section {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(user.username)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Admin")
                        Spacer()
                        Text(user.isAdmin ? "Yes" : "No")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Account")
                }
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    showingLogoutConfirmation = true
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .preferredColorScheme(.dark)
        .background(Color.black)
        .confirmationDialog("Sign Out?", isPresented: $showingLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                KeychainHelper.shared.delete(service: "SwiftFlux", account: "apiToken")
                appState.apiToken = ""
                appState.isAuthenticated = false
                appState.currentUser = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to sign in again to access your feeds.")
        }
    }
}
