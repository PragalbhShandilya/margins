import SwiftUI

#if canImport(MarginsCore)
  import MarginsCore
#endif
// Use the property-wrapper form for compatibility with iOS 17 and later.
typealias ViewState<Value> = SwiftUI.State<Value>
extension Color {
  static let paper = Color(red: 0.975, green: 0.967, blue: 0.945)
  static let ink = Color(red: 0.17, green: 0.20, blue: 0.15)
  static let fern = Color(red: 0.30, green: 0.40, blue: 0.27)
}
struct QuoteCard: View {
  let quote: Quote
  var mood: CardMood = .forest
  var photo: UIImage?
  var compact = false
  private var colors: [Color] {
    switch mood {
    case .forest:
      [Color(red: 0.32, green: 0.43, blue: 0.31), Color(red: 0.12, green: 0.23, blue: 0.18)]
    case .sea:
      [Color(red: 0.47, green: 0.65, blue: 0.67), Color(red: 0.15, green: 0.33, blue: 0.40)]
    case .paper:
      [Color(red: 0.78, green: 0.73, blue: 0.61), Color(red: 0.48, green: 0.53, blue: 0.39)]
    case .photo: [.gray, .black]
    }
  }
  var body: some View {
    ZStack {
      LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
      if mood == .photo, let photo {
        Image(uiImage: photo).resizable().scaledToFill().overlay(.black.opacity(0.45))
      }
      if mood != .photo {
        Image(systemName: mood == .sea ? "water.waves" : "leaf").font(
          .system(size: 230, weight: .ultraLight)
        ).foregroundStyle(.white.opacity(0.07)).rotationEffect(.degrees(-25)).offset(x: 100, y: 80)
          .accessibilityHidden(true)
      }
      VStack(alignment: .leading, spacing: 20) {
        Label("A WORD TO KEEP", systemImage: "sparkle").font(
          .system(size: 10, weight: .medium, design: .rounded)
        ).tracking(2)
        Spacer(minLength: 10)
        Text("“\(quote.text)”").font(
          .system(
            size: quote.text.count > 1000
              ? 13 : quote.text.count > 600 ? 16 : quote.text.count > 350 ? 18 : compact ? 27 : 31,
            design: .serif)
        ).lineSpacing(5).minimumScaleFactor(0.6).fixedSize(horizontal: false, vertical: true)
        Text(quote.byline).font(.subheadline).opacity(0.85)
        Spacer(minLength: 10)
        HStack {
          Label("margins", systemImage: "book.pages").font(.system(.subheadline, design: .serif))
          Spacer()
          Text(quote.kind.rawValue).font(.caption).opacity(0.65)
        }
      }.padding(28).foregroundStyle(.white)
    }.frame(maxWidth: .infinity).frame(minHeight: compact ? 300 : 360).clipShape(
      RoundedRectangle(cornerRadius: 18)
    ).accessibilityElement(children: .combine)
  }
}
@MainActor enum CardRenderer {
  static func image(quote: Quote, mood: CardMood, photo: UIImage?) -> UIImage {
    let renderer = ImageRenderer(
      content: QuoteCard(quote: quote, mood: mood, photo: photo).frame(width: 540, height: 675)
        .environment(\.colorScheme, .light))
    renderer.scale = 2
    return renderer.uiImage ?? UIImage()
  }
}
struct ShareSheet: UIViewControllerRepresentable {
  var items: [Any]
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
struct QuoteRow: View {
  @EnvironmentObject var store: LibraryStore
  let quote: Quote
  var owned = true
  var edit: ((Quote) -> Void)?
  @ViewState<Bool> private var share: Bool = false
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Label(quote.kind.rawValue.uppercased(), systemImage: quote.kind.symbol).font(.caption2)
        .tracking(1).foregroundStyle(Color.fern)
      Text("“\(quote.text)”").font(.system(.title3, design: .serif)).lineSpacing(4).textSelection(
        .enabled)
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Text(quote.byline).font(.subheadline.weight(.medium))
          if !quote.source.isEmpty { Text(quote.source).font(.caption).foregroundStyle(.secondary) }
        }
        Spacer()
        if owned {
          Button {
            store.favorite(quote.id)
          } label: {
            Image(systemName: quote.favorite ? "heart.fill" : "heart").frame(width: 44, height: 44)
          }.accessibilityLabel(quote.favorite ? "Remove favorite" : "Favorite quote")
        }
      }
      Divider()
      HStack {
        if owned {
          Button("Edit") { edit?(quote) }
        } else {
          Button("Keep quote", systemImage: "plus") { store.keep(quote) }
        }
        Spacer()
        Button("Quote card", systemImage: "square.and.arrow.up") { share = true }
      }.font(.caption)
    }.padding(22).background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 14)).overlay(
      RoundedRectangle(cornerRadius: 14).strokeBorder(Color.fern.opacity(0.12))
    )
    .sheet(isPresented: $share) { CardSheet(quote: quote).environmentObject(store) }
  }
}
struct CardSheet: View {
  @EnvironmentObject var store: LibraryStore
  @Environment(\.dismiss) var dismiss
  let quote: Quote
  @ViewState<CardMood> private var mood: CardMood = .forest
  @ViewState<Bool> private var showingShare: Bool = false
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 22) {
          QuoteCard(quote: quote, mood: mood, photo: store.photo)
          Picker("Card background", selection: $mood) {
            ForEach(CardMood.allCases.filter { $0 != .photo || store.photo != nil }) { m in
              Text(m.rawValue).tag(m)
            }
          }.pickerStyle(.menu)
          Button("Share image", systemImage: "square.and.arrow.up") { showingShare = true }
            .buttonStyle(.borderedProminent)
          ShareLink(item: "“\(quote.text)” — \(quote.byline)") {
            Label("Share words", systemImage: "text.quote")
          }
        }.padding(24)
      }.background(Color.paper).navigationTitle("A word to carry").navigationBarTitleDisplayMode(
        .inline
      ).toolbar { Button("Done") { dismiss() } }.sheet(isPresented: $showingShare) {
        ShareSheet(items: [CardRenderer.image(quote: quote, mood: mood, photo: store.photo)])
      }
    }.onAppear { mood = store.state.reminders.mood }
  }
}
