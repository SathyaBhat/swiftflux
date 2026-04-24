import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.isAuthenticated {
            MainView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .background(Color.black)
        } else {
            LoginView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .background(Color.black)
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform")
                .font(.system(size: 64))
                .foregroundStyle(.primary)

            Text("SwiftFlux")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Miniflux RSS Reader for Mac")
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TextField("Server URL", text: $appState.serverURL)
                    .textFieldStyle(.roundedBorder)

                SecureField("API Token", text: $appState.apiToken)
                    .textFieldStyle(.roundedBorder)
            }
            .frame(maxWidth: 300)

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button(action: {
                Task {
                    await validateAndLogin()
                }
            }) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Connect")
                }
            }
            .disabled(appState.serverURL.isEmpty || appState.apiToken.isEmpty || isLoading)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .background(Color.black)
    }

    private func validateAndLogin() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let client = MinifluxClient(baseURL: appState.serverURL, apiToken: appState.apiToken)
        do {
            let user = try await client.getCurrentUser()
            appState.currentUser = user
            appState.isAuthenticated = true
        } catch MinifluxError.unauthorized {
            errorMessage = "Invalid API token"
        } catch {
            errorMessage = "Failed to connect: \(error.localizedDescription)"
        }
    }
}
