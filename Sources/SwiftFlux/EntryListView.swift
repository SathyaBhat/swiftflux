import SwiftUI

struct EntryListView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isMarkingAllRead = false
    @State private var searchText = ""
    @State private var selectedAuthor: String? = nil

    var availableAuthors: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for entry in viewModel.entries {
            guard let author = entry.author, !author.isEmpty else { continue }
            counts[author, default: 0] += 1
        }
        return counts.map { (name: $0.key, count: $0.value) }.sorted { $0.name < $1.name }
    }

    var filteredEntries: [Entry] {
        var entries = viewModel.entries
        if let author = selectedAuthor {
            entries = entries.filter { $0.author == author }
        }
        if searchText.isEmpty {
            return entries
        }
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.content ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.feed?.title ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(MainViewModel.EntryFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)

                Spacer()

                if !availableAuthors.isEmpty {
                    Menu {
                        Button("All Authors") { selectedAuthor = nil }
                        Divider()
                        ForEach(availableAuthors, id: \.name) { author in
                            Button(action: { selectedAuthor = author.name }) {
                                HStack {
                                    Text("\(author.name) (\(author.count))")
                                    if selectedAuthor == author.name {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: selectedAuthor != nil ? "person.fill" : "person")
                    }
                    .help(selectedAuthor.map { "Filtering by \($0)" } ?? "Filter by author")
                }

                Button(action: {
                    let entriesToMark = filteredEntries
                    Task {
                        isMarkingAllRead = true
                        await viewModel.markAllAsRead(from: entriesToMark)
                        isMarkingAllRead = false
                    }
                }) {
                    if isMarkingAllRead {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "envelope.open")
                    }
                }
                .help(selectedAuthor != nil ? "Mark all as read for \(selectedAuthor!)" : "Mark all as read")
                .disabled(filteredEntries.filter(\.isUnread).isEmpty || isMarkingAllRead)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.12))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom, 4)

            if viewModel.isLoading && viewModel.entries.isEmpty {
                Spacer()
                ProgressView("Loading entries...")
                Spacer()
            } else if filteredEntries.isEmpty {
                Spacer()
                ContentUnavailableView(
                    searchText.isEmpty ? "No Entries" : "No Results",
                    systemImage: searchText.isEmpty ? "tray" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "No entries found for the selected filter." : "No entries match your search.")
                )
                Spacer()
            } else {
                List(selection: $viewModel.selectedEntry) {
                    ForEach(filteredEntries) { entry in
                        EntryRow(entry: entry, visibleEntries: filteredEntries, viewModel: viewModel)
                            .tag(entry)
                            .listRowBackground(Color.black)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
        }
        .background(Color.black)
        .onChange(of: viewModel.selectedFilter) { _, _ in
            selectedAuthor = nil
            Task {
                await viewModel.loadEntries()
            }
        }
        .onChange(of: viewModel.entries) { _, _ in
            if let author = selectedAuthor, !availableAuthors.contains(where: { $0.name == author }) {
                selectedAuthor = nil
            }
        }
        .onChange(of: viewModel.selectedEntry) { oldValue, _ in
            if oldValue != nil {
                Task {
                    await viewModel.loadEntries()
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            if let msg = viewModel.errorMessage {
                Text(msg)
            }
        }
    }
}

struct EntryRow: View {
    let entry: Entry
    let visibleEntries: [Entry]
    @ObservedObject var viewModel: MainViewModel
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 13, weight: entry.isUnread ? .semibold : .regular))
                    .lineLimit(2)
                    .foregroundStyle(entry.isUnread ? .primary : .secondary)

                HStack(spacing: 6) {
                    if let feed = entry.feed {
                        Text(feed.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Text("·")
                        .foregroundStyle(.tertiary)

                    if let date = entry.publishedDate {
                        Text(date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    if let readingTime = entry.readingTime, readingTime > 0 {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("\(readingTime) min read")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    if entry.starred {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                    if entry.isUnread {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                    }
                }

                if let author = entry.author, !author.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "person")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                        Text(author)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            if entry.isUnread {
                Button("Mark as Read") {
                    Task { await viewModel.markAsRead(entry) }
                }
            } else {
                Button("Mark as Unread") {
                    Task { await viewModel.markAsUnread(entry) }
                }
            }
            Button(entry.starred ? "Remove Star" : "Star") {
                Task { await viewModel.toggleStar(entry) }
            }
            Divider()
            Button("Mark All as Read") {
                Task { await viewModel.markAllAsRead(from: visibleEntries) }
            }
        }
    }
}
