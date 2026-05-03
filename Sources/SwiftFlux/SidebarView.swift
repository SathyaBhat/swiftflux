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

            Section("Feeds") {
                ForEach(viewModel.sidebarRows, id: \.self) { item in
                    sidebarRow(for: item)
                }
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

    @ViewBuilder
    private func sidebarRow(for item: SidebarItem) -> some View {
        switch item {
        case .category(let category):
            HStack {
                Image(systemName: "folder")
                Text(category.title)
                Spacer()
                if let count = category.totalUnread, count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Image(systemName: viewModel.collapsedCategories.contains(category.id) ? "chevron.right" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 13, weight: .semibold))
            .tag(item)
            .onTapGesture(count: 2) {
                viewModel.toggleCategory(category.id)
            }

        case .feed(let feed):
            HStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 16)

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
            .font(.system(size: 12))
            .tag(item)

        case .filter:
            EmptyView()
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

                Button(action: {
                    viewModel.showOnlyUnreadFeeds.toggle()
                }) {
                    Image(systemName: viewModel.showOnlyUnreadFeeds ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(viewModel.showOnlyUnreadFeeds ? Color.accentColor : .secondary)
                }
                .help(viewModel.showOnlyUnreadFeeds ? "Showing only feeds with unread items" : "Showing all feeds")
                .buttonStyle(.borderless)
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
