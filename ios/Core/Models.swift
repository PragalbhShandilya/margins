import Foundation

public enum QuoteKind: String, CaseIterable, Codable, Identifiable, Sendable {
  case books = "Books"
  case movies = "Movies"
  case life = "From life"
  public var id: String { rawValue }
  public var symbol: String {
    switch self {
    case .books: "book.closed"
    case .movies: "film"
    case .life: "heart"
    }
  }
}
public struct Quote: Codable, Identifiable, Equatable, Sendable {
  public var id: String
  public var text: String
  public var author: String
  public var source: String
  public var kind: QuoteKind
  public var favorite: Bool
  public var createdAt: Date
  public init(
    id: String = UUID().uuidString, text: String, author: String = "", source: String = "",
    kind: QuoteKind = .life, favorite: Bool = false, createdAt: Date = .now
  ) throws {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed.count <= 2000 else {
      throw AppIssue.message("Write a quote between 1 and 2,000 characters.")
    }
    guard author.count <= 120, source.count <= 200 else {
      throw AppIssue.message("Keep names under 120 characters and context under 200.")
    }
    self.id = id
    self.text = trimmed
    self.author = author.trimmingCharacters(in: .whitespacesAndNewlines)
    self.source = source.trimmingCharacters(in: .whitespacesAndNewlines)
    self.kind = kind
    self.favorite = favorite
    self.createdAt = createdAt
  }
  public var byline: String { author.isEmpty ? "Unknown" : author }
}
public enum AppIssue: LocalizedError {
  case message(String)
  public var errorDescription: String? {
    if case .message(let text) = self { return text }
    return nil
  }
}
public enum CardMood: String, CaseIterable, Codable, Identifiable, Sendable {
  case forest = "Forest"
  case sea = "Sea"
  case paper = "Paper"
  case photo = "My photo"
  public var id: String { rawValue }
}
public enum WordSource: String, CaseIterable, Codable, Identifiable, Sendable {
  case library = "My library"
  case favorites = "Favorites"
  case channels = "Followed channels"
  case single = "One special quote"
  public var id: String { rawValue }
}
public struct ReminderPreferences: Codable, Equatable, Sendable {
  public var enabled = false
  public var source: WordSource = .library
  public var quoteID = ""
  public var mood: CardMood = .forest
  public var count = 1
  public var startMinute = 9 * 60
  public var endMinute = 20 * 60
  public var plannedUntil: Date?
  public init() {}
  public func validate() throws {
    guard (1...3).contains(count) else {
      throw AppIssue.message("Choose one to three moments per day.")
    }
    guard (0..<1440).contains(startMinute), (1...1439).contains(endMinute), startMinute < endMinute
    else { throw AppIssue.message("Choose an end time after the start time.") }
  }
}
public struct CollectionState: Codable, Equatable, Sendable {
  public var version = 1
  public var quotes: [Quote] = []
  public var followedChannels: Set<String> = []
  public var displayName = "A reader"
  public var bio = ""
  public var reminders = ReminderPreferences()
  public init() {}
  public func validate() throws {
    guard version == 1, quotes.count <= 5000, Set(quotes.map(\.id)).count == quotes.count else {
      throw AppIssue.message("This collection has an unsupported or duplicate format.")
    }
    for q in quotes {
      _ = try Quote(id: q.id, text: q.text, author: q.author, source: q.source, kind: q.kind)
    }
    try reminders.validate()
  }
  public func pool(for preferences: ReminderPreferences) -> [Quote] {
    switch preferences.source {
    case .library: quotes
    case .favorites: quotes.filter(\.favorite)
    case .single: quotes.filter { $0.id == preferences.quoteID }
    case .channels: Channel.all.filter { followedChannels.contains($0.id) }.flatMap(\.quotes)
    }
  }
  public func searching(
    _ query: String, kind: QuoteKind?, favorites: Bool, oldestFirst: Bool = false
  ) -> [Quote] {
    let words = query.lowercased().split(whereSeparator: \.isWhitespace)
    return quotes.filter { q in
      (kind == nil || q.kind == kind) && (!favorites || q.favorite)
        && words.allSatisfy { word in
          (q.text + " " + q.author + " " + q.source).lowercased().contains(word)
        }
    }.sorted { oldestFirst ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt }
  }
  public mutating func merge(_ incoming: CollectionState) throws -> Int {
    try incoming.validate()
    var copy = self
    var added = 0
    for q in incoming.quotes
    where !copy.quotes.contains(where: {
      $0.id == q.id || ($0.text == q.text && $0.author == q.author)
    }) {
      copy.quotes.append(q)
      added += 1
    }
    copy.followedChannels.formUnion(incoming.followedChannels)
    try copy.validate()
    self = copy
    return added
  }
}
public struct Channel: Identifiable, Sendable {
  public var id: String
  public var title: String
  public var description: String
  public var symbol: String
  public var quotes: [Quote]
  private static func q(
    _ id: String, _ text: String, _ author: String, _ source: String, _ kind: QuoteKind = .books
  ) -> Quote {
    // Curated literals are validated when this catalog is loaded.
    try! Quote(id: id, text: text, author: author, source: source, kind: kind)
  }
  public static let all: [Channel] = [
    Channel(
      id: "quiet", title: "The Quiet Chapter",
      description: "Room to breathe. A slower, softer kind of day.", symbol: "leaf",
      quotes: [
        q(
          "quiet-1", "Adopt the pace of nature: her secret is patience.", "Ralph Waldo Emerson",
          "Education"),
        q(
          "quiet-2", "I went to the woods because I wished to live deliberately.",
          "Henry David Thoreau", "Walden"),
        q("quiet-3", "There is no charm equal to tenderness of heart.", "Jane Austen", "Emma"),
      ]),
    Channel(
      id: "human", title: "Absurdly Human", description: "Life is strange. We might as well laugh.",
      symbol: "sun.max",
      quotes: [
        q(
          "human-1", "I can resist everything except temptation.", "Oscar Wilde",
          "Lady Windermere’s Fan"),
        q(
          "human-2", "My brain has too many tabs open, and one of them is playing music.",
          "The Margins editors", "An original observation", .life),
      ]),
    Channel(
      id: "lines", title: "Between the Lines",
      description: "A little literature to carry into your day.", symbol: "text.book.closed",
      quotes: [
        q("lines-1", "I am no bird; and no net ensnares me.", "Charlotte Brontë", "Jane Eyre"),
        q(
          "lines-2", "We are such stuff as dreams are made on.", "William Shakespeare",
          "The Tempest, Act IV"),
      ]),
  ]
}
public struct PlannedMoment: Equatable, Sendable {
  public var id: String
  public var date: Date
  public var quote: Quote
}
public enum MomentPlanner {
  public static func plan(
    preferences: ReminderPreferences, quotes: [Quote], now: Date = .now,
    calendar: Calendar = .current, random: () -> Double = { Double.random(in: 0..<1) }
  ) throws -> [PlannedMoment] {
    try preferences.validate()
    guard !quotes.isEmpty else {
      throw AppIssue.message("Add a quote or follow a channel before enabling moments.")
    }
    var result: [PlannedMoment] = []
    let today = calendar.startOfDay(for: now)
    for offset in 0..<30 {
      guard let day = calendar.date(byAdding: .day, value: offset, to: today),
        let start = calendar.date(
          bySettingHour: preferences.startMinute / 60, minute: preferences.startMinute % 60,
          second: 0, of: day),
        let end = calendar.date(
          bySettingHour: preferences.endMinute / 60, minute: preferences.endMinute % 60, second: 0,
          of: day), end > start
      else { continue }
      let duration = end.timeIntervalSince(start) / Double(preferences.count)
      for slot in 0..<preferences.count {
        let a = start.addingTimeInterval(Double(slot) * duration)
        let b = a.addingTimeInterval(duration)
        let lower = max(a, now.addingTimeInterval(60))
        guard lower < b else { continue }
        let date = lower.addingTimeInterval(
          min(0.999999, max(0, random())) * b.timeIntervalSince(lower))
        let index = min(
          quotes.count - 1, Int(min(0.999999, max(0, random())) * Double(quotes.count)))
        result.append(
          PlannedMoment(id: "margins.\(offset).\(slot)", date: date, quote: quotes[index]))
        if result.count == 60 { return result }
      }
    }
    return result
  }
}

