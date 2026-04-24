import SwiftUI

struct AddFeedView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var feedUrl = ""
    @State private var selectedCategoryId: Int = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var discoverResults: [DiscoverResult] = []
    @State private var showingDiscover = false
    @EnvironmentObject var appState: AppState

    struct DiscoverResult: Identifiable {
        let id = UUID()
        let url: String
        let title: String
        let type: String
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Add New Feed")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Feed URL", text: $feedUrl)
                    .textFieldStyle(.roundedBorder)

                if !viewModel.categories.isEmpty {
                    Picker("Category", selection: $selectedCategoryId) {
                        ForEach(viewModel.categories) { category in
                            Text(category.title).tag(category.id)
                        }
                    }
                }
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            if showingDiscover && !discoverResults.isEmpty {
                List(discoverResults) { result in
                    Button(action: {
                        feedUrl = result.url
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title)
                                .font(.subheadline)
                            Text(result.url)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.black)
                }
                .frame(height: 150)
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Discover") {
                    Task { await discoverFeeds() }
                }
                .disabled(feedUrl.isEmpty || isLoading)

                Button("Add Feed") {
                    Task { await addFeed() }
                }
                .disabled(feedUrl.isEmpty || isLoading)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 450)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    private func discoverFeeds() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Miniflux discover endpoint
            let body = try JSONSerialization.data(withJSONObject: ["url": feedUrl])
            var request = URLRequest(url: URL(string: appState.serverURL + "/v1/discover")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(appState.apiToken, forHTTPHeaderField: "X-Auth-Token")
            request.httpBody = body

            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let results = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
                discoverResults = results.compactMap { dict in
                    guard let url = dict["url"], let title = dict["title"], let type = dict["type"] else { return nil }
                    return DiscoverResult(url: url, title: title, type: type)
                }
                showingDiscover = true
            }
        } catch {
            errorMessage = "Discovery failed: \(error.localizedDescription)"
        }
    }

    private func addFeed() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let client = MinifluxClient(baseURL: appState.serverURL, apiToken: appState.apiToken)
        do {
            let categoryId = selectedCategoryId > 0 ? selectedCategoryId : nil
            _ = try await client.createFeed(feedUrl: feedUrl, categoryId: categoryId)
            await viewModel.refreshData()
            dismiss()
        } catch {
            errorMessage = "Failed to add feed: \(error.localizedDescription)"
        }
    }
}
