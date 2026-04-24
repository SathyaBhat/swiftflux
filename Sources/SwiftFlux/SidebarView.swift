import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isRefreshing = false
    @State private var showingAddFeed = false
    @State private var showingAddCategory = false

    var body: some View {
        List(selection: sidebarSelection()) {
            Section("Filters") {
                filterRows
            }

            Section("Categories") {
                categoryRows
            }

            Section {
                feedRows
            } header: {
                FeedsSectionHeader(showOnlyUnread: $viewModel.showOnlyUnreadFeeds)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .sheet(isPresented: $showingAddFeed) {
            AddFeedView(viewModel: viewModel)
        }
    }

    private var filterRows: some View {
        ForEach(MainViewModel.EntryFilter.allCases) { filter in
            HStack {
                Image(systemName: filterIcon(for: filter))
                Text(filter.rawValue)
                Spacer()
                if filter == .unread {
                    let total = viewModel.categories.first(where: { $0.id == 0 })?.totalUnread ?? viewModel.unreadCounts.values.reduce(0, +)
                    if total > 0 {
                        Text("\(total)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tag(SidebarItem.filter(filter))
        }
    }

    private var categoryRows: some View {
        ForEach(viewModel.categories) { category in
            HStack {
                Image(systemName: "folder")
                Text(category.title)
                Spacer()
                if let count = category.totalUnread, count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tag(SidebarItem.category(category))
        }
    }

    private var feedRows: some View {
        ForEach(viewModel.displayedFeeds) { feed in
            HStack {
                if let iconId = feed.icon?.iconId {
                    FeedIconView(iconId: iconId, feedId: feed.id)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "rss")
                        .foregroundStyle(.secondary)
                }

                Text(feed.title)
                    .lineLimit(1)

                Spacer()

                if let count = viewModel.unreadCounts[feed.id], count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tag(SidebarItem.feed(feed))
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                Button(action: {
                    Task {
                        isRefreshing = true
                        await viewModel.refreshFeeds()
                        isRefreshing = false
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                .help("Refresh all feeds")

                Button(action: { showingAddFeed = true }) {
                    Image(systemName: "plus")
                }
                .help("Add new feed")

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(Color.black)
    }

    private func sidebarSelection() -> Binding<SidebarItem?> {
        Binding(
            get: {
                if let feed = viewModel.selectedFeed {
                    return .feed(feed)
                } else if let category = viewModel.selectedCategory {
                    return .category(category)
                } else {
                    return .filter(viewModel.selectedFilter)
                }
            },
            set: { newValue in
                guard let newValue = newValue else { return }
                switch newValue {
                case .feed(let feed):
                    viewModel.selectedFeed = feed
                    viewModel.selectedCategory = nil
                    viewModel.selectedFilter = .unread
                case .category(let category):
                    viewModel.selectedCategory = category
                    viewModel.selectedFeed = nil
                    viewModel.selectedFilter = .unread
                case .filter(let filter):
                    viewModel.selectedFilter = filter
                    viewModel.selectedFeed = nil
                    viewModel.selectedCategory = nil
                }
                Task {
                    await viewModel.loadEntries()
                }
            }
        )
    }

    private func filterIcon(for filter: MainViewModel.EntryFilter) -> String {
        switch filter {
        case .unread: return "envelope.badge"
        case .read: return "envelope.open"
        case .starred: return "star.fill"
        case .all: return "tray.full"
        }
    }
}

struct FeedsSectionHeader: View {
    @Binding var showOnlyUnread: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text("Feeds")
            Spacer()
            Button(action: {
                showOnlyUnread.toggle()
            }) {
                Image(systemName: showOnlyUnread ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(showOnlyUnread ? Color.accentColor : .secondary)
            }
            .buttonStyle(.borderless)
            .help(showOnlyUnread ? "Showing only feeds with unread items" : "Showing all feeds")
        }
    }
}

enum SidebarItem: Hashable {
    case feed(Feed)
    case category(Category)
    case filter(MainViewModel.EntryFilter)
}

struct FeedIconView: View {
    let iconId: Int
    let feedId: Int
    @State private var image: NSImage?
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "rss")
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            await loadIcon()
        }
    }

    private func loadIcon() async {
        guard !appState.serverURL.isEmpty, !appState.apiToken.isEmpty else { return }
        let client = MinifluxClient(baseURL: appState.serverURL, apiToken: appState.apiToken)
        do {
            let icon = try await client.getFeedIcon(feedId: feedId)
            if let commaIndex = icon.data.firstIndex(of: ","),
               let data = Data(base64Encoded: String(icon.data[icon.data.index(after: commaIndex)...])) {
                self.image = NSImage(data: data)
            }
        } catch {
            // Icon not available
        }
    }
}
