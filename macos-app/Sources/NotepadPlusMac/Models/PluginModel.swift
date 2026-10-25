import Foundation
import SwiftUI
import AppKit

// MARK: - Plugin Category
public enum PluginCategory: String, CaseIterable, Codable, Identifiable {
    case all = "All"
    case formatters = "Formatters"
    case viewers = "Viewers"
    case utilities = "Utilities"

    public var id: String { rawValue }
    public var iconName: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .formatters: return "wand.and.stars"
        case .viewers: return "eye.fill"
        case .utilities: return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Plugin Manager Tab (Macro-free)
public enum PluginManagerTab: String, CaseIterable, Identifiable {
    case installed = "Installed"
    case available = "Available"
    case updates = "Updates"
    case disabled = "Disabled"

    public var id: String { rawValue }
    public var iconName: String {
        switch self {
        case .installed: return "checkmark.seal.fill"
        case .available: return "arrow.down.circle"
        case .updates: return "arrow.triangle.2.circlepath"
        case .disabled: return "slash.circle"
        }
    }
}

// MARK: - Plugin Model
public struct PluginInfo: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let icon: String
    public let category: PluginCategory
    public let version: String
    public let availableVersion: String?
    public let author: String
    public let summary: String
    public let documentation: String
    public var isInstalled: Bool
    public var isEnabled: Bool

    public init(
        id: String,
        name: String,
        icon: String,
        category: PluginCategory,
        version: String,
        availableVersion: String? = nil,
        author: String = "NPad++ Team",
        summary: String,
        documentation: String,
        isInstalled: Bool = true,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.category = category
        self.version = version
        self.availableVersion = availableVersion
        self.author = author
        self.summary = summary
        self.documentation = documentation
        self.isInstalled = isInstalled
        self.isEnabled = isEnabled
    }
}

// MARK: - Plugin Manager Model & Controller
public final class PluginRegistry: ObservableObject {
    public static let shared = PluginRegistry()

    private let kEnabledPlugins = "npad.plugins.enabled"
    private let kInstalledPlugins = "npad.plugins.installed"

    @Published public var plugins: [PluginInfo] = []

    // Plugin Manager UI State (Macro-free)
    @Published public var selectedTab: PluginManagerTab = .installed
    @Published public var selectedCategory: PluginCategory = .all
    @Published public var searchText: String = ""
    @Published public var selectedPlugin: PluginInfo? = nil

    public init() {
        loadDefaultPlugins()
    }

