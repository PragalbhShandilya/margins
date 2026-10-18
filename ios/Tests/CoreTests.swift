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
  func testCrossFieldSearchAndChronologicalSorting() throws {
    var state = CollectionState()
    let older = try Quote(id: "older", text: "Take the scenic route", author: "Mum",
      source: "Sunday walk", kind: .life, favorite: true, createdAt: Date(timeIntervalSince1970: 100))
    let newer = try Quote(id: "newer", text: "The route home", author: "Film character",
      source: "Evening film", kind: .movies, createdAt: Date(timeIntervalSince1970: 200))
    state.quotes = [older, newer]
    XCTAssertEqual(state.searching("  MUM\nSunday route  ", kind: .life, favorites: true).map(\.id), ["older"])
    XCTAssertTrue(state.searching("Mum film", kind: nil, favorites: false).isEmpty)
    XCTAssertEqual(state.searching("", kind: nil, favorites: false).map(\.id), ["newer", "older"])
    XCTAssertEqual(state.searching("route", kind: nil, favorites: false, oldestFirst: true).map(\.id), ["older", "newer"])
    XCTAssertEqual(state.searching("route", kind: .movies, favorites: false).map(\.id), ["newer"])
    XCTAssertTrue(state.searching("route", kind: .movies, favorites: true).isEmpty)
    XCTAssertEqual(state.quotes, [older, newer], "Searching must not reorder the stored collection")
  }
  func testQuietHoursControlsKeepWallTimeAcrossDSTChanges() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
    for (month, day) in [(3, 8), (11, 1)] {
      let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12)))
      for minute in [9 * 60, 20 * 60 + 15] {
        let displayed = MomentPlanner.localTime(minutes: minute, on: date, calendar: calendar)
        XCTAssertEqual(calendar.component(.hour, from: displayed), minute / 60)
        XCTAssertEqual(calendar.component(.minute, from: displayed), minute % 60)
        XCTAssertTrue(calendar.isDate(displayed, inSameDayAs: date))
      }
    }
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
  func testPhotoImportFailurePreservesPreviousCollectionAndPhoto() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appendingPathComponent("collection.json")
    let oldPhoto = folder.appendingPathComponent("photo.jpg")
    let original = CollectionState()
    let originalData = try JSONEncoder().encode(original)
    try originalData.write(to: url)
    try Data("old photo".utf8).write(to: oldPhoto)
    var incoming = original
    incoming.quotes = [try Quote(text: "Restored quote")]
    XCTAssertThrowsError(try CollectionPersistence.saveImport(incoming, photo: Data("new photo".utf8), to: url) { data, destination in
      if destination == url { throw CocoaError(.fileWriteNoPermission) }
      try data.write(to: destination, options: .atomic)
    })
    XCTAssertEqual(try Data(contentsOf: url), originalData)
    XCTAssertEqual(try Data(contentsOf: oldPhoto), Data("old photo".utf8))
    XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: folder.path)), ["collection.json", "photo.jpg"])
    let saved = try CollectionPersistence.saveImport(incoming, photo: Data("new photo".utf8), to: url)
    let loaded = try JSONDecoder().decode(CollectionState.self, from: Data(contentsOf: url))
    XCTAssertEqual(loaded.photoFilename, saved.photoFilename)
    XCTAssertEqual(loaded.quotes.first?.text, "Restored quote")
    XCTAssertEqual(try Data(contentsOf: folder.appendingPathComponent(try XCTUnwrap(loaded.photoFilename))), Data("new photo".utf8))
    XCTAssertEqual(try Data(contentsOf: oldPhoto), Data("old photo".utf8))
  }

}
