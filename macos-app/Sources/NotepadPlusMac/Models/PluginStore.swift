import Foundation
import CryptoKit
import JavaScriptCore

// MARK: - Community plugin format
//
// A community plugin is a folder holding `manifest.json` and `main.js`. The script is plain JavaScript run inside
// JavaScriptCore with no file, network or process access: it receives text and returns text.
//
//     commands.upper = function (text, ctx) { return text.toUpperCase(); };
//
// `ctx` describes the document: { language: "Java", fileName: "Main.java", extension: "java" }.

public struct PluginCommand: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String
}

/// `manifest.json` of an installed plugin, and also the shape of one `catalog.json` entry.
public struct CommunityPluginManifest: Codable, Equatable {
    public let id: String
    public let name: String
    public let version: String
    public let author: String
    public let summary: String
    public let documentation: String?
    public let license: String
    public let category: String
    public let icon: String?
    public let homepage: String?
    public let commands: [PluginCommand]
    /// Catalog only: where `main.js` is downloaded from.
    public let downloadURL: String?
    /// Catalog only: lowercase hex SHA-256 of `main.js`. Installation is refused when it does not match.
    public let sha256: String?
}

public struct CommunityPluginCatalog: Codable {
    public let plugins: [CommunityPluginManifest]
}

public enum PluginStoreError: LocalizedError {
    case invalidManifest(String)
    case untrustedSource(URL)
    case downloadFailed(String)
    case tooLarge
    case checksumMismatch
    case missingChecksum
    case notFound

    public var errorDescription: String? {
        switch self {
        case .invalidManifest(let why): return "The plugin manifest is invalid: \(why)."
        case .untrustedSource(let url): return "Downloads from \(url.host ?? url.absoluteString) are not allowed."
        case .downloadFailed(let why): return "The download failed: \(why)"
        case .tooLarge: return "The plugin script is larger than the 256 KB limit."
        case .checksumMismatch: return "The downloaded file does not match its published SHA-256 checksum, so it was discarded."
        case .missingChecksum: return "The catalog entry has no SHA-256 checksum, so it cannot be verified."
        case .notFound: return "The plugin is not installed."
        }
    }
}

// MARK: - On-disk store
public final class PluginStore {
    public static let shared = PluginStore()

    public static let maxScriptBytes = 256 * 1024
    private static let trustedHosts: Set<String> = ["raw.githubusercontent.com"]

    public let directory: URL
    private let fm = FileManager.default

    public init(directory: URL? = nil) {
        if let directory = directory {
            self.directory = directory
        } else {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.directory = support.appendingPathComponent("NPad++/Plugins", isDirectory: true)
        }
    }

    // Ids become folder names, so they must not be able to escape the plugins directory.
    public static func isValid(_ manifest: CommunityPluginManifest) -> String? {
        if manifest.id.range(of: "^[a-z0-9][a-z0-9_-]{0,63}$", options: .regularExpression) == nil {
            return "id must be lowercase letters, digits, '-' or '_'"
        }
        if manifest.name.isEmpty || manifest.version.isEmpty { return "name and version are required" }
        for c in manifest.commands where c.id.range(of: "^[A-Za-z_][A-Za-z0-9_]{0,63}$", options: .regularExpression) == nil {
            return "command id '\(c.id)' is not a valid identifier"
        }
        return nil
    }

    /// HTTPS from GitHub's raw host only. A `file://` download is accepted solely when the catalog itself is a local file (development).
    public static func isTrusted(_ url: URL, catalogURL: URL) -> Bool {
        if url.scheme == "https", let host = url.host?.lowercased() { return trustedHosts.contains(host) }
        return url.isFileURL && catalogURL.isFileURL
    }

    private func folder(_ id: String) -> URL { directory.appendingPathComponent(id, isDirectory: true) }

