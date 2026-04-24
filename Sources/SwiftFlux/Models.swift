import Foundation

struct Feed: Identifiable, Codable, Hashable {
    let id: Int
    let userId: Int
    let title: String
    let siteUrl: String
    let feedUrl: String
    let checkedAt: String?
    let parsingErrorMessage: String?
    let parsingErrorCount: Int
    let disabled: Bool
    let category: Category?
    let icon: FeedIcon?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case siteUrl = "site_url"
        case feedUrl = "feed_url"
        case checkedAt = "checked_at"
        case parsingErrorMessage = "parsing_error_message"
        case parsingErrorCount = "parsing_error_count"
        case disabled
        case category
        case icon
    }
}

struct FeedIcon: Codable, Hashable {
    let feedId: Int
    let iconId: Int

    enum CodingKeys: String, CodingKey {
        case feedId = "feed_id"
        case iconId = "icon_id"
    }
}

struct Category: Identifiable, Codable, Hashable {
    let id: Int
    let userId: Int
    let title: String
    let hideGlobally: Bool?
    let feedCount: Int?
    let totalUnread: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case hideGlobally = "hide_globally"
        case feedCount = "feed_count"
        case totalUnread = "total_unread"
    }
}

struct Entry: Identifiable, Codable, Hashable {
    let id: Int
    let userId: Int
    let feedId: Int
    let title: String
    let url: String
    let commentsUrl: String?
    let author: String?
    let content: String?
    let publishedAt: String
    let createdAt: String?
    let status: String
    let starred: Bool
    let readingTime: Int?
    let feed: Feed?
    let enclosures: [Enclosure]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case feedId = "feed_id"
        case title
        case url
        case commentsUrl = "comments_url"
        case author
        case content
        case publishedAt = "published_at"
        case createdAt = "created_at"
        case status
        case starred
        case readingTime = "reading_time"
        case feed
        case enclosures
    }

    var isUnread: Bool { status == "unread" }
    var publishedDate: Date? {
        ISO8601DateFormatter().date(from: publishedAt)
    }
}

struct Enclosure: Codable, Hashable {
    let id: Int
    let userId: Int
    let entryId: Int
    let url: String
    let mimeType: String?
    let size: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case entryId = "entry_id"
        case url
        case mimeType = "mime_type"
        case size
    }
}

struct EntriesResponse: Codable {
    let total: Int
    let entries: [Entry]
}

struct IconResponse: Codable {
    let id: Int
    let data: String
    let mimeType: String

    enum CodingKeys: String, CodingKey {
        case id
        case data
        case mimeType = "mime_type"
    }
}

struct User: Codable {
    let id: Int
    let username: String
    let isAdmin: Bool
    let theme: String
    let language: String
    let timezone: String?
    let entriesPerPage: Int
    let keyboardShortcuts: Bool
    let showReadingTime: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case isAdmin = "is_admin"
        case theme
        case language
        case timezone
        case entriesPerPage = "entries_per_page"
        case keyboardShortcuts = "keyboard_shortcuts"
        case showReadingTime = "show_reading_time"
    }
}

struct CountersResponse: Codable {
    let reads: [String: Int]
    let unreads: [String: Int]
}

struct UpdateEntriesRequest: Codable {
    let entryIds: [Int]
    let status: String

    enum CodingKeys: String, CodingKey {
        case entryIds = "entry_ids"
        case status
    }
}

struct CreateFeedRequest: Codable {
    let feedUrl: String
    let categoryId: Int?

    enum CodingKeys: String, CodingKey {
        case feedUrl = "feed_url"
        case categoryId = "category_id"
    }
}

struct CreateFeedResponse: Codable {
    let feedId: Int

    enum CodingKeys: String, CodingKey {
        case feedId = "feed_id"
    }
}
