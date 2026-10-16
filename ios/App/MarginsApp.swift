import SwiftUI
import UserNotifications

@MainActor final class NotificationRouter: ObservableObject {
  static let shared = NotificationRouter()
  @Published var quote: Quote?
}
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) { completionHandler([.banner, .sound, .list]) }
  func userNotificationCenter(
    _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let info = response.notification.request.content.userInfo
    Task { @MainActor in
      NotificationRouter.shared.quote = try? Quote(
        id: info["quoteID"] as? String ?? UUID().uuidString,
        text: info["text"] as? String ?? response.notification.request.content.body,
        author: info["author"] as? String ?? "", source: info["source"] as? String ?? "",
        kind: QuoteKind(rawValue: info["kind"] as? String ?? "") ?? .life)
    }
    completionHandler()
  }
}
@main struct MarginsApp: App {
  @StateObject private var store = LibraryStore()
  @StateObject private var community = Community()
  @Environment(\.scenePhase) private var scenePhase
  private let notificationDelegate = NotificationDelegate()
  init() { UNUserNotificationCenter.current().delegate = notificationDelegate }
  var body: some Scene {
    WindowGroup {
      RootView().environmentObject(store).environmentObject(community).tint(.fern)
        .preferredColorScheme(.light).onChange(of: scenePhase) { _, phase in
          if phase == .active { Task { await store.refreshOnOpen() } }
        }.task {
          await community.resume()
          await store.refreshOnOpen()
        }.alert(
          "A little attention needed",
          isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })
        ) {
          Button("OK", role: .cancel) { store.error = nil }
        } message: {
          Text(store.error ?? "")
        }
    }
  }
}
struct RootView: View {
  @EnvironmentObject var store: LibraryStore
  @ViewState<Bool> private var settings: Bool = false
  @ObservedObject private var notificationRouter = NotificationRouter.shared
  var body: some View {
    TabView {
      shell(title: "For you") { HomeScreen() }.tabItem {
        Label("For you", systemImage: "square.grid.2x2")
      }
      shell(title: "My library") { LibraryScreen() }.tabItem {
        Label("Library", systemImage: "books.vertical")
      }
      shell(title: "Moments") { MomentsScreen() }.tabItem { Label("Moments", systemImage: "bell") }
      shell(title: "Channels") { ChannelsScreen() }.tabItem {
        Label("Channels", systemImage: "circle.grid.2x2")
      }
      shell(title: "People") { PeopleScreen() }.tabItem { Label("People", systemImage: "person.2") }
    }.disabled(store.busy).sheet(isPresented: $settings) { SettingsScreen() }.sheet(
      item: $notificationRouter.quote
    ) { CardSheet(quote: $0) }
  }
  func shell<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
    NavigationStack {
      content().navigationTitle(title).toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            settings = true
          } label: {
            Image(systemName: "person.crop.circle")
          }.accessibilityLabel("Collection and settings")
        }
      }.toolbarBackground(Color.paper, for: .navigationBar)
    }
  }
}
struct HomeScreen: View {
  @EnvironmentObject var store: LibraryStore
  @ViewState<Int> private var index: Int = Calendar.current.component(.day, from: .now)
  @ViewState<Bool> private var add: Bool = false
  @ViewState<Quote?> private var editing: Quote?
  private var words: [Quote] { store.state.quotes + Channel.all.flatMap(\.quotes) }
  private var current: Quote { words[index % words.count] }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 26) {
        VStack(alignment: .leading, spacing: 12) {
          Text("A few words,\njust for you.").font(.system(size: 37, design: .serif)).tracking(-1)
          Text("Collected with love. Rediscovered when you need them.").font(.subheadline)
            .foregroundStyle(.secondary)
        }
        QuoteCard(quote: current, mood: .forest, photo: nil)
        HStack {
          Button("Another word", systemImage: "shuffle") { index += 1 }
          Spacer()
          Button("Keep quote", systemImage: "bookmark") { store.keep(current) }
        }.font(.subheadline)
        HStack {
          Text("On your bookshelf").font(.system(.title2, design: .serif))
          Spacer()
          Button {
            add = true
          } label: {
            Image(systemName: "plus.circle.fill").font(.title2)
          }.accessibilityLabel("Add a quote")
        }
        if store.state.quotes.isEmpty {
          ContentUnavailableView(
            "Your first little word", systemImage: "book.closed",
            description: Text("Keep something from a book, a film, or someone you love."))
          Button("Add your first quote") { add = true }.buttonStyle(.borderedProminent)
        } else {
          ForEach(store.state.quotes.prefix(3)) { q in QuoteRow(quote: q, edit: { editing = $0 })
          }
        }
        if !store.state.followedChannels.isEmpty {
          Text("From your channels").font(.system(.title2, design: .serif))
          ForEach(
            Channel.all.filter { store.state.followedChannels.contains($0.id) }.flatMap(\.quotes)
              .prefix(3)
          ) { q in QuoteRow(quote: q, owned: false) }
        }
        Text("A small space for words that make life a little bigger.").font(
          .system(.caption, design: .serif).italic()
        ).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 20)
      }.padding(24)
    }.background(Color.paper).sheet(isPresented: $add) { QuoteEditor() }.sheet(item: $editing) {
      QuoteEditor(existing: $0)
    }
  }
}
struct LibraryScreen: View {
  @EnvironmentObject var store: LibraryStore
  @EnvironmentObject var community: Community
  @ViewState<String> private var query: String = ""
  @ViewState<QuoteKind?> private var kind: QuoteKind?
  @ViewState<Bool> private var favorites: Bool = false
  @ViewState<Bool> private var oldest: Bool = false
  @ViewState<Bool> private var add: Bool = false
  @ViewState<Quote?> private var editing: Quote?
  @ViewState<Quote?> private var remove: Quote?
  @ViewState<Quote?> private var undo: Quote?
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack {
            filter("All", selected: kind == nil && !favorites) {
              kind = nil
              favorites = false
            }
            ForEach(QuoteKind.allCases) { k in
              filter(k.rawValue, selected: kind == k) {
                kind = k
                favorites = false
              }
            }
            filter("Favorites", selected: favorites) {
              favorites.toggle()
              kind = nil
            }
          }
        }
        HStack {
          Text("\(store.state.quotes.count) words kept").font(.caption).foregroundStyle(.secondary)
          Spacer()
          Menu {
            Button("Newest first") { oldest = false }
            Button("Oldest first") { oldest = true }
          } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down").font(.caption)
          }
        }
        let list = store.state.searching(
          query, kind: kind, favorites: favorites, oldestFirst: oldest)
        if list.isEmpty {
          ContentUnavailableView(
            "A little space for words", systemImage: "books.vertical",
            description: Text(
              store.state.quotes.isEmpty
                ? "Add your first quote to begin." : "Try a different search or collection."))
        }
        ForEach(list) { q in
          VStack {
            QuoteRow(quote: q, edit: { editing = $0 })
            HStack {
              Button("Remove", role: .destructive) { remove = q }
              Spacer()
              if community.user != nil {
                Button("Publish") {
                  Task {
                    await community.publish(q)
                    store.error = community.message
                  }
                }
              }
            }.font(.caption).padding(.horizontal, 8)
          }
        }
        if let undo {
          Button("Undo removal") {
            store.add(undo)
            self.undo = nil
          }.buttonStyle(.bordered)
        }
      }.padding(24)
    }.background(Color.paper).searchable(text: $query, prompt: "A quote, person, or little context")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) { Button("Add", systemImage: "plus") { add = true } }
      }.sheet(isPresented: $add) { QuoteEditor() }.sheet(item: $editing) {
        QuoteEditor(existing: $0)
      }.confirmationDialog(
        "Remove this quote?",
        isPresented: Binding(get: { remove != nil }, set: { if !$0 { remove = nil } }),
        titleVisibility: .visible
      ) {
        Button("Remove quote", role: .destructive) {
          if let q = remove {
            undo = q
            store.remove(q.id)
          }
          remove = nil
        }
        Button("Keep it", role: .cancel) { remove = nil }
      } message: {
        Text(
          "You can undo this afterward. Published community copies are separate; unpublish them in People."
        )
      }
  }
  private func filter(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title).font(.subheadline).padding(.horizontal, 16).padding(.vertical, 12).background(
        selected ? Color.fern.opacity(0.16) : Color.white, in: Capsule())
    }.foregroundStyle(Color.ink).accessibilityAddTraits(selected ? .isSelected : [])
  }
}
struct QuoteEditor: View {
  @EnvironmentObject var store: LibraryStore
  @Environment(\.dismiss) var dismiss
  var existing: Quote?
  @ViewState<String> private var text: String = ""
  @ViewState<String> private var author: String = ""
  @ViewState<String> private var source: String = ""
  @ViewState<QuoteKind> private var kind: QuoteKind = .books
  @ViewState<String> private var error: String = ""
  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextEditor(text: $text).frame(minHeight: 160).font(.system(.title3, design: .serif))
            .accessibilityLabel("The quote")
          Text("\(text.count) / 2,000").font(.caption).foregroundStyle(.secondary)
        } header: {
          Text("What stayed with you?")
        }
        Section("A little context") {
          TextField("Who said it? Optional", text: $author)
          TextField("Book, film, or a memory. Optional", text: $source)
          Picker("From", selection: $kind) {
            ForEach(QuoteKind.allCases) { Text($0.rawValue).tag($0) }
          }
        }
        if !error.isEmpty { Text(error).foregroundStyle(.red) }
      }.navigationTitle(existing == nil ? "A word worth keeping" : "Keep the words just right")
        .navigationBarTitleDisplayMode(.inline).toolbar {
          ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
          ToolbarItem(placement: .confirmationAction) {
            Button("Keep") {
              do {
                let q = try Quote(
                  id: existing?.id ?? UUID().uuidString, text: text, author: author, source: source,
                  kind: kind, favorite: existing?.favorite ?? false,
                  createdAt: existing?.createdAt ?? .now)
                try store.upsert(q)
                dismiss()
              } catch { self.error = error.localizedDescription }
            }
          }
        }
    }.onAppear {
      if let existing {
        text = existing.text
        author = existing.author
        source = existing.source
        kind = existing.kind
      }
    }
  }
}
struct ChannelsScreen: View {
  @EnvironmentObject var store: LibraryStore
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Find your kind of words.").font(.system(.largeTitle, design: .serif))
        Text("A little wisdom. A little wit. Something that feels like you.").foregroundStyle(
          .secondary)
        ForEach(Channel.all) { c in
          VStack(alignment: .leading, spacing: 14) {
            Label(c.title, systemImage: c.symbol).font(.system(.title2, design: .serif))
            Text(c.description).font(.subheadline).foregroundStyle(.secondary)
            HStack {
              NavigationLink("Read \(c.quotes.count) quotes") {
                ScrollView {
                  LazyVStack(spacing: 18) {
                    ForEach(c.quotes) { QuoteRow(quote: $0, owned: false) }
                  }.padding(24)
                }.background(Color.paper).navigationTitle(c.title).navigationBarTitleDisplayMode(
                  .inline)
              }
              Spacer()
              Button(store.state.followedChannels.contains(c.id) ? "Following" : "Follow") {
                store.follow(c.id)
              }.buttonStyle(.bordered)
            }
          }.padding(24).background(
            Color.fern.opacity(c.id == "human" ? 0.06 : 0.1), in: RoundedRectangle(cornerRadius: 16)
          )
        }
      }.padding(24)
    }.background(Color.paper)
  }
}