public struct PortableBackup: Codable, Sendable {
  public var format = "margins-ios-1"
  public var collection: CollectionState
  public var photo: Data?
  public init(collection: CollectionState, photo: Data? = nil) {
    self.collection = collection
    self.photo = photo
  }
}
public enum CollectionTransfer {
  private struct WebQuote: Decodable {
    var id: String
    var text: String
    var author: String
    var source: String
    var type: String
    var saved: Bool
    var createdAt: String?
  }
  private struct WebProfile: Decodable {
    var name: String?
    var bio: String?
  }
  private struct WebBackup: Decodable {
    var version: Int
    var quotes: [WebQuote]
    var following: [String]?
    var profile: WebProfile?
  }
  public static func decode(_ data: Data) throws -> PortableBackup {
    guard data.count < 20_000_000 else { throw AppIssue.message("Choose a backup under 20 MB.") }
    let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    if root?["format"] != nil {
      let backup = try JSONDecoder().decode(PortableBackup.self, from: data)
      guard backup.format == "margins-ios-1" else {
        throw AppIssue.message("This backup format is not supported.")
      }
      try backup.collection.validate()
      return backup
    }
    let web = try JSONDecoder().decode(WebBackup.self, from: data)
    guard web.version == 3 else {
      throw AppIssue.message("This web backup version is not supported.")
    }
    var state = CollectionState()
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let standard = ISO8601DateFormatter()
    state.quotes = try web.quotes.map { q in
      guard ["Books", "Movies", "Life"].contains(q.type) else {
        throw AppIssue.message("This backup contains an unknown quote category.")
      }
      let created =
        q.createdAt.flatMap { fractional.date(from: $0) ?? standard.date(from: $0) } ?? .now
      return try Quote(
        id: q.id, text: q.text, author: q.author, source: q.source,
        kind: q.type == "Books" ? .books : q.type == "Movies" ? .movies : .life, favorite: q.saved,
        createdAt: created)
    }
    state.followedChannels = Set(web.following ?? []).intersection(Set(Channel.all.map(\.id)))
    state.displayName = web.profile?.name ?? "A reader"
    state.bio = web.profile?.bio ?? ""
    try state.validate()
    return PortableBackup(collection: state)
  }
}
