import Foundation
import Security

enum MinifluxError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case decodingError(Error)
    case unauthorized
    case unknown(Error)
}

@MainActor
class MinifluxClient: ObservableObject {
    let baseURL: String
    let apiToken: String

    init(baseURL: String, apiToken: String) {
        self.baseURL = baseURL
        self.apiToken = apiToken
    }

    private func makeRequest(path: String, method: String = "GET", body: Data? = nil, queryItems: [URLQueryItem]? = nil) async throws -> (Data, URLResponse) {
        guard var components = URLComponents(string: baseURL) else {
            throw MinifluxError.invalidURL
        }

        components.path = "/v1" + path
        components.queryItems = queryItems

        guard let url = components.url else {
            throw MinifluxError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiToken, forHTTPHeaderField: "X-Auth-Token")

        if let body = body {
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MinifluxError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw MinifluxError.unauthorized
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MinifluxError.httpError(httpResponse.statusCode, errorString)
        }

        return (data, response)
    }

    // MARK: - Feeds

    func getFeeds() async throws -> [Feed] {
        let (data, _) = try await makeRequest(path: "/feeds")
        return try JSONDecoder().decode([Feed].self, from: data)
    }

    func getFeed(id: Int) async throws -> Feed {
        let (data, _) = try await makeRequest(path: "/feeds/\(id)")
        return try JSONDecoder().decode(Feed.self, from: data)
    }

    func createFeed(feedUrl: String, categoryId: Int? = nil) async throws -> Int {
        let request = CreateFeedRequest(feedUrl: feedUrl, categoryId: categoryId)
        let body = try JSONEncoder().encode(request)
        let (data, _) = try await makeRequest(path: "/feeds", method: "POST", body: body)
        let response = try JSONDecoder().decode(CreateFeedResponse.self, from: data)
        return response.feedId
    }

    func refreshFeed(id: Int) async throws {
        _ = try await makeRequest(path: "/feeds/\(id)/refresh", method: "PUT")
    }

    func refreshAllFeeds() async throws {
        _ = try await makeRequest(path: "/feeds/refresh", method: "PUT")
    }

    func removeFeed(id: Int) async throws {
        _ = try await makeRequest(path: "/feeds/\(id)", method: "DELETE")
    }

    func markFeedAsRead(id: Int) async throws {
        _ = try await makeRequest(path: "/feeds/\(id)/mark-all-as-read", method: "PUT")
    }

    // MARK: - Categories

    func getCategories(counts: Bool = true) async throws -> [Category] {
        var queryItems: [URLQueryItem]?
        if counts {
            queryItems = [URLQueryItem(name: "counts", value: "true")]
        }
        let (data, _) = try await makeRequest(path: "/categories", queryItems: queryItems)
        return try JSONDecoder().decode([Category].self, from: data)
    }

    func createCategory(title: String) async throws -> Category {
        let body = try JSONEncoder().encode(["title": title])
        let (data, _) = try await makeRequest(path: "/categories", method: "POST", body: body)
        return try JSONDecoder().decode(Category.self, from: data)
    }

    func markCategoryAsRead(id: Int) async throws {
        _ = try await makeRequest(path: "/categories/\(id)/mark-all-as-read", method: "PUT")
    }

    // MARK: - Entries

    func getEntries(
        status: String? = nil,
        offset: Int? = nil,
        limit: Int = 100,
        order: String = "published_at",
        direction: String = "desc",
        starred: Bool? = nil,
        search: String? = nil,
        categoryId: Int? = nil,
        feedId: Int? = nil
    ) async throws -> EntriesResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "order", value: order),
            URLQueryItem(name: "direction", value: direction)
        ]

        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        if let starred = starred {
            queryItems.append(URLQueryItem(name: "starred", value: starred ? "true" : "false"))
        }
        if let search = search {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        if let categoryId = categoryId {
            queryItems.append(URLQueryItem(name: "category_id", value: String(categoryId)))
        }

        let path: String
        if let feedId = feedId {
            path = "/feeds/\(feedId)/entries"
        } else {
            path = "/entries"
        }

        let (data, _) = try await makeRequest(path: path, queryItems: queryItems)
        return try JSONDecoder().decode(EntriesResponse.self, from: data)
    }

    func getCategoryEntries(
        categoryId: Int,
        status: String? = nil,
        offset: Int? = nil,
        limit: Int = 100,
        order: String = "published_at",
        direction: String = "desc",
        starred: Bool? = nil
    ) async throws -> EntriesResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "order", value: order),
            URLQueryItem(name: "direction", value: direction)
        ]

        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        if let starred = starred {
            queryItems.append(URLQueryItem(name: "starred", value: starred ? "true" : "false"))
        }

        let (data, _) = try await makeRequest(path: "/categories/\(categoryId)/entries", queryItems: queryItems)
        return try JSONDecoder().decode(EntriesResponse.self, from: data)
    }

    func getEntry(id: Int) async throws -> Entry {
        let (data, _) = try await makeRequest(path: "/entries/\(id)")
        return try JSONDecoder().decode(Entry.self, from: data)
    }

    func updateEntries(ids: [Int], status: String) async throws {
        let request = UpdateEntriesRequest(entryIds: ids, status: status)
        let body = try JSONEncoder().encode(request)
        _ = try await makeRequest(path: "/entries", method: "PUT", body: body)
    }

    func toggleBookmark(id: Int) async throws {
        _ = try await makeRequest(path: "/entries/\(id)/bookmark", method: "PUT")
    }

    func fetchOriginalContent(entryId: Int) async throws -> String {
        let (data, _) = try await makeRequest(path: "/entries/\(entryId)/fetch-content?update_content=true")
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        return json?["content"] ?? ""
    }

    // MARK: - Icons

    func getFeedIcon(feedId: Int) async throws -> IconResponse {
        let (data, _) = try await makeRequest(path: "/feeds/\(feedId)/icon")
        return try JSONDecoder().decode(IconResponse.self, from: data)
    }

    // MARK: - User

    func getCurrentUser() async throws -> User {
        let (data, _) = try await makeRequest(path: "/me")
        return try JSONDecoder().decode(User.self, from: data)
    }

    // MARK: - Counters

    func getCounters() async throws -> CountersResponse {
        let (data, _) = try await makeRequest(path: "/feeds/counters")
        return try JSONDecoder().decode(CountersResponse.self, from: data)
    }
}