    private func loadDefaultPlugins() {
        let savedEnabled = UserDefaults.standard.stringArray(forKey: kEnabledPlugins) ?? [
            "json_tools", "xml_tools", "markdown_preview",
            "color_preview", "code_snippets", "base64_tools",
            "text_sort", "file_compare"
        ]
        let enabledSet = Set(savedEnabled)

        let savedInstalled = UserDefaults.standard.stringArray(forKey: kInstalledPlugins) ?? [
            "json_tools", "xml_tools", "markdown_preview",
            "color_preview", "code_snippets", "base64_tools",
            "text_sort", "file_compare"
        ]
        let installedSet = Set(savedInstalled)

        self.plugins = [
            PluginInfo(
                id: "json_tools",
                name: "JSON Formatter & Validator",
                icon: "curlybraces.square.fill",
                category: .formatters,
                version: "1.2.0",
                summary: "Prettify, minify, and validate JSON payloads with syntax error reporting.",
                documentation: "Formats unformatted JSON documents with standard 2-space or 4-space indentation. Automatically reports line and column errors on invalid JSON syntax.",
                isInstalled: installedSet.contains("json_tools"),
                isEnabled: enabledSet.contains("json_tools")
            ),
            PluginInfo(
                id: "xml_tools",
                name: "XML Prettifier & Tools",
                icon: "chevron.left.forwardslash.chevron.right",
                category: .formatters,
                version: "1.1.0",
                summary: "Format and clean XML trees with proper indentation and tag validation.",
                documentation: "Parses and indents XML/HTML tags with hierarchical structure visualization. Cleans trailing spaces and preserves attribute order.",
                isInstalled: installedSet.contains("xml_tools"),
                isEnabled: enabledSet.contains("xml_tools")
            ),
            PluginInfo(
                id: "markdown_preview",
                name: "Markdown Live Viewer",
                icon: "doc.richtext",
                category: .viewers,
                version: "1.3.0",
                availableVersion: "1.3.2",
                summary: "Render formatted Markdown documents with headings, lists, code blocks, and tables.",
                documentation: "Provides an interactive live preview of Markdown files side-by-side or in a dedicated sheet.",
                isInstalled: installedSet.contains("markdown_preview"),
                isEnabled: enabledSet.contains("markdown_preview")
            ),
            PluginInfo(
                id: "color_preview",
                name: "Color Preview & Hex Converter",
                icon: "paintpalette.fill",
                category: .utilities,
                version: "1.0.2",
                summary: "Detects hex colors (#RRGGBB) and RGB strings and displays inline visual swatches.",
                documentation: "Assists CSS, web, and UI designers by parsing color strings and offering fast color selection and format conversion.",
                isInstalled: installedSet.contains("color_preview"),
                isEnabled: enabledSet.contains("color_preview")
            ),
            PluginInfo(
                id: "code_snippets",
                name: "Code Snippets & Boilerplates",
                icon: "text.badge.plus",
                category: .utilities,
                version: "1.1.0",
                summary: "Insert pre-configured template snippets for Java, Swift, Python, HTML5, and React.",
                documentation: "Accelerates development by inserting standard project headers, classes, main methods, and loops directly at the cursor.",
                isInstalled: installedSet.contains("code_snippets"),
                isEnabled: enabledSet.contains("code_snippets")
            ),
            PluginInfo(
                id: "base64_tools",
                name: "Base64 Encoder & Decoder",
                icon: "lock.shield",
                category: .utilities,
                version: "1.0.0",
                summary: "Encode and decode text, tokens, and payloads directly in the editor.",
                documentation: "Standard RFC 4648 Base64 encoding and decoding for selected strings or entire documents with UTF-8 character preservation.",
                isInstalled: installedSet.contains("base64_tools"),
                isEnabled: enabledSet.contains("base64_tools")
            ),
            PluginInfo(
                id: "text_sort",
                name: "Line Sorter & Deduplicator",
                icon: "arrow.up.arrow.down",
                category: .utilities,
                version: "1.0.1",
                summary: "Sort lines alphabetically, reverse sort, and remove duplicate lines.",
                documentation: "Clean and reorganize imports, lists, logs, and datasets with case-sensitive or case-insensitive alphabetical sorting.",
                isInstalled: installedSet.contains("text_sort"),
                isEnabled: enabledSet.contains("text_sort")
            ),
            PluginInfo(
                id: "file_compare",
                name: "Notepad++ Compare Engine",
                icon: "square.split.2x1",
                category: .utilities,
                version: "2.1.0",
                summary: "Eugene Myers diff comparison engine with side-by-side highlighting.",
                documentation: "Full side-by-side file comparison with intra-line character range diffs, green additions, red deletions, and amber modifications.",
                isInstalled: installedSet.contains("file_compare"),
                isEnabled: enabledSet.contains("file_compare")
            )
        ]
    }

    public func isPluginEnabled(_ id: String) -> Bool {
        plugins.first(where: { $0.id == id })?.isEnabled ?? false
    }

    public func togglePlugin(_ id: String) {
        if let idx = plugins.firstIndex(where: { $0.id == id }) {
            plugins[idx].isEnabled.toggle()
            saveState()
        }
    }

    public func installPlugin(_ id: String) {
        if let idx = plugins.firstIndex(where: { $0.id == id }) {
            plugins[idx].isInstalled = true
            plugins[idx].isEnabled = true
            saveState()
        }
    }

