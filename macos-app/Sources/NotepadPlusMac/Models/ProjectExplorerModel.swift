import Foundation
import SwiftUI
import AppKit

// MARK: - Project Explorer Node Item
public class ProjectItem: Identifiable, ObservableObject, Equatable {
    public let id: UUID
    public let name: String
    public let url: URL
    public let isDirectory: Bool
    public let fileExtension: String
    @Published public var isExpanded: Bool
    @Published public var children: [ProjectItem]?

    public init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        isDirectory: Bool,
        isExpanded: Bool = false,
        children: [ProjectItem]? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.fileExtension = url.pathExtension.lowercased()
        self.isExpanded = isExpanded
        self.children = children
    }

    public static func == (lhs: ProjectItem, rhs: ProjectItem) -> Bool {
        lhs.id == rhs.id && lhs.url == rhs.url && lhs.isExpanded == rhs.isExpanded
    }

    public var systemIcon: String {
        if isDirectory {
            return isExpanded ? "folder.fill" : "folder"
        }
        switch fileExtension {
        case "java", "gradle": return "cup.and.saucer.fill"
        case "swift": return "swift"
        case "py": return "chevron.left.forwardslash.chevron.right"
        case "js", "ts", "jsx", "tsx": return "curlybraces"
        case "json", "xml", "yaml", "yml": return "curlybraces.square.fill"
        case "html", "htm": return "chevron.left.forwardslash.chevron.right"
        case "css", "scss", "less": return "paintbrush.fill"
        case "sh", "bash", "zsh": return "terminal.fill"
        case "sql": return "cylinder.split.1x2.fill"
        case "md", "markdown", "txt": return "text.quote"
        case "c", "cpp", "h", "hpp", "rs", "go": return "hammer.fill"
        case "png", "jpg", "jpeg", "gif", "svg": return "photo.fill"
        case "pdf": return "doc.richtext"
        case "zip", "tar", "gz": return "archivebox.fill"
        default: return "doc.text"
        }
    }

    public var iconColor: Color {
        if isDirectory {
            return .accentColor
        }
        switch fileExtension {
        case "java": return Color(red: 0.85, green: 0.45, blue: 0.15)
        case "swift": return Color(red: 0.95, green: 0.35, blue: 0.15)
        case "py", "python": return .blue
        case "js", "jsx": return .yellow
        case "ts", "tsx": return .blue
        case "json", "xml", "html": return .purple
        case "css": return .pink
        case "sh", "bash", "zsh": return .green
        case "sql": return .teal
        case "c", "cpp", "rs": return .red
        case "md", "txt": return .secondary
        default: return .secondary
        }
    }
}

// MARK: - Project Explorer Service (Safe Hierarchical Tree Scanner)
public enum ProjectExplorerService {

    /// Ignored directory names to maintain responsiveness and avoid bloat
    public static let ignoredDirectories: Set<String> = [
        ".git", ".svn", ".hg", "node_modules", ".build", ".gradle", "build", "target", ".idea", ".vscode"
    ]

    /// Builds a full recursive tree from the given folder URL
    public static func buildTree(for rootURL: URL, maxDepth: Int = 10) -> ProjectItem? {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: rootURL.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }

        var visitedPaths = Set<String>()
        return scanDirectory(url: rootURL, currentDepth: 0, maxDepth: maxDepth, visited: &visitedPaths, isRoot: true)
    }

    private static func scanDirectory(
        url: URL,
        currentDepth: Int,
        maxDepth: Int,
        visited: inout Set<String>,
        isRoot: Bool = false
    ) -> ProjectItem? {
        // Resolve canonical path to prevent infinite loops from symlinks
        let canonicalPath = (try? url.resourceValues(forKeys: [.canonicalPathKey]))?.canonicalPath ?? url.resolvingSymlinksInPath().path
        if visited.contains(canonicalPath) {
            return nil
        }
        visited.insert(canonicalPath)

        let fileManager = FileManager.default
        let dirName = isRoot ? url.lastPathComponent : url.lastPathComponent
        guard !dirName.isEmpty else { return nil }

        let item = ProjectItem(
            name: dirName,
            url: url,
            isDirectory: true,
            isExpanded: isRoot // Expand root by default
        )

        if currentDepth >= maxDepth {
            item.children = []
            return item
        }

        do {
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .isHiddenKey, .nameKey]
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsPackageDescendants]
            )

            var childFolders: [ProjectItem] = []
            var childFiles: [ProjectItem] = []

            for childURL in contents {
                let name = childURL.lastPathComponent
                // Skip hidden files unless needed, and skip ignored heavy directories
                if name.hasPrefix(".") && name != ".env" { continue }
                if ignoredDirectories.contains(name) { continue }

                var isChildDir: ObjCBool = false
                if fileManager.fileExists(atPath: childURL.path, isDirectory: &isChildDir) {
                    if isChildDir.boolValue {
                        if let folderNode = scanDirectory(
                            url: childURL,
                            currentDepth: currentDepth + 1,
                            maxDepth: maxDepth,
                            visited: &visited
                        ) {
                            childFolders.append(folderNode)
                        }
                    } else {
                        let fileNode = ProjectItem(
                            name: name,
                            url: childURL,
                            isDirectory: false
                        )
                        childFiles.append(fileNode)
                    }
                }
            }

            // Sort directories alphabetically, then files alphabetically
            childFolders.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            childFiles.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

            item.children = childFolders + childFiles
            return item
        } catch {
            item.children = []
            return item
        }
    }

    // MARK: - Safe File & Folder Operations
    public static func createFile(in parentFolderURL: URL, name: String) throws -> URL {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            throw NSError(domain: "NPad", code: 1001, userInfo: [NSLocalizedDescriptionKey: "File name cannot be empty."])
        }
        let targetURL = parentFolderURL.appendingPathComponent(cleanName)
        if FileManager.default.fileExists(atPath: targetURL.path) {
            throw NSError(domain: "NPad", code: 1002, userInfo: [NSLocalizedDescriptionKey: "A file with this name already exists."])
        }
        try "".write(to: targetURL, atomically: true, encoding: .utf8)
        return targetURL
    }

    public static func createFolder(in parentFolderURL: URL, name: String) throws -> URL {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            throw NSError(domain: "NPad", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Folder name cannot be empty."])
        }
        let targetURL = parentFolderURL.appendingPathComponent(cleanName)
        if FileManager.default.fileExists(atPath: targetURL.path) {
            throw NSError(domain: "NPad", code: 1004, userInfo: [NSLocalizedDescriptionKey: "A folder with this name already exists."])
        }
        try FileManager.default.createDirectory(at: targetURL, withIntermediateDirectories: false)
        return targetURL
    }

    public static func rename(at itemURL: URL, newName: String) throws -> URL {
        let cleanName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            throw NSError(domain: "NPad", code: 1005, userInfo: [NSLocalizedDescriptionKey: "Name cannot be empty."])
        }
        let targetURL = itemURL.deletingLastPathComponent().appendingPathComponent(cleanName)
        if FileManager.default.fileExists(atPath: targetURL.path) && targetURL.path != itemURL.path {
            throw NSError(domain: "NPad", code: 1006, userInfo: [NSLocalizedDescriptionKey: "An item with this name already exists."])
        }
        try FileManager.default.moveItem(at: itemURL, to: targetURL)
        return targetURL
    }

    public static func delete(at itemURL: URL) throws {
        try FileManager.default.removeItem(at: itemURL)
    }

    public static func revealInFinder(at itemURL: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([itemURL])
    }
}
