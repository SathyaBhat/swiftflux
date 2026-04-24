import SwiftUI
import WebKit

struct EntryDetailView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isLoading = false
    @State private var showOriginal = false

    var body: some View {
        Group {
            if let entry = viewModel.selectedEntry {
                EntryContentView(entry: entry, viewModel: viewModel)
            } else {
                ContentUnavailableView("No Selection", systemImage: "doc.text", description: Text("Select an entry to read."))
            }
        }
    }
}

struct EntryContentView: View {
    let entry: Entry
    @ObservedObject var viewModel: MainViewModel
    @State private var htmlContent: String = ""
    @State private var isFetchingOriginal = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.headline)
                        .textSelection(.enabled)

                    HStack(spacing: 6) {
                        if let feed = entry.feed {
                            Text(feed.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let author = entry.author, !author.isEmpty {
                            Text("by \(author)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let date = entry.publishedDate {
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text(date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: {
                        Task { await viewModel.toggleStar(entry) }
                    }) {
                        Image(systemName: entry.starred ? "star.fill" : "star")
                            .foregroundStyle(entry.starred ? .yellow : .secondary)
                    }
                    .help("Toggle star")

                    Button(action: {
                        if let url = URL(string: entry.url) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Image(systemName: "safari")
                    }
                    .help("Open in browser")

                    Button(action: {
                        Task { await toggleReadStatus() }
                    }) {
                        Image(systemName: entry.isUnread ? "envelope.open" : "envelope.badge")
                    }
                    .help(entry.isUnread ? "Mark as read" : "Mark as unread")
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .background(Color.black)

            Divider()
                .background(Color(white: 0.15))

            WebView(htmlString: htmlContent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: entry.id) {
            loadContent()
        }
    }

    private func loadContent() {
        let baseHTML = entry.content ?? "<p>No content available.</p>"
        let styled = styleHTML(baseHTML)
        self.htmlContent = styled

        // Auto-mark as read when opened
        if entry.isUnread {
            Task {
                await viewModel.markAsRead(entry)
            }
        }
    }

    private func toggleReadStatus() async {
        if entry.isUnread {
            await viewModel.markAsRead(entry)
        } else {
            await viewModel.markAsUnread(entry)
        }
    }

    private func styleHTML(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        :root {
            --bg: #ffffff;
            --text: #1a1a1a;
            --text-secondary: #444444;
            --link: #0056d6;
            --link-hover: #003d99;
            --border: #e0e0e0;
            --code-bg: #f6f8fa;
            --blockquote-border: #c0c0c0;
            --blockquote-text: #555555;
        }

        @media (prefers-color-scheme: dark) {
            :root {
                --bg: #000000;
                --text: #f0f0f0;
                --text-secondary: #a0a0a0;
                --link: #64b5f6;
                --link-hover: #bbdefb;
                --border: #2a2a2a;
                --code-bg: #111111;
                --blockquote-border: #444444;
                --blockquote-text: #999999;
            }
        }

        * {
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            font-size: 18px;
            line-height: 1.75;
            color: var(--text);
            background: var(--bg);
            max-width: 780px;
            margin: 32px auto;
            padding: 0 36px;
            -webkit-font-smoothing: antialiased;
            text-rendering: optimizeLegibility;
        }

        h1, h2, h3, h4, h5, h6 {
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", Roboto, sans-serif;
            font-weight: 700;
            line-height: 1.3;
            color: var(--text);
            margin-top: 1.6em;
            margin-bottom: 0.6em;
        }

        h1 { font-size: 2em; }
        h2 { font-size: 1.6em; }
        h3 { font-size: 1.3em; }
        h4 { font-size: 1.15em; }

        p {
            margin: 0 0 1.2em 0;
            color: var(--text);
        }

        img {
            max-width: 100%;
            height: auto;
            border-radius: 8px;
            display: block;
            margin: 1.5em auto;
        }

        pre {
            background: var(--code-bg);
            padding: 16px;
            border-radius: 10px;
            overflow-x: auto;
            font-size: 15px;
            line-height: 1.5;
            border: 1px solid var(--border);
        }

        code {
            font-family: "SF Mono", "SFMono-Regular", Menlo, Monaco, Consolas, "Liberation Mono", monospace;
            font-size: 0.92em;
            background: var(--code-bg);
            padding: 2px 6px;
            border-radius: 5px;
            border: 1px solid var(--border);
        }

        pre code {
            background: transparent;
            padding: 0;
            border: none;
            font-size: inherit;
        }

        blockquote {
            border-left: 4px solid var(--blockquote-border);
            margin: 1.2em 0;
            padding: 0.2em 0 0.2em 20px;
            color: var(--blockquote-text);
            font-style: italic;
        }

        a {
            color: var(--link);
            text-decoration: none;
            border-bottom: 1px solid transparent;
            transition: border-color 0.2s ease;
        }

        a:hover {
            color: var(--link-hover);
            border-bottom-color: var(--link);
        }

        ul, ol {
            margin: 0 0 1.2em 0;
            padding-left: 1.6em;
        }

        li {
            margin-bottom: 0.4em;
        }

        hr {
            border: none;
            border-top: 1px solid var(--border);
            margin: 2em 0;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin: 1.2em 0;
            font-size: 0.95em;
        }

        th, td {
            padding: 10px 14px;
            border-bottom: 1px solid var(--border);
            text-align: left;
        }

        th {
            font-weight: 600;
            color: var(--text);
        }
        </style>
        </head>
        <body>
        \(content)
        </body>
        </html>
        """
    }
}

struct WebView: NSViewRepresentable {
    let htmlString: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isInspectable = false
        webView.enclosingScrollView?.scrollerStyle = .overlay
        webView.enclosingScrollView?.backgroundColor = .black
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlString, baseURL: nil)
    }
}