    public func uninstallPlugin(_ id: String) {
        if let idx = plugins.firstIndex(where: { $0.id == id }) {
            plugins[idx].isInstalled = false
            plugins[idx].isEnabled = false
            saveState()
        }
    }

    public func updatePlugin(_ id: String) {
        if plugins.contains(where: { $0.id == id }) {
            saveState()
        }
    }

    private func saveState() {
        let enabled = plugins.filter { $0.isEnabled }.map { $0.id }
        let installed = plugins.filter { $0.isInstalled }.map { $0.id }
        UserDefaults.standard.set(enabled, forKey: kEnabledPlugins)
        UserDefaults.standard.set(installed, forKey: kInstalledPlugins)
    }

    // MARK: - Practical Plugin Actions
    public static func formatJSON(content: String) -> (result: String?, error: String?) {
        guard let data = content.data(using: .utf8) else {
            return (nil, "Unable to read content as UTF-8.")
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            if let prettyString = String(data: prettyData, encoding: .utf8) {
                return (prettyString, nil)
            }
            return (nil, "Failed to encode formatted JSON.")
        } catch {
            return (nil, error.localizedDescription)
        }
    }

    public static func minifyJSON(content: String) -> (result: String?, error: String?) {
        guard let data = content.data(using: .utf8) else {
            return (nil, "Unable to read content as UTF-8.")
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let minData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            if let minString = String(data: minData, encoding: .utf8) {
                return (minString, nil)
            }
            return (nil, "Failed to encode minified JSON.")
        } catch {
            return (nil, error.localizedDescription)
        }
    }

    public static func formatXML(content: String) -> String {
        var indent = 0
        var resultLines: [String] = []
        let rawTokens = content.replacingOccurrences(of: "><", with: ">\n<").components(separatedBy: "\n")

        for token in rawTokens {
            let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            if trimmed.hasPrefix("</") {
                indent = max(0, indent - 1)
            }

            let spaces = String(repeating: "    ", count: indent)
            resultLines.append("\(spaces)\(trimmed)")

            if trimmed.hasPrefix("<") && !trimmed.hasPrefix("</") && !trimmed.hasSuffix("/>") && !trimmed.contains("</") && !trimmed.hasPrefix("<?") && !trimmed.hasPrefix("<!") {
                indent += 1
            }
        }
        return resultLines.joined(separator: "\n")
    }

    public static func extractTodos(content: String) -> [(line: Int, tag: String, text: String)] {
        var results: [(line: Int, tag: String, text: String)] = []
        let lines = content.components(separatedBy: "\n")
        let tags = ["TODO", "FIXME", "NOTE", "BUG", "HACK"]

        for (idx, line) in lines.enumerated() {
            for tag in tags {
                if let range = line.range(of: tag + ":", options: .caseInsensitive) {
                    let desc = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                    results.append((line: idx + 1, tag: tag, text: desc.isEmpty ? line : desc))
                    break
                }
            }
        }
        return results
    }

