import PhotosUI
import SwiftUI

struct MomentsScreen: View {
  @EnvironmentObject var store: LibraryStore
  @ViewState<ReminderPreferences> private var preferences: ReminderPreferences =
    ReminderPreferences()
  @ViewState<PhotosPickerItem?> private var photoItem: PhotosPickerItem?
  @ViewState<Int> private var previewIndex: Int = 0
  private var words: [Quote] { store.state.pool(for: preferences) }
  private var preview: Quote? { words.isEmpty ? nil : words[previewIndex % words.count] }
  private func timeBinding(start: Bool) -> Binding<Date> {
    Binding(
      get: {
        MomentPlanner.localTime(minutes: start ? preferences.startMinute : preferences.endMinute)
      },
      set: { d in
        let parts = Calendar.current.dateComponents([.hour, .minute], from: d)
        let minute = (parts.hour ?? 9) * 60 + (parts.minute ?? 0)
        if start { preferences.startMinute = minute } else { preferences.endMinute = minute }
      })
  }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        Text("Let the words\nfind you.").font(.system(size: 38, design: .serif)).tracking(-1)
        Text("A thoughtful interruption, made your own.").foregroundStyle(.secondary)
        if let preview {
          QuoteCard(quote: preview, mood: preferences.mood, photo: store.photo, compact: true)
        } else {
          ContentUnavailableView(
            "A little space for words", systemImage: "quote.bubble",
            description: Text("Add a quote or follow a channel to begin."))
        }
        VStack(alignment: .leading, spacing: 20) {
          Picker("Choose words from", selection: $preferences.source) {
            ForEach(WordSource.allCases) { Text($0.rawValue).tag($0) }
          }
          if preferences.source == .single {
            Picker("Your quote", selection: $preferences.quoteID) {
              Text("Choose a quote").tag("")
              ForEach(store.state.quotes) { Text($0.text.prefix(60)).tag($0.id) }
            }
          }
          Divider()
          Picker("Card background", selection: $preferences.mood) {
            ForEach(CardMood.allCases) { Text($0.rawValue).tag($0) }
          }
          if preferences.mood == .photo {
            PhotosPicker(selection: $photoItem, matching: .images) {
              Label("Choose your own photo", systemImage: "photo")
            }
            Text("Your photo stays on your iPhone.").font(.caption).foregroundStyle(.secondary)
          }
          Divider()
          Picker("Moments per day", selection: $preferences.count) {
            ForEach(1...3, id: \.self) { Text("\($0)").tag($0) }
          }
          DatePicker(
            "Not before", selection: timeBinding(start: true), displayedComponents: .hourAndMinute)
          DatePicker(
            "Not after", selection: timeBinding(start: false), displayedComponents: .hourAndMinute)
          Text(
            "Random times within this window. Focus modes and iPhone notification settings can delay alerts."
          ).font(.caption).foregroundStyle(.secondary)
          Toggle("Send me random moments", isOn: $preferences.enabled)
        }.padding(22).background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
        Button {
          Task {
            await store.configure(preferences)
            preferences = store.state.reminders
          }
        } label: {
          HStack {
            Spacer()
            if store.busy { ProgressView().tint(.white) } else { Text("Save my moments") }
            Spacer()
          }.padding(8)
        }.buttonStyle(.borderedProminent).disabled(store.busy)
        HStack {
          Button("Preview another") { previewIndex += 1 }
          Spacer()
          Button("Pause reminders") {
            Task {
              await store.pause()
              preferences = store.state.reminders
            }
          }.disabled(store.busy)
        }.font(.subheadline)
        Text(store.notificationStatus).font(.subheadline).foregroundStyle(Color.fern)
        Text(
          "Works without a server, even when Margins is closed. Up to 60 moments are planned at a time; open the app regularly to replenish them. Your iPhone controls notification delivery."
        ).font(.caption).foregroundStyle(.secondary)
        Button("Open notification settings") {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
        }.font(.caption)
      }.padding(24)
    }.background(Color.paper).onAppear { preferences = store.state.reminders }.task(id: photoItem) {
      guard let photoItem else { return }
      do {
        guard let data = try await photoItem.loadTransferable(type: Data.self) else {
          throw AppIssue.message("This photo could not be opened.")
        }
        try store.savePhoto(data)
      } catch { store.error = error.localizedDescription }
    }
  }
}
struct PeopleScreen: View {
  @EnvironmentObject var store: LibraryStore
  @EnvironmentObject var community: Community
  @ViewState<String> private var query = ""
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Good words travel.").font(.system(.largeTitle, design: .serif))
        if community.address.isEmpty {
          ContentUnavailableView(
            "Your community, when you’re ready", systemImage: "person.2",
            description: Text(
              "Your personal library and iPhone notifications work now. Connect the prepared backend in Settings later to follow real readers."
            ))
        } else {
          Text(community.message).font(.subheadline).foregroundStyle(.secondary)
          HStack {
            TextField("Find a reader", text: $query).textFieldStyle(.roundedBorder)
            Button("Find") { Task { await community.discover(query) } }
          }
          if let user = community.user {
            HStack {
              Button("My shared quotes") { Task { await community.read(user) } }
              Spacer()
              Button("Following feed") { Task { await community.feed() } }
            }.font(.caption)
          }
          ForEach(community.people) { reader in readerRow(reader) }
          ForEach(community.quotes) { quote in
            VStack {
              QuoteRow(quote: quote, owned: false)
              if let user = community.user, quote.id.hasPrefix(user.id + ":") {
                Button("Unpublish", role: .destructive) {
                  Task { await community.unpublish(quote) }
                }.font(.caption)
              }
            }
          }
        }
      }.padding(24)
    }.background(Color.paper).task { if !community.address.isEmpty { await community.discover() } }
  }
  private func readerRow(_ reader: Reader) -> some View {
    HStack {
      VStack(alignment: .leading) {
        Text(reader.name).font(.system(.title3, design: .serif))
        Text("@" + reader.username).font(.caption).foregroundStyle(.secondary)
        Text("\(reader.quoteCount ?? 0) public quotes").font(.caption2).foregroundStyle(.secondary)
      }
      Spacer()
      Button("Read") { Task { await community.read(reader) } }
      if reader.id != community.user?.id {
        Button(community.following.contains(reader.id) ? "Following" : "Follow") {
          Task { await community.follow(reader) }
        }
      }
    }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 12))
  }
}
private struct BackupShare: Identifiable {
  let id = UUID()
  let url: URL
}
struct SettingsScreen: View {
  @EnvironmentObject var store: LibraryStore
  @EnvironmentObject var community: Community
  @Environment(\.dismiss) var dismiss
  @ViewState<String> private var name: String = ""
  @ViewState<String> private var bio: String = ""
  @ViewState<String> private var address: String = ""
  @ViewState<String> private var username: String = ""
  @ViewState<String> private var password: String = ""
  @ViewState<BackupShare?> private var backupShare: BackupShare?
  @ViewState<Bool> private var importing: Bool = false
  @ViewState<String> private var status: String = ""
  var body: some View {
    NavigationStack {
      Form {
        Section("Your little corner") {
          TextField("Your display name", text: $name)
          TextField("A little about you", text: $bio)
          Button("Save profile") {
            do {
              guard !name.trimmingCharacters(in: .whitespaces).isEmpty, name.count <= 60,
                bio.count <= 180
              else { throw AppIssue.message("Add a name under 60 characters and a bio under 180.") }
              try store.commit {
                $0.displayName = name
                $0.bio = bio
              }
              status = "Profile saved on this iPhone."
            } catch { store.error = error.localizedDescription }
          }
        }
        Section {
          Button("Export collection") {
            do {
              backupShare = BackupShare(url: try store.exportURL())
            } catch { store.error = error.localizedDescription }
          }
          Button("Export quotes as CSV") {
            do { backupShare = BackupShare(url: try store.exportText(markdown: false)) }
            catch { store.error = error.localizedDescription }
          }
          Button("Export quotes as Markdown") {
            do { backupShare = BackupShare(url: try store.exportText(markdown: true)) }
            catch { store.error = error.localizedDescription }
          }
          Button("Import backup or CSV") { importing = true }
          Text("CSV: text or quote column; optional author, source, kind. Kind: Books, Movies, or From life. Imports merge without deleting your quotes.")
            .font(.caption).foregroundStyle(.secondary)
          Button("Export original recovery file") {
            do {
              backupShare = BackupShare(url: try store.exportURL(recovery: true))
            } catch { store.error = error.localizedDescription }
          }
          Text(
            "Backups include your library and chosen photo. Imports merge quotes and leave reminders paused."
          ).font(.caption).foregroundStyle(.secondary)
        } header: {
          Text("Keep a copy")
        }
        Section {
          TextField("https://your-server.example", text: $address).keyboardType(.URL)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
          Button("Connect server") { Task { await community.connect(address) } }.disabled(
            community.busy)
          Text(community.message).font(.caption)
          Text(
            "Hosting is deferred. Leave this blank to use Margins privately. Profile details and published quotes will be visible on your connected server."
          ).font(.caption).foregroundStyle(.secondary)
          if !community.address.isEmpty {
            TextField("Username", text: $username).textContentType(.username)
              .textInputAutocapitalization(.never).autocorrectionDisabled()
            SecureField("Password (12+ characters)", text: $password).textContentType(.password)
            HStack {
              Button("Sign in") {
                Task {
                  await community.authenticate(
                    username: username, password: password, name: store.state.displayName,
                    create: false)
                  if community.user != nil { password = "" }
                }
              }
              Spacer()
              Button("Create account") {
                Task {
                  await community.authenticate(
                    username: username, password: password, name: store.state.displayName,
                    create: true)
                  if community.user != nil { password = "" }
                }
              }
            }.disabled(community.busy)
            if community.user != nil { Button("Sign out") { Task { await community.signOut() } } }
          }
        } header: {
          Text("Your community, later")
        }
        Section {
          Text("Margins · iPhone edition").font(.system(.headline, design: .serif))
          Text("A little home for words worth keeping.").foregroundStyle(.secondary)
        }
      }.navigationTitle("Your little corner").navigationBarTitleDisplayMode(.inline).toolbar {
        Button("Done") { dismiss() }
      }.onAppear {
        name = store.state.displayName
        bio = store.state.bio
        address = community.address
      }.sheet(item: $backupShare) { ShareSheet(items: [$0.url]) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json, .commaSeparatedText]) { result in
          do {
            let count = try store.importBackup(result.get())
            status = "\(count) \(count == 1 ? "quote" : "quotes") imported. Your existing words were kept. Moments are paused."
          } catch { store.error = error.localizedDescription }
        }
        .alert("Margins", isPresented: Binding(
          get: { !status.isEmpty },
          set: { if !$0 { status = "" } }
        )) {
          Button("OK", role: .cancel) { status = "" }
        } message: { Text(status) }
    }
  }
}