    public func installedManifests() -> [CommunityPluginManifest] {
        guard let entries = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return [] }
        return entries.compactMap { dir in
            guard let data = try? Data(contentsOf: dir.appendingPathComponent("manifest.json")),
                  let manifest = try? JSONDecoder().decode(CommunityPluginManifest.self, from: data),
                  Self.isValid(manifest) == nil, manifest.id == dir.lastPathComponent,
                  fm.fileExists(atPath: dir.appendingPathComponent("main.js").path) else { return nil }
            return manifest
        }
    }

    public func script(for id: String) -> String? {
        try? String(contentsOf: folder(id).appendingPathComponent("main.js"), encoding: .utf8)
    }

    public func fetchCatalog(from url: URL) async throws -> [CommunityPluginManifest] {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw PluginStoreError.downloadFailed("HTTP \(http.statusCode)")
        }
        let catalog = try JSONDecoder().decode(CommunityPluginCatalog.self, from: data)
        return catalog.plugins.filter { Self.isValid($0) == nil }
    }

    /// Downloads `main.js`, verifies its SHA-256 and only then moves it into place.
    public func install(_ manifest: CommunityPluginManifest, catalogURL: URL) async throws {
        if let why = Self.isValid(manifest) { throw PluginStoreError.invalidManifest(why) }
        guard let expected = manifest.sha256?.lowercased(), !expected.isEmpty else { throw PluginStoreError.missingChecksum }
        guard let urlString = manifest.downloadURL, let url = URL(string: urlString) else {
            throw PluginStoreError.invalidManifest("missing downloadURL")
        }
        guard Self.isTrusted(url, catalogURL: catalogURL) else { throw PluginStoreError.untrustedSource(url) }

        let data: Data
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            let (body, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw PluginStoreError.downloadFailed("HTTP \(http.statusCode)")
            }
            data = body
        } catch let error as PluginStoreError {
            throw error
        } catch {
            throw PluginStoreError.downloadFailed(error.localizedDescription)
        }

        guard data.count <= Self.maxScriptBytes else { throw PluginStoreError.tooLarge }
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard digest == expected else { throw PluginStoreError.checksumMismatch }

        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        let staging = directory.appendingPathComponent(".\(manifest.id).partial", isDirectory: true)
        try? fm.removeItem(at: staging)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        try data.write(to: staging.appendingPathComponent("main.js"))
        try JSONEncoder().encode(manifest).write(to: staging.appendingPathComponent("manifest.json"))

        let target = folder(manifest.id)
        try? fm.removeItem(at: target)
        try fm.moveItem(at: staging, to: target)
    }

    public func uninstall(_ id: String) throws {
        let target = folder(id)
        guard fm.fileExists(atPath: target.path) else { throw PluginStoreError.notFound }
        try fm.removeItem(at: target)
    }
}

// MARK: - Sandboxed script runner
public enum PluginRunError: LocalizedError {
    case timedOut
    case missingCommand(String)
    case script(String)
    case badResult

    public var errorDescription: String? {
        switch self {
        case .timedOut: return "The plugin took longer than 5 seconds and was stopped."
        case .missingCommand(let id): return "The plugin does not define the command '\(id)'."
        case .script(let message): return "The plugin reported an error: \(message)"
        case .badResult: return "The plugin did not return text."
        }
    }
}

public enum JSPluginRunner {
    private final class ResultBox {
        private let lock = NSLock()
        private var value: Result<String, PluginRunError> = .failure(.timedOut)
        func set(_ v: Result<String, PluginRunError>) { lock.lock(); value = v; lock.unlock() }
        func get() -> Result<String, PluginRunError> { lock.lock(); defer { lock.unlock() }; return value }
    }

    /// Runs `commands[command](input, context)` in a fresh JavaScriptCore context. Blocks the caller for at most `timeout` seconds,
    /// so call it off the main thread.
    public static func run(script: String, command: String, input: String, context info: [String: String] = [:], timeout: TimeInterval = 5) -> Result<String, PluginRunError> {
        let box = ResultBox()
        let done = DispatchSemaphore(value: 0)

        DispatchQueue.global(qos: .userInitiated).async {
            defer { done.signal() }
            guard let context = JSContext() else { box.set(.failure(.script("JavaScript is unavailable"))); return }
            var thrown: String?
            context.exceptionHandler = { _, exception in thrown = exception?.toString() }
            context.evaluateScript("var commands = {}; var console = { log: function () {}, warn: function () {}, error: function () {} };")
            context.evaluateScript(script)
            if let thrown = thrown { box.set(.failure(.script(thrown))); return }

            guard let fn = context.objectForKeyedSubscript("commands")?.objectForKeyedSubscript(command),
                  fn.isObject, context.evaluateScript("typeof commands['\(command)'] === 'function'")?.toBool() == true else {
                box.set(.failure(.missingCommand(command)))
                return
            }
            let result = fn.call(withArguments: [input, info])
            if let thrown = thrown { box.set(.failure(.script(thrown))); return }
            if let result = result, result.isString, let text = result.toString() {
                box.set(.success(text))
            } else {
                box.set(.failure(.badResult))
            }
        }

        if done.wait(timeout: .now() + timeout) == .timedOut { return .failure(.timedOut) }
        return box.get()
    }
}