    public static func detectGitBranch(at path: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["rev-parse", "--abbrev-ref", "HEAD"]
        process.currentDirectoryURL = URL(fileURLWithPath: path)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let branch = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                return branch?.isEmpty == false ? branch : nil
            }
        } catch {}
        return nil
    }

    // MARK: - Direct Action Dispatchers for Menu / UI
    public func jsonPrettify(appState: AppStateManager) {
        guard let doc = appState.activeDocument else { return }
        let (res, err) = PluginRegistry.formatJSON(content: doc.content)
        if let res = res {
            doc.content = res
            doc.isModified = true
        } else if let err = err {
            let alert = NSAlert()
            alert.messageText = "JSON Formatting Error"
            alert.informativeText = err
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    public func jsonMinify(appState: AppStateManager) {
        guard let doc = appState.activeDocument else { return }
        let (res, err) = PluginRegistry.minifyJSON(content: doc.content)
        if let res = res {
            doc.content = res
            doc.isModified = true
        } else if let err = err {
            let alert = NSAlert()
            alert.messageText = "JSON Minify Error"
            alert.informativeText = err
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    public func jsonValidate(appState: AppStateManager) {
        guard let doc = appState.activeDocument else { return }
        let (res, err) = PluginRegistry.formatJSON(content: doc.content)
        let alert = NSAlert()
        if res != nil {
            alert.messageText = "Valid JSON"
            alert.informativeText = "The document contains well-formed and valid JSON syntax."
            alert.alertStyle = .informational
        } else {
            alert.messageText = "Invalid JSON"
            alert.informativeText = err ?? "Syntax error detected in JSON document."
            alert.alertStyle = .warning
        }
        alert.runModal()
    }

    public func xmlFormat(appState: AppStateManager) {
        guard let doc = appState.activeDocument else { return }
        let formatted = PluginRegistry.formatXML(content: doc.content)
        doc.content = formatted
        doc.isModified = true
    }

    public func sortLinesAscending(appState: AppStateManager) {
        guard let doc = appState.activeDocument else { return }
        let lines = doc.content.components(separatedBy: "\n").sorted()
        doc.content = lines.joined(separator: "\n")
        doc.isModified = true
    }

    public func sortLinesDescending(appState: AppStateManager) {
        guard let doc = appState.activeDocument else { return }
        let lines = doc.content.components(separatedBy: "\n").sorted(by: >)
        doc.content = lines.joined(separator: "\n")
        doc.isModified = true
    }

    public func removeDuplicateLines(appState: AppStateManager) {
        guard let doc = appState.activeDocument else { return }
        let lines = doc.content.components(separatedBy: "\n")
        var seen = Set<String>()
        var deduped: [String] = []
        for line in lines {
            if !seen.contains(line) {
                seen.insert(line)
                deduped.append(line)
            }
        }
        doc.content = deduped.joined(separator: "\n")
        doc.isModified = true
    }

    public func base64Encode(appState: AppStateManager) {
        appState.base64EncodeSelectionOrDocument()
    }

    public func base64Decode(appState: AppStateManager) {
        appState.base64DecodeSelectionOrDocument()
    }

    public func findTodos(appState: AppStateManager) {
        guard let doc = appState.activeDocument else { return }
        let todos = PluginRegistry.extractTodos(content: doc.content)
        if todos.isEmpty {
            let alert = NSAlert()
            alert.messageText = "TODO / Task Tracker"
            alert.informativeText = "No TODO, FIXME, NOTE, or BUG comments found in '\(doc.title)'."
            alert.alertStyle = .informational
            alert.runModal()
        } else {
            appState.searchResultsList = todos.map { todo in
                SearchResultItem(
                    fileTitle: doc.title,
                    fileURL: doc.fileURL,
                    lineNumber: todo.line,
                    lineContent: "[\(todo.tag)] \(todo.text)",
                    matchRange: NSRange(location: 0, length: 0)
                )
            }
            appState.activeBottomTab = "Search Results"
            appState.isBottomPanelVisible = true
        }
    }

    public func checkGitStatus(appState: AppStateManager) {
        let path = appState.workspaceRootURL?.path ?? (appState.activeDocument?.fileURL?.deletingLastPathComponent().path ?? "")
        guard !path.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "Git Integration"
            alert.informativeText = "Please open a folder or file to inspect Git status."
            alert.alertStyle = .informational
            alert.runModal()
            return
        }

        if let branch = PluginRegistry.detectGitBranch(at: path) {
            appState.terminalWorkingDirectory = path
            appState.terminalOutput.append("[Git Branch: \(branch)]")
            appState.terminalCommand = "git status"
            appState.executeTerminalCommand()
            appState.activeBottomTab = "Terminal"
            appState.isBottomPanelVisible = true
        } else {
            let alert = NSAlert()
            alert.messageText = "Git Integration"
            alert.informativeText = "No Git repository detected at '\(path)'."
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
}
