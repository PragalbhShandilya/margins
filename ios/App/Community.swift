import Security
import SwiftUI

#if canImport(MarginsCore)
  import MarginsCore
#endif
private struct ServerFailure: Decodable { var error: String }
struct Reader: Codable, Identifiable {
  var id: String
  var username: String
  var name: String
  var bio: String
  var quoteCount: Int?
}
struct CommunityWords: Decodable {
  var id: String
  var text: String
  var author: String
  var source: String
  var type: String
  var quote: Quote? {
    try? Quote(
      id: id, text: text, author: author, source: source,
      kind: type == "Books" ? .books : type == "Movies" ? .movies : .life)
  }
}
@MainActor final class Community: ObservableObject {
  @Published var address = UserDefaults.standard.string(forKey: "community-address") ?? ""
  @Published var user: Reader?
  @Published var people: [Reader] = []
  @Published var following: Set<String> = []
  @Published var quotes: [Quote] = []
  @Published var message = "Connect your community when the backend is ready."
  @Published var busy = false
  private var token: String? {
    get {
      let q: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "Margins.community", kSecAttrAccount as String: address,
        kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne,
      ]
      var result: CFTypeRef?
      guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
        let data = result as? Data
      else { return nil }
      return String(data: data, encoding: .utf8)
    }
    set {
      let q: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "Margins.community", kSecAttrAccount as String: address,
      ]
      SecItemDelete(q as CFDictionary)
      if let newValue {
        var add = q
        add[kSecValueData as String] = Data(newValue.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
      }
    }
  }
  private func root() throws -> URL {
    guard let u = URL(string: address), u.scheme == "https", u.host != nil, u.user == nil,
      u.password == nil, u.query == nil, u.fragment == nil, u.path.isEmpty || u.path == "/"
    else { throw AppIssue.message("Enter an HTTPS server address without a path or password.") }
    return u
  }
  private func request<T: Decodable>(
    _ path: String, method: String = "GET", body: [String: String]? = nil, as type: T.Type
  ) throws -> URLRequest {
    let root = try root()
    guard let url = URL(string: path, relativeTo: root) else {
      throw AppIssue.message("This server address is invalid.")
    }
    var req = URLRequest(url: url)
    req.httpMethod = method
    req.timeoutInterval = 15
    if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
    if let body {
      req.httpBody = try JSONEncoder().encode(body)
      req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    return req
  }
  private func call<T: Decodable>(
    _ path: String, method: String = "GET", body: [String: String]? = nil, as type: T.Type
  ) async throws -> T {
    let req = try request(path, method: method, body: body, as: type)
    let (data, response) = try await URLSession.shared.data(for: req)
    guard let http = response as? HTTPURLResponse else {
      throw AppIssue.message("The server did not respond.")
    }
    if !(200..<300).contains(http.statusCode) {
      throw AppIssue.message(
        (try? JSONDecoder().decode(ServerFailure.self, from: data).error)
          ?? "The request failed. Try again.")
    }
    return try JSONDecoder().decode(T.self, from: data)
  }
  func connect(_ value: String) async {
    guard !busy else { return }
    busy = true
    defer { busy = false }
    let old = address
    let candidate = value.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(
      in: CharacterSet(charactersIn: "/"))
    if candidate == old {
      message = "This server is already connected. Your sign-in is kept."
      return
    }
    do {
      address = candidate
      do {
        struct Health: Decodable { var app: String }
        let health = try await call("/api/health", as: Health.self)
        guard health.app == "margins" else {
          throw AppIssue.message("This is not a Margins server.")
        }
      } catch {
        address = old
        throw error
      }
      address = old
      if token != nil {
        guard await signOut() else {
          throw AppIssue.message("Sign out of the current server before switching.")
        }
      }
      address = candidate
      UserDefaults.standard.set(address, forKey: "community-address")
      user = nil
      people = []
      quotes = []
      following = []
      message = "Server connected. Sign in to follow readers."
      await resume()
    } catch {
      address = old
      message = error.localizedDescription
    }
  }
  func authenticate(username: String, password: String, name: String, create: Bool) async {
    guard !busy else { return }
    busy = true
    defer { busy = false }
    do {
      if let user, user.username != username.lowercased() {
        throw AppIssue.message("Sign out before switching accounts.")
      }
      struct Auth: Decodable {
        var token: String
        var user: Reader
      }
      let r = try await call(
        create ? "/api/signup" : "/api/signin", method: "POST",
        body: ["username": username, "password": password, "name": name], as: Auth.self)
      token = r.token
      user = r.user
      message = "Signed in as @\(r.user.username)."
      await discover()
    } catch { message = error.localizedDescription }
  }
  func resume() async {
    guard token != nil else { return }
    do {
      struct Me: Decodable { var user: Reader }
      user = try await call("/api/me", as: Me.self).user
      await discover()
    } catch { message = "Sign in again to use the community. \(error.localizedDescription)" }
  }
  @discardableResult func signOut() async -> Bool {
    do {
      struct OK: Decodable { var ok: Bool }
      _ = try await call("/api/signout", method: "POST", as: OK.self)
      token = nil
      user = nil
      following = []
      quotes = []
      message = "Signed out. Your private iPhone library is kept."
      return true
    } catch {
      message =
        "Sign-out was not confirmed. Stay connected and retry. \(error.localizedDescription)"
      return false
    }
  }
  func discover(_ query: String = "") async {
    do {
      struct Result: Decodable {
        var people: [Reader]
        var following: [String]
      }
      let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
      let r = try await call("/api/people?q=\(encoded)", as: Result.self)
      people = r.people
      following = Set(r.following)
      message =
        people.isEmpty ? "No readers found yet." : "\(people.count) readers in this community."
    } catch { message = error.localizedDescription }
  }
  func follow(_ reader: Reader) async {
    guard user != nil else {
      message = "Sign in to follow a reader."
      return
    }
    do {
      struct OK: Decodable { var ok: Bool }
      _ = try await call(
        "/api/follows/\(reader.id)", method: following.contains(reader.id) ? "DELETE" : "PUT",
        as: OK.self)
      await discover()
      await feed()
    } catch { message = error.localizedDescription }
  }
  func read(_ reader: Reader) async {
    do {
      struct Result: Decodable { var quotes: [CommunityWords] }
      quotes = try await call("/api/users/\(reader.id)/quotes", as: Result.self).quotes.compactMap(
        \.quote)
      message = "\(reader.name)’s shared words"
    } catch { message = error.localizedDescription }
  }
  func feed() async {
    do {
      struct Result: Decodable { var quotes: [CommunityWords] }
      quotes = try await call("/api/feed", as: Result.self).quotes.compactMap(\.quote)
      message = "From readers you follow"
    } catch { message = error.localizedDescription }
  }
  func publish(_ quote: Quote) async {
    guard user != nil else {
      message = "Sign in before publishing."
      return
    }
    do {
      struct OK: Decodable { var ok: Bool }
      _ = try await call(
        "/api/quotes/\(quote.id)", method: "PUT",
        body: [
          "text": quote.text, "author": quote.byline, "source": quote.source,
          "type": quote.kind == .life ? "Life" : quote.kind.rawValue,
        ], as: OK.self)
      message = "Quote published. You can remove it from your shared collection below."
    } catch { message = error.localizedDescription }
  }
  func unpublish(_ quote: Quote) async {
    guard let user else { return }
    let prefix = user.id + ":"
    guard quote.id.hasPrefix(prefix) else { return }
    let id = String(quote.id.dropFirst(prefix.count))
    do {
      struct OK: Decodable { var ok: Bool }
      _ = try await call("/api/quotes/\(id)", method: "DELETE", as: OK.self)
      await read(user)
    } catch { message = error.localizedDescription }
  }
}
