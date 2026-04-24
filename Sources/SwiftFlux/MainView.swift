import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .frame(minWidth: 220)
                .background(Color.black)
        } content: {
            EntryListView(viewModel: viewModel)
                .frame(minWidth: 320)
                .background(Color.black)
        } detail: {
            EntryDetailView(viewModel: viewModel)
                .background(Color.black)
        }
        .background(Color.black)
        .task {
            await viewModel.loadInitialData(serverURL: appState.serverURL, apiToken: appState.apiToken)
        }
    }
}

@MainActor
class MainViewModel: ObservableObject {
    @Published var feeds: [Feed] = []
    @Published var categories: [Category] = []
    @Published var entries: [Entry] = []
    @Published var selectedFeed: Feed? = nil
    @Published var selectedCategory: Category? = nil
    @Published var selectedEntry: Entry? = nil
    @Published var selectedFilter: EntryFilter = .unread
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var unreadCounts: [Int: Int] = [:]
    @Published var showOnlyUnreadFeeds: Bool = false

    var displayedFeeds: [Feed] {
        if showOnlyUnreadFeeds {
            return feeds.filter { unreadCounts[$0.id, default: 0] > 0 }
        }
        return feeds
    }

    private var client: MinifluxClient?

    enum EntryFilter: String, CaseIterable, Identifiable {
        case unread = "Unread"
        case read = "Read"
        case starred = "Starred"
        case all = "All"

        var id: String { rawValue }

        var statusValue: String? {
            switch self {
            case .unread: return "unread"
            case .read: return "read"
            case .starred: return nil
            case .all: return nil
            }
        }

        var isStarred: Bool? {
            switch self {
            case .starred: return true
            default: return nil
            }
        }
    }

    func loadInitialData(serverURL: String, apiToken: String) async {
        guard !serverURL.isEmpty, !apiToken.isEmpty else { return }
        self.client = MinifluxClient(baseURL: serverURL, apiToken: apiToken)
        await refreshData()
    }

    func refreshData() async {
        guard let client = client else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            async let feedsTask = client.getFeeds()
            async let categoriesTask = client.getCategories()
            async let countersTask = client.getCounters()

            let (feedsResult, categoriesResult, countersResult) = try await (feedsTask, categoriesTask, countersTask)

            self.feeds = feedsResult.sorted { $0.title.lowercased() < $1.title.lowercased() }
            self.categories = categoriesResult.sorted { $0.title.lowercased() < $1.title.lowercased() }

            var counts: [Int: Int] = [:]
            for (feedIdStr, count) in countersResult.unreads {
                if let feedId = Int(feedIdStr) {
                    counts[feedId] = count
                }
            }
            self.unreadCounts = counts

            await loadEntries()
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
    }

    func loadEntries() async {
        guard let client = client else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let response: EntriesResponse

            if let feed = selectedFeed {
                response = try await client.getEntries(
                    status: selectedFilter.statusValue,
                    limit: 200,
                    starred: selectedFilter.isStarred,
                    feedId: feed.id
                )
            } else if let category = selectedCategory, category.id > 0 {
                response = try await client.getCategoryEntries(
                    categoryId: category.id,
                    status: selectedFilter.statusValue,
                    limit: 200,
                    starred: selectedFilter.isStarred
                )
            } else {
                response = try await client.getEntries(
                    status: selectedFilter.statusValue,
                    limit: 200,
                    starred: selectedFilter.isStarred
                )
            }

            self.entries = response.entries
        } catch {
            errorMessage = "Failed to load entries: \(error.localizedDescription)"
        }
    }

    func markAsRead(_ entry: Entry) async {
        guard let client = client else { return }
        do {
            try await client.updateEntries(ids: [entry.id], status: "read")
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = try await client.getEntry(id: entry.id)
            }
            await refreshData()
        } catch {
            errorMessage = "Failed to mark as read: \(error.localizedDescription)"
        }
    }

    func markAsUnread(_ entry: Entry) async {
        guard let client = client else { return }
        do {
            try await client.updateEntries(ids: [entry.id], status: "unread")
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = try await client.getEntry(id: entry.id)
            }
            await refreshData()
        } catch {
            errorMessage = "Failed to mark as unread: \(error.localizedDescription)"
        }
    }

    func toggleStar(_ entry: Entry) async {
        guard let client = client else { return }
        do {
            try await client.toggleBookmark(id: entry.id)
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = try await client.getEntry(id: entry.id)
            }
            if selectedEntry?.id == entry.id {
                selectedEntry = entries.first(where: { $0.id == entry.id })
            }
            await refreshData()
        } catch {
            errorMessage = "Failed to toggle star: \(error.localizedDescription)"
        }
    }

    func markAllAsRead() async {
        guard let client = client else { return }
        do {
            let ids = entries.filter { $0.isUnread }.map { $0.id }
            if !ids.isEmpty {
                try await client.updateEntries(ids: ids, status: "read")
                await refreshData()
            }
        } catch {
            errorMessage = "Failed to mark all as read: \(error.localizedDescription)"
        }
    }

    func refreshFeeds() async {
        guard let client = client else { return }
        do {
            try await client.refreshAllFeeds()
            try await Task.sleep(nanoseconds: 2_000_000_000)
            await refreshData()
        } catch {
            errorMessage = "Failed to refresh feeds: \(error.localizedDescription)"
        }
    }
}
