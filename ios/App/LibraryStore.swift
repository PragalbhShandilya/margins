import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

#if canImport(MarginsCore)
  import MarginsCore
#endif

@MainActor final class LibraryStore: ObservableObject {
  @Published private(set) var state = CollectionState()
  @Published var error: String?
  @Published var busy = false
  @Published var notificationStatus = "Moments are paused."
  private let folder: URL
  private var quarantine = false
  private let center = UNUserNotificationCenter.current()
  init() {
    folder = URL.applicationSupportDirectory.appending(path: "Margins", directoryHint: .isDirectory)
    do {
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      if FileManager.default.fileExists(atPath: collectionURL.path) {
        let loaded = try JSONDecoder().decode(
          CollectionState.self, from: Data(contentsOf: collectionURL))
        try loaded.validate()
        state = loaded
      }
    } catch {
      quarantine = true
      self.error =
        "Your original collection has been preserved. Export the recovery file in Settings before restoring a backup. \(error.localizedDescription)"
    }
  }
  var collectionURL: URL { folder.appending(path: "collection.json") }
  var photoURL: URL { folder.appending(path: "photo.jpg") }
  var photo: UIImage? { UIImage(contentsOfFile: photoURL.path) }
  func commit(_ change: (inout CollectionState) throws -> Void) throws {
    guard !quarantine else {
      throw AppIssue.message(
        "Export your original recovery file and restore a valid backup before making changes.")
    }
    var copy = state
    try change(&copy)
    try copy.validate()
    let data = try JSONEncoder().encode(copy)
    try data.write(
      to: collectionURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    state = copy
  }
  func change(_ action: (inout CollectionState) throws -> Void) {
    do { try commit(action) } catch { self.error = error.localizedDescription }
  }
  func upsert(_ quote: Quote) throws {
    try commit { s in
      if let i = s.quotes.firstIndex(where: { $0.id == quote.id }) {
        s.quotes[i] = quote
      } else {
        guard s.quotes.count < 5000 else {
          throw AppIssue.message(
            "Your library holds 5,000 quotes. Export a backup and make room first.")
        }
        s.quotes.insert(quote, at: 0)
      }
    }
    refreshIfNeeded()
  }
  func add(_ quote: Quote) {
    do { try upsert(quote) } catch { self.error = error.localizedDescription }
  }
  func keep(_ quote: Quote) {
    guard !state.quotes.contains(where: { $0.text == quote.text && $0.author == quote.author })
    else { return }
    do {
      add(try Quote(text: quote.text, author: quote.author, source: quote.source, kind: quote.kind))
    } catch { self.error = error.localizedDescription }
  }
  func favorite(_ id: String) {
    change { s in
      if let i = s.quotes.firstIndex(where: { $0.id == id }) { s.quotes[i].favorite.toggle() }
    }
    refreshIfNeeded()
  }
  func remove(_ id: String) {
    change { s in
      s.quotes.removeAll { $0.id == id }
      if s.reminders.quoteID == id {
        s.reminders.source = .library
        s.reminders.quoteID = ""
      }
    }
    refreshIfNeeded()
  }
  func follow(_ id: String) {
    change { s in
      if s.followedChannels.contains(id) {
        s.followedChannels.remove(id)
      } else {
        s.followedChannels.insert(id)
      }
    }
    refreshIfNeeded()
  }
  func savePhoto(_ data: Data) throws {
    guard data.count <= 15_000_000, let original = UIImage(data: data) else {
      throw AppIssue.message("Choose a JPEG, PNG, or HEIC photo under 15 MB.")
    }
    let scale = min(1, 1200 / max(original.size.width, original.size.height))
    let size = CGSize(width: original.size.width * scale, height: original.size.height * scale)
    let image = UIGraphicsImageRenderer(size: size).image { _ in
      original.draw(in: CGRect(origin: .zero, size: size))
    }
    guard let compressed = image.jpegData(compressionQuality: 0.8) else {
      throw AppIssue.message("This photo could not be read.")
    }
    try compressed.write(
      to: photoURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    objectWillChange.send()
  }
  func exportURL(recovery: Bool = false) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appending(
      path: recovery ? "Margins-recovery.json" : "Margins-collection.json")
    if recovery {
      try Data(contentsOf: collectionURL).write(to: url, options: .atomic)
    } else {
      let backup = PortableBackup(collection: state, photo: try? Data(contentsOf: photoURL))
      try JSONEncoder().encode(backup).write(to: url, options: .atomic)
    }
    return url
  }
  func importBackup(_ url: URL) throws -> Int {
    let access = url.startAccessingSecurityScopedResource()
    defer { if access { url.stopAccessingSecurityScopedResource() } }
    let data = try Data(contentsOf: url)
    guard data.count < 20_000_000 else { throw AppIssue.message("Choose a backup under 20 MB.") }
    let backup = try CollectionTransfer.decode(data)
    try backup.collection.validate()
    var copy = state
    let count = try copy.merge(backup.collection)
    if quarantine {
      copy.displayName = backup.collection.displayName
      copy.bio = backup.collection.bio
    }
    // Restoring a backup never enables reminders without a fresh permission check.
    copy.reminders.enabled = false
    copy.reminders.plannedUntil = nil
    if let image = backup.photo {
      try savePhoto(image)
      copy.reminders.mood = .photo
    }
    let encoded = try JSONEncoder().encode(copy)
    try encoded.write(
      to: collectionURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    quarantine = false
    state = copy
    Task { await pause() }
    return count
  }
  private func refreshIfNeeded() {
    if state.reminders.enabled {
      if state.pool(for: state.reminders).isEmpty {
        Task {
          await pause()
          self.error = "Moments were paused because the selected collection is empty."
        }
      } else {
        Task { await configure(state.reminders, requestPermission: false) }
      }
    }
  }
  func pause() async {
    let ids = await center.pendingNotificationRequests().map(\.identifier).filter {
      $0.hasPrefix("margins.")
    }
    center.removePendingNotificationRequests(withIdentifiers: ids)
    center.removeDeliveredNotifications(withIdentifiers: ids)
    change {
      $0.reminders.enabled = false
      $0.reminders.plannedUntil = nil
    }
    notificationStatus = "Moments are paused. Your design is kept."
  }
  func configure(_ requested: ReminderPreferences, requestPermission: Bool = true) async {
    guard !busy else {
      error = "A moment update is in progress. Try again in a second."
      return
    }
    busy = true
    defer { busy = false }
    var oldRequests: [UNNotificationRequest] = []
    do {
      try requested.validate()
      guard requested.enabled else {
        try commit { $0.reminders = requested }
        await pause()
        return
      }
      let settings = await center.notificationSettings()
      if settings.authorizationStatus == .notDetermined && requestPermission {
        guard try await center.requestAuthorization(options: [.alert, .sound, .badge]) else {
          throw AppIssue.message(
            "Notifications were not allowed. You can enable them in iPhone Settings.")
        }
      }
      let allowed = await center.notificationSettings().authorizationStatus
      guard allowed == .authorized || allowed == .provisional else {
        throw AppIssue.message(
          "Enable notifications for Margins in iPhone Settings, then save again.")
      }
      if requested.mood == .photo && photo == nil {
        throw AppIssue.message("Choose a photo for this card first.")
      }
      let plans = try MomentPlanner.plan(preferences: requested, quotes: state.pool(for: requested))
      let requests = try plans.map { plan -> UNNotificationRequest in
        let content = UNMutableNotificationContent()
        content.title = "A moment from Margins"
        content.body = "\(plan.quote.text) — \(plan.quote.byline)"
        content.sound = .default
        content.userInfo = [
          "quoteID": plan.quote.id, "text": plan.quote.text, "author": plan.quote.author,
          "source": plan.quote.source, "kind": plan.quote.kind.rawValue,
        ]
        content.threadIdentifier = "margins.words"
        let attachmentURL = folder.appending(
          path: "moment-\(plan.id.replacingOccurrences(of:".",with:"-" )).jpg")
        let image = CardRenderer.image(quote: plan.quote, mood: requested.mood, photo: photo)
        if let jpeg = image.jpegData(compressionQuality: 0.65) {
          try jpeg.write(to: attachmentURL, options: .atomic)
          content.attachments = [
            try UNNotificationAttachment(identifier: "card", url: attachmentURL)
          ]
        }
        let parts = Calendar.current.dateComponents(
          [.year, .month, .day, .hour, .minute, .second], from: plan.date)
        return UNNotificationRequest(
          identifier: plan.id, content: content,
          trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
      }
      oldRequests = await center.pendingNotificationRequests().filter {
        $0.identifier.hasPrefix("margins.")
      }
      center.removePendingNotificationRequests(withIdentifiers: oldRequests.map(\.identifier))
      do { for request in requests { try await center.add(request) } } catch {
        center.removePendingNotificationRequests(withIdentifiers: requests.map(\.identifier))
        for old in oldRequests { try? await center.add(old) }
        throw error
      }
      var saved = requested
      saved.plannedUntil = plans.last?.date
      do { try commit { $0.reminders = saved } } catch {
        center.removePendingNotificationRequests(withIdentifiers: requests.map(\.identifier))
        for old in oldRequests { try? await center.add(old) }
        throw error
      }
      notificationStatus =
        "\(requests.count) moments planned through \(plans.last?.date.formatted(date:.abbreviated,time:.omitted) ?? "the coming days"). Open Margins regularly to refresh the plan."
    } catch {
      self.error = error.localizedDescription
      notificationStatus = "The new schedule was not saved. \(error.localizedDescription)"
    }
  }
  func refreshOnOpen() async {
    guard state.reminders.enabled else { return }
    let pending = await center.pendingNotificationRequests().filter {
      $0.identifier.hasPrefix("margins.")
    }
    if pending.count < 30 {
      await configure(state.reminders, requestPermission: false)
    } else {
      notificationStatus =
        "\(pending.count) moments are scheduled. Quiet hours follow your iPhone’s calendar."
    }
  }
}
struct BackupDocument: FileDocument {
  static var readableContentTypes: [UTType] { [.json] }
  var data: Data
  init(data: Data) { self.data = data }
  init(configuration: ReadConfiguration) throws {
    data = configuration.file.regularFileContents ?? Data()
  }
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}
