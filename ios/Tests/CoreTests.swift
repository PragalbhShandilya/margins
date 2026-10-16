import XCTest

@testable import MarginsCore

final class CoreTests: XCTestCase {
  func testRejectsBlankAndOversizeQuotes() {
    XCTAssertThrowsError(try Quote(text: "  \n"))
    XCTAssertThrowsError(try Quote(text: String(repeating: "x", count: 2001)))
  }
  func testSearchAndFavorites() throws {
    var s = CollectionState()
    s.quotes = [
      try Quote(text: "Take a jacket", author: "Mum", kind: .life, favorite: true),
      try Quote(text: "A book", kind: .books),
    ]
    XCTAssertEqual(s.searching("MUM jacket", kind: .life, favorites: true).count, 1)
    XCTAssertTrue(s.searching("jacket", kind: .books, favorites: false).isEmpty)
  }
  func testStableSingleSelection() throws {
    var s = CollectionState()
    let q = try Quote(text: "Remember")
    s.quotes = [q]
    var m = ReminderPreferences()
    m.source = .single
    m.quoteID = q.id
    s.quotes.insert(try Quote(text: "New"), at: 0)
    XCTAssertEqual(s.pool(for: m).first?.id, q.id)
  }
  func testBackupRoundTripAndDuplicateMerge() throws {
    var s = CollectionState()
    s.quotes = [try Quote(text: "Word")]
    let restored = try JSONDecoder().decode(CollectionState.self, from: JSONEncoder().encode(s))
    XCTAssertEqual(restored, s)
    XCTAssertEqual(try s.merge(restored), 0)
    XCTAssertEqual(s.quotes.count, 1)
  }
  func testCorruptImportDoesNotMutate() throws {
    var s = CollectionState()
    s.quotes = [try Quote(text: "Keep")]
    let original = s
    var bad = CollectionState()
    bad.version = 99
    XCTAssertThrowsError(try s.merge(bad))
    XCTAssertEqual(s, original)
  }
  func testChannelPoolsFollowMembership() {
    var s = CollectionState()
    s.followedChannels = ["human"]
    var m = ReminderPreferences()
    m.source = .channels
    XCTAssertEqual(s.pool(for: m).count, 2)
    s.followedChannels = []
    XCTAssertTrue(s.pool(for: m).isEmpty)
  }
  func testInvalidWindowAndEmptyPool() {
    var p = ReminderPreferences()
    p.endMinute = p.startMinute
    XCTAssertThrowsError(try MomentPlanner.plan(preferences: p, quotes: []))
    p = ReminderPreferences()
    XCTAssertThrowsError(try MomentPlanner.plan(preferences: p, quotes: []))
  }
  func testRandomSlotsQuietHoursAndCap() throws {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Asia/Kolkata")!
    let now = c.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 8))!
    var p = ReminderPreferences()
    p.count = 3
    let plan = try MomentPlanner.plan(
      preferences: p, quotes: [try Quote(text: "Hello")], now: now, calendar: c, random: { 0.5 })
    XCTAssertEqual(plan.count, 60)
    XCTAssertEqual(Set(plan.map(\.id)).count, 60)
    for item in plan {
      let h = c.component(.hour, from: item.date)
      XCTAssertTrue(h >= 9 && h < 20)
      XCTAssertTrue(item.date > now)
    }
    XCTAssertEqual(plan.map(\.date), plan.map(\.date).sorted())
  }
  func testDSTAndNextDayPlanning() throws {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/New_York")!
    let now = c.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 22))!
    let plan = try MomentPlanner.plan(
      preferences: ReminderPreferences(), quotes: [try Quote(text: "Hello")], now: now, calendar: c,
      random: { 0.25 })
    XCTAssertEqual(c.component(.day, from: plan[0].date), 8)
    XCTAssertTrue(plan.allSatisfy { (9..<20).contains(c.component(.hour, from: $0.date)) })
  }
}
extension CoreTests {
  func testWebLibraryImportPreservesFavoritesAndAttribution() throws {
    let json =
      #"{"version":3,"quotes":[{"id":"web-1","text":"Take a jacket","author":"Mum","source":"At the door","type":"Life","saved":true,"createdAt":"2026-10-16T00:00:00Z"}],"following":["quiet","unknown"],"profile":{"name":"A reader","bio":"Hello"}}"#
    let backup = try CollectionTransfer.decode(Data(json.utf8))
    XCTAssertEqual(backup.collection.quotes.first?.kind, .life)
    XCTAssertEqual(backup.collection.quotes.first?.favorite, true)
    XCTAssertEqual(backup.collection.quotes.first?.source, "At the door")
    XCTAssertEqual(backup.collection.followedChannels, ["quiet"])
    XCTAssertFalse(backup.collection.reminders.enabled)
  }
  func testNativeBackupIncludesPhotoAndRejectsUnknownFormat() throws {
    var backup = PortableBackup(collection: CollectionState(), photo: Data([1, 2, 3]))
    let restored = try CollectionTransfer.decode(JSONEncoder().encode(backup))
    XCTAssertEqual(restored.photo, Data([1, 2, 3]))
    backup.format = "future-99"
    XCTAssertThrowsError(try CollectionTransfer.decode(JSONEncoder().encode(backup)))
  }
  func testImportRejectsInvalidCategoriesAndDuplicateIdentities() throws {
    let json =
      #"{"version":3,"quotes":[{"id":"same","text":"A","author":"Mum","source":"","type":"Other","saved":false}]}"#
    XCTAssertThrowsError(try CollectionTransfer.decode(Data(json.utf8)))
    var state = CollectionState()
    let q = try Quote(text: "A")
    state.quotes = [q, q]
    XCTAssertThrowsError(try state.validate())
  }
}
