import Foundation
import Combine
import AppKit
import SwiftUI

public enum LineEndingFormat: String, CaseIterable, Identifiable, Codable {
    case lf = "macOS / Unix (LF)"
    case crlf = "Windows (CRLF)"
    case cr = "Classic Mac (CR)"

    public var id: String { rawValue }
    public var newlineSequence: String {
        switch self {
        case .lf: return "\n"
        case .crlf: return "\r\n"
        case .cr: return "\r"
        }
    }
}

public enum DocumentEncoding: String, CaseIterable, Identifiable, Codable {
    case utf8 = "UTF-8"
    case utf8BOM = "UTF-8 with BOM"
    case utf16LE = "UTF-16 LE"
    case utf16BE = "UTF-16 BE"
    case ascii = "US-ASCII"

    public var id: String { rawValue }
}

extension String {
    public static let plainText = "Plain Text"
    public static let java = "Java"
    public static let python = "Python"
    public static let swift = "Swift"
    public static let markdown = "Markdown"
    public static let javascript = "JavaScript"
    public static let typescript = "TypeScript"
    public static let c = "C"
    public static let cpp = "C++"
    public static let html = "HTML"
    public static let css = "CSS"
    public static let json = "JSON"
    public static let xml = "XML"
    public static let sql = "SQL"
    public static let shell = "Shell"
}

public struct TextMark: Identifiable, Codable, Equatable {
    public var id: UUID
    public var location: Int
    public var length: Int
    public var colorName: String // "Yellow", "Green", "Cyan", "Pink", "Orange"

    public var range: NSRange {
        get { NSRange(location: location, length: length) }
        set {
            location = newValue.location
            length = newValue.length
        }
    }

    public init(id: UUID = UUID(), range: NSRange, colorName: String = "Yellow") {
        self.id = id
        self.location = range.location
        self.length = range.length
        self.colorName = colorName
    }
}

public struct DocumentEditSnapshot: Equatable {
    public let content: String
    public let selectedRange: NSRange
    public let cursorLine: Int
    public let cursorColumn: Int
    public let actionName: String

    public init(
        content: String,
        selectedRange: NSRange,
        cursorLine: Int,
        cursorColumn: Int,
        actionName: String = "Edit"
    ) {
        self.content = content
        self.selectedRange = selectedRange
        self.cursorLine = cursorLine
        self.cursorColumn = cursorColumn
        self.actionName = actionName
    }
}

public enum TabCloseDecision: Equatable {
    case save
    case dontSave
    case cancel
}

public struct PersistedDocumentSnapshot: Codable, Equatable {
    public var id: UUID
    public var title: String
    public var filePath: String?
    public var recoverableContent: String
    public var savedContent: String
    public var isModified: Bool
    public var hasEverBeenSaved: Bool
    public var isOriginalFileMissing: Bool
    public var encodingRawValue: String
    public var lineEndingRawValue: String
    public var language: String
    public var bookmarks: [Int]
    public var marks: [TextMark]
    public var cursorLine: Int
    public var cursorColumn: Int
    public var selectedLocation: Int
    public var selectedLength: Int
    public var scrollOriginX: Double
    public var scrollOriginY: Double
    public var updatedAt: TimeInterval
}

public struct PersistedWorkspaceSession: Codable, Equatable {
    public var version: Int
    public var activeDocumentId: UUID?
    public var tabOrder: [UUID]
    public var documents: [PersistedDocumentSnapshot]
    public var terminalWorkingDirectory: String?
    public var workspaceRootURLString: String?
    public var updatedAt: TimeInterval
    public var leftTabOrder: [UUID]?
    public var rightTabOrder: [UUID]?
    public var isSplitViewActive: Bool?
    public var splitRatio: Double?
    public var activePane: String?

    public init(
        version: Int = 2,
        activeDocumentId: UUID? = nil,
        tabOrder: [UUID] = [],
        documents: [PersistedDocumentSnapshot] = [],
        terminalWorkingDirectory: String? = nil,
        workspaceRootURLString: String? = nil,
        updatedAt: TimeInterval = Date().timeIntervalSince1970,
        leftTabOrder: [UUID]? = nil,
        rightTabOrder: [UUID]? = nil,
        isSplitViewActive: Bool? = nil,
        splitRatio: Double? = nil,
        activePane: String? = nil
    ) {
        self.version = version
        self.activeDocumentId = activeDocumentId
        self.tabOrder = tabOrder
        self.documents = documents
        self.terminalWorkingDirectory = terminalWorkingDirectory
        self.workspaceRootURLString = workspaceRootURLString
        self.updatedAt = updatedAt
        self.leftTabOrder = leftTabOrder
        self.rightTabOrder = rightTabOrder
        self.isSplitViewActive = isSplitViewActive
        self.splitRatio = splitRatio
        self.activePane = activePane
    }
}

public class EditorDocument: ObservableObject, Identifiable {
    public let id: UUID
    @Published public var title: String
    @Published public var fileURL: URL?
    @Published public var content: String
    @Published public var savedContent: String
    @Published public var isModified: Bool = false
    @Published public var hasEverBeenSaved: Bool = false
    @Published public var isOriginalFileMissing: Bool = false
    @Published public var externalConflictContent: String? = nil
    @Published public var encoding: DocumentEncoding = .utf8
    @Published public var lineEnding: LineEndingFormat = .lf
    @Published public var language: String = "Plain Text"
    @Published public var bookmarks: Set<Int> = [] // 1-indexed line numbers
    @Published public var marks: [TextMark] = []   // Persistent in-memory text marks
    @Published public var cursorLine: Int = 1
    @Published public var cursorColumn: Int = 1
    @Published public var selectionLength: Int = 0
    @Published public var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @Published public var scrollOrigin: NSPoint = .zero

    public let undoManager: UndoManager = UndoManager()
    private var undoStack: [DocumentEditSnapshot] = []
    private var redoStack: [DocumentEditSnapshot] = []
    private var undoObserverCancellables = Set<AnyCancellable>()

    @Published public private(set) var canUndo: Bool = false
    @Published public private(set) var canRedo: Bool = false

    public var onContentDidChange: (() -> Void)? = nil

    public func updateUndoRedoState() {
        let newCanUndo = !undoStack.isEmpty
        let newCanRedo = !redoStack.isEmpty
        if canUndo != newCanUndo {
            canUndo = newCanUndo
        }
        if canRedo != newCanRedo {
            canRedo = newCanRedo
        }
    }

    private func setupUndoManagerObservers() {
        undoObserverCancellables.removeAll()
        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            .NSUndoManagerCheckpoint,
            .NSUndoManagerDidUndoChange,
            .NSUndoManagerDidRedoChange,
            .NSUndoManagerWillCloseUndoGroup
        ]
        for name in names {
            center.publisher(for: name, object: undoManager)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.updateUndoRedoState()
                }
                .store(in: &undoObserverCancellables)
        }
    }

    public var name: String {
        get { title }
        set { title = newValue }
    }

    public init(
        id: UUID = UUID(),
        title: String = "new 1",
        fileURL: URL? = nil,
        content: String = "",
        savedContent: String? = nil,
        language: String = "Plain Text",
        hasEverBeenSaved: Bool? = nil,
        isModified: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.content = content
        let baseline = savedContent ?? content
        self.savedContent = baseline
        self.language = language
        self.hasEverBeenSaved = hasEverBeenSaved ?? (fileURL != nil)
        self.isModified = isModified ?? (content != baseline)
        self.undoManager.groupsByEvent = true
        setupUndoManagerObservers()
        updateUndoRedoState()
    }

    public convenience init(
        name: String,
        content: String = "",
        savedContent: String? = nil,
        language: String = "Plain Text",
        fileURL: URL? = nil,
        isModified: Bool? = nil,
        hasEverBeenSaved: Bool? = nil
    ) {
        self.init(
            id: UUID(),
            title: name,
            fileURL: fileURL,
            content: content,
            savedContent: savedContent,
            language: language,
            hasEverBeenSaved: hasEverBeenSaved,
            isModified: isModified
        )
    }

    public convenience init(
        name: String,
        content: String,
        savedContent: String?,
        language: String,
        isModified: Bool,
        hasEverBeenSaved: Bool? = nil
    ) {
        self.init(
            id: UUID(),
            title: name,
            fileURL: nil,
            content: content,
            savedContent: savedContent,
            language: language,
            hasEverBeenSaved: hasEverBeenSaved,
            isModified: isModified
        )
    }

    public convenience init(
        name: String,
        content: String,
        savedContent: String?,
        language: String,
        fileURL: URL?,
        isModified: Bool,
        hasEverBeenSaved: Bool? = nil
    ) {
        self.init(
            id: UUID(),
            title: name,
            fileURL: fileURL,
            content: content,
            savedContent: savedContent,
            language: language,
            hasEverBeenSaved: hasEverBeenSaved,
            isModified: isModified
        )
    }

    /// Applies an edit and records it on this document's isolated undo stack.
    public func applyEdit(
        _ newContent: String,
        newSelectedRange: NSRange? = nil,
        actionName: String = "Typing"
    ) {
        guard newContent != content else { return }
        #if DEBUG
        NSLog("[NPad++ Diagnostic] applyEdit: action=%@, doc=%@, prevLen=%d, newLen=%d", actionName, title, content.count, newContent.count)
        #endif

        let prevSnapshot = DocumentEditSnapshot(
            content: content,
            selectedRange: selectedRange,
            cursorLine: cursorLine,
            cursorColumn: cursorColumn,
            actionName: actionName
        )
        undoStack.append(prevSnapshot)
        if undoStack.count > 250 {
            undoStack.removeFirst()
        }
        redoStack.removeAll()

        content = newContent
        if let range = newSelectedRange {
            selectedRange = range
            selectionLength = range.length
            updateCursorFromRange(range)
        } else {
            var targetLoc = selectedRange.location
            if targetLoc == 0 && cursorLine > 1 {
                targetLoc = characterIndex(forLine: cursorLine, column: cursorColumn, in: newContent)
            }
            let safeLoc = min(targetLoc, (newContent as NSString).length)
            let range = NSRange(location: safeLoc, length: 0)
            selectedRange = range
            selectionLength = 0
            updateCursorFromRange(range)
        }

        recalculateModifiedState()
        updateUndoRedoState()
        onContentDidChange?()
    }

    @discardableResult
    public func undo() -> Bool {
        guard let targetSnapshot = undoStack.popLast() else {
            updateUndoRedoState()
            return false
        }

        let currentSnapshot = DocumentEditSnapshot(
            content: content,
            selectedRange: selectedRange,
            cursorLine: cursorLine,
            cursorColumn: cursorColumn,
            actionName: targetSnapshot.actionName
        )
        redoStack.append(currentSnapshot)

        content = targetSnapshot.content
        selectedRange = targetSnapshot.selectedRange
        selectionLength = targetSnapshot.selectedRange.length
        cursorLine = targetSnapshot.cursorLine
        cursorColumn = targetSnapshot.cursorColumn
        recalculateModifiedState()
        updateUndoRedoState()
        onContentDidChange?()
        return true
    }

    @discardableResult
    public func redo() -> Bool {
        guard let targetSnapshot = redoStack.popLast() else {
            updateUndoRedoState()
            return false
        }

        let currentSnapshot = DocumentEditSnapshot(
            content: content,
            selectedRange: selectedRange,
            cursorLine: cursorLine,
            cursorColumn: cursorColumn,
            actionName: targetSnapshot.actionName
        )
        undoStack.append(currentSnapshot)

        content = targetSnapshot.content
        selectedRange = targetSnapshot.selectedRange
        selectionLength = targetSnapshot.selectedRange.length
        cursorLine = targetSnapshot.cursorLine
        cursorColumn = targetSnapshot.cursorColumn
        recalculateModifiedState()
        updateUndoRedoState()
        onContentDidChange?()
        return true
    }

    public func recalculateModifiedState() {
        isModified = isOriginalFileMissing || (content != savedContent)
    }

    public func markAsSaved(at url: URL? = nil) {
        if let newURL = url {
            self.fileURL = newURL
            self.title = newURL.lastPathComponent
        }
        self.savedContent = self.content
        self.hasEverBeenSaved = true
        self.isOriginalFileMissing = false
        self.externalConflictContent = nil
        self.isModified = false
        updateUndoRedoState()
    }

    public func save(to url: URL? = nil) throws {
        guard let targetURL = url ?? fileURL else {
            throw NSError(domain: "NPad", code: 404, userInfo: [NSLocalizedDescriptionKey: "No target URL for save"])
        }
        try content.write(to: targetURL, atomically: true, encoding: .utf8)
        markAsSaved(at: targetURL)
    }

    public func characterIndex(forLine line: Int, column: Int = 1, in text: String? = nil) -> Int {
        let targetText = text ?? content
        let lines = targetText.components(separatedBy: "\n")
        let targetLineIdx = max(0, min(line - 1, lines.count - 1))
        var loc = 0
        for i in 0..<targetLineIdx {
            loc += (lines[i] as NSString).length + 1
        }
        let colOffset = max(0, min(column - 1, (lines[targetLineIdx] as NSString).length))
        return loc + colOffset
    }

    private func updateCursorFromRange(_ range: NSRange) {
        let nsText = content as NSString
        let safeLoc = max(0, min(range.location, nsText.length))
        let prefix = nsText.substring(with: NSRange(location: 0, length: safeLoc))
        let lines = prefix.components(separatedBy: "\n")
        cursorLine = max(1, lines.count)
        cursorColumn = (lines.last?.count ?? 0) + 1
    }

    public func toggleMark(for range: NSRange, colorName: String = "Yellow") {
        guard range.length > 0 else { return }

        if let idx = marks.firstIndex(where: {
            NSIntersectionRange($0.range, range).length > 0
        }) {
            marks.remove(at: idx)
        } else {
            marks.append(TextMark(range: range, colorName: colorName))
        }
    }

    public func clearAllMarks() {
        marks.removeAll()
    }

    public func toggleBookmark(_ line: Int) {
        if bookmarks.contains(line) {
            bookmarks.remove(line)
        } else {
            bookmarks.insert(line)
        }
    }

    public func clearBookmarks() {
        bookmarks.removeAll()
    }

    public func toPersistedSnapshot() -> PersistedDocumentSnapshot {
        PersistedDocumentSnapshot(
            id: id,
            title: title,
            filePath: fileURL?.path,
            recoverableContent: content,
            savedContent: savedContent,
            isModified: isOriginalFileMissing || isModified || (content != savedContent),
            hasEverBeenSaved: hasEverBeenSaved,
            isOriginalFileMissing: isOriginalFileMissing,
            encodingRawValue: encoding.rawValue,
            lineEndingRawValue: lineEnding.rawValue,
            language: language,
            bookmarks: Array(bookmarks).sorted(),
            marks: marks,
            cursorLine: cursorLine,
            cursorColumn: cursorColumn,
            selectedLocation: selectedRange.location,
            selectedLength: selectedRange.length,
            scrollOriginX: Double(scrollOrigin.x),
            scrollOriginY: Double(scrollOrigin.y),
            updatedAt: Date().timeIntervalSince1970
        )
    }

    public static func fromPersistedSnapshot(_ snap: PersistedDocumentSnapshot) -> EditorDocument {
        var url: URL? = nil
        var missingOnDisk = snap.isOriginalFileMissing
        var baseline = snap.savedContent
        var conflictText: String? = nil
        var textToRestore = snap.recoverableContent

        if let path = snap.filePath, !path.isEmpty {
            url = URL(fileURLWithPath: path)
            if !FileManager.default.fileExists(atPath: path) {
                missingOnDisk = true
            } else if let diskData = try? Data(contentsOf: URL(fileURLWithPath: path)),
                      let diskStr = String(data: diskData, encoding: .utf8) {
                if diskStr != snap.savedContent {
                    if !snap.isModified && snap.recoverableContent == snap.savedContent {
                        baseline = diskStr
                        textToRestore = diskStr
                    } else {
                        conflictText = diskStr
                    }
                }
            }
        }

        let isDirty = missingOnDisk || snap.isModified || (textToRestore != baseline)
        let doc = EditorDocument(
            id: snap.id,
            title: snap.title,
            fileURL: url,
            content: textToRestore,
            savedContent: baseline,
            language: snap.language,
            hasEverBeenSaved: snap.hasEverBeenSaved,
            isModified: isDirty
        )
        doc.isOriginalFileMissing = missingOnDisk
        doc.externalConflictContent = conflictText
        doc.encoding = DocumentEncoding(rawValue: snap.encodingRawValue) ?? .utf8
        doc.lineEnding = LineEndingFormat(rawValue: snap.lineEndingRawValue) ?? .lf
        doc.bookmarks = Set(snap.bookmarks)
        doc.marks = snap.marks
        doc.cursorLine = max(1, snap.cursorLine)
        doc.cursorColumn = max(1, snap.cursorColumn)
        doc.selectedRange = NSRange(location: max(0, snap.selectedLocation), length: max(0, snap.selectedLength))
        doc.selectionLength = max(0, snap.selectedLength)
        doc.scrollOrigin = NSPoint(x: snap.scrollOriginX, y: snap.scrollOriginY)
        return doc
    }
}

public enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case light = "Light"
    case dark = "Dark"

    public static var system: AppAppearanceMode { .auto }

    public var id: String { rawValue }
    public var iconName: String {
        switch self {
        case .auto: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .auto: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

public struct CodeExecutionPlan: Equatable {
    public let supported: Bool
    public let language: String
    public let command: String
    public let workingDirectory: String
    public let stagedFileURL: URL?
    public let errorMessage: String?
}

public enum FindDialogTab: String, CaseIterable, Identifiable {
    case find = "Find"
    case replace = "Replace"
    case findInFiles = "Find in Files"
    case findInProjects = "Find in Projects"
    case mark = "Mark"

    public var id: String { rawValue }
}

public enum TransparencyMode: String, CaseIterable, Identifiable {
    case onLosingFocus = "On losing focus"
    case always = "Always"

    public var id: String { rawValue }
}

public enum EditorPaneSide: String, CaseIterable, Codable {
    case left = "Left"
    case right = "Right"
}

public class AppStateManager: ObservableObject {
    public static let appName = "NPad++"

    // UserDefault keys
    private let kFontFamily = "npad.fontFamily"
    private let kFontSize = "npad.fontSize"
    private let kAppearanceMode = "npad.appearanceMode"
    private let kTheme = "npad.theme"
    public static let kHasCompletedWelcome = "npad.hasCompletedWelcome"

    // Session & Recovery Storage Directory
    public let storageDirectoryURL: URL
    public var sessionFileURL: URL {
        storageDirectoryURL.appendingPathComponent("workspace-session.json")
    }

    @Published public var documents: [EditorDocument] = []
    @Published public var activeDocumentId: UUID? {
        didSet {
            if oldValue != activeDocumentId {
                scheduleSessionSave()
            }
        }
    }

    /// Alias for activeDocumentId for backward compatibility
    public var selectedDocumentID: UUID? {
        get { activeDocumentId }
        set { activeDocumentId = newValue }
    }

    @Published public var hoveredDocumentId: UUID?
    @Published public var isSidebarVisible: Bool = true
    @Published public var isBottomPanelVisible: Bool = false
    @Published public var activeBottomTab: String = "Terminal"

    /// Property indicating whether the terminal panel is currently visible
    public var showTerminal: Bool {
        get { isBottomPanelVisible && activeBottomTab == "Terminal" }
        set {
            isBottomPanelVisible = newValue
            if newValue {
                activeBottomTab = "Terminal"
            }
        }
    }

    @Published public var isSplitViewActive: Bool = false
    @Published public var leftDocumentId: UUID?
    @Published public var rightDocumentId: UUID?
    @Published public var leftDocumentIds: [UUID] = []
    @Published public var rightDocumentIds: [UUID] = []
    @Published public var leftActiveDocumentId: UUID? = nil
    @Published public var rightActiveDocumentId: UUID? = nil
    @Published public var draggingDocumentId: UUID? = nil
    @Published public var dragTargetPane: EditorPaneSide? = nil
    @Published public var dragTargetIndex: Int? = nil
    @Published public var isPaneDragOverLeft: Bool = false
    @Published public var isPaneDragOverRight: Bool = false
    @Published public var isSingleEditorDragOverRight: Bool = false
    @Published public var activePane: EditorPaneSide = .left
    @Published public var splitRatio: CGFloat = 0.5
    @Published public var isSynchronizedScrollingEnabled: Bool = true

    // File Comparison Properties
    @Published public var isComparing: Bool = false
    @Published public var comparisonResult: DiffResult? = nil
    @Published public var firstComparisonDocId: UUID? = nil

    // Project Explorer Properties
    @Published public var projectRootItem: ProjectItem? = nil
    @Published public var selectedProjectItemURL: URL? = nil

    // UI Toggles
    @Published public var isStatusBarVisible: Bool = true
    @Published public var showLineNumbers: Bool = true {
        didSet { editorActionSubject.send(.themeChanged) }
    }
    @Published public var syntaxHighlightingEnabled: Bool = true {
        didSet { editorActionSubject.send(.themeChanged) }
    }

    // Modal Sheets
    @Published public var showPluginManagerSheet: Bool = false
    @Published public var showDocumentationSheet: Bool = false

    // Sidebar Section Collapsing State (Macro-free)
    @Published public var isSidebarDocumentsExpanded: Bool = true
    @Published public var isSidebarBookmarksExpanded: Bool = true

    // Project Explorer Dialog State (Macro-free)
    @Published public var explorerNewFileDialogPresented: Bool = false
    @Published public var explorerNewFolderDialogPresented: Bool = false
    @Published public var explorerRenameDialogPresented: Bool = false
    @Published public var explorerDeleteAlertPresented: Bool = false
    @Published public var explorerTargetFolderURL: URL? = nil
    @Published public var explorerTargetItemURL: URL? = nil
    @Published public var explorerInputName: String = ""

    // Plugin Manager UI State (Macro-free)
    @Published public var pluginManagerSelectedTab: String = "Installed"
    @Published public var pluginManagerSelectedCategory: PluginCategory = .all
    @Published public var pluginManagerSearchText: String = ""
    @Published public var pluginManagerSelectedPlugin: PluginInfo? = nil

    // Documentation View UI State (Macro-free)
    @Published public var documentationSelectedTab: String = "Shortcuts"

    // Official GitHub Links & Author Attribution
    public static let githubRepositoryURL: String = "https://github.com/vasi-vijay/npad-plus-plus"
    public static let githubIssuesURL: String = "https://github.com/vasi-vijay/npad-plus-plus/issues"
    public static let githubRepoURL = URL(string: "https://github.com/vasi-vijay/npad-plus-plus")!
    public static let githubNewIssueURL = URL(string: "https://github.com/vasi-vijay/npad-plus-plus/issues/new")!
    public static let documentationURL = URL(string: "https://github.com/vasi-vijay/npad-plus-plus#readme")!
    public static let authorTag: String = "Made By Vijay"
    public static let authorInstagramURL: String = "https://www.instagram.com/made.by.vijay"

    @Published public var workspaceRootURL: URL? = nil

    // Appearance & Theme
    @Published public var appearanceMode: AppAppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: kAppearanceMode)
            applyAppearance()
            editorActionSubject.send(.themeChanged)
        }
    }

    @Published public var theme: String {
        didSet {
            UserDefaults.standard.set(theme, forKey: kTheme)
            editorActionSubject.send(.themeChanged)
        }
    }

    // Persistent Font Preferences
    @Published public var fontFamily: String {
        didSet {
            UserDefaults.standard.set(fontFamily, forKey: kFontFamily)
            editorActionSubject.send(.fontChanged)
        }
    }
    @Published public var fontSize: CGFloat {
        didSet {
            UserDefaults.standard.set(Double(fontSize), forKey: kFontSize)
            editorActionSubject.send(.fontChanged)
        }
    }

    @Published public var tabWidth: Int = 4
    @Published public var showWhitespace: Bool = false
    @Published public var wordWrap: Bool = false

    // Text Marking Preferences
    @Published public var activeMarkColor: String = "Yellow"

    // Sheets & Dialogs
    @Published public var showGoToLineSheet: Bool = false
    @Published public var showSettingsSheet: Bool = false
    @Published public var showWelcomeSheet: Bool = false
    @Published public var welcomeExploreFeaturesActive: Bool = false
    @Published public var targetLineNumber: String = "1"

    public var hasCompletedWelcome: Bool {
        get { UserDefaults.standard.bool(forKey: Self.kHasCompletedWelcome) }
        set { UserDefaults.standard.set(newValue, forKey: Self.kHasCompletedWelcome) }
    }

    public func markWelcomeCompleted() {
        hasCompletedWelcome = true
        showWelcomeSheet = false
        welcomeExploreFeaturesActive = false
    }

    public func openFolder(url: URL? = nil) {
        if let target = url {
            self.workspaceRootURL = target
            self.loadProject(from: target)
            _ = self.changeTerminalDirectory(to: target.path)
            self.terminalOutput.append("[Opened workspace folder: \(target.path)]")
            self.scheduleSessionSave()
            return
        }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Select Folder"
        panel.title = "Open Project Folder"
        if panel.runModal() == .OK, let selectedURL = panel.url {
            self.workspaceRootURL = selectedURL
            self.loadProject(from: selectedURL)
            _ = self.changeTerminalDirectory(to: selectedURL.path)
            self.terminalOutput.append("[Opened workspace folder: \(selectedURL.path)]")
            self.scheduleSessionSave()
        }
    }

    public func loadProject(from url: URL) {
        if workspaceRootURL == nil {
            workspaceRootURL = url
        }
        let tree = ProjectExplorerService.buildTree(for: url)
        if Thread.isMainThread {
            self.projectRootItem = tree
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.projectRootItem = tree
            }
        }
    }

    public func refreshProject() {
        guard let root = workspaceRootURL else { return }
        loadProject(from: root)
    }

    public func closeFolder() {
        workspaceRootURL = nil
        projectRootItem = nil
        selectedProjectItemURL = nil
        scheduleSessionSave()
    }

    public func openFileFromProject(url: URL, inPane: EditorPaneSide? = nil) {
        if let pane = inPane {
            openFileInPane(url: url, pane: pane)
            selectedProjectItemURL = url
            return
        }
        if isSplitViewActive {
            openFileInPane(url: url, pane: activePane)
            selectedProjectItemURL = url
            return
        }
        _ = try? openFileFromURL(url)
        selectedProjectItemURL = url
    }

    // In-Editor Find & Replace State
    @Published public var isFindBarVisible: Bool = false
    @Published public var isReplaceBarVisible: Bool = false
    @Published public var showFindWindow: Bool = false
    @Published public var findDialogTab: FindDialogTab = .find
    @Published public var searchHistory: [String] = []
    @Published public var replaceHistory: [String] = []
    @Published public var searchQuery: String = "" {
        didSet {
            if oldValue != searchQuery {
                updateSearchMatches()
            }
        }
    }
    @Published public var replaceQuery: String = ""
    @Published public var searchCaseSensitive: Bool = false {
        didSet { updateSearchMatches() }
    }
    @Published public var searchWholeWord: Bool = false {
        didSet { updateSearchMatches() }
    }
    @Published public var searchRegex: Bool = false {
        didSet { updateSearchMatches() }
    }
    @Published public var searchWrapAround: Bool = true
    @Published public var searchMode: SearchModeType = .normal {
        didSet { updateSearchMatches() }
    }
    @Published public var searchBackward: Bool = false
    @Published public var searchDotMatchesNewline: Bool = false {
        didSet { updateSearchMatches() }
    }
    @Published public var searchInSelection: Bool = false {
        didSet { updateSearchMatches() }
    }
    @Published public var searchFilters: String = "*.*"
    @Published public var searchDirectory: String = ""
    @Published public var searchInSubfolders: Bool = true
    @Published public var searchInHiddenFolders: Bool = false
    @Published public var projectPanel1: Bool = false
    @Published public var projectPanel2: Bool = false
    @Published public var projectPanel3: Bool = false
    @Published public var markBookmarkLine: Bool = false
    @Published public var markPurgeForSearch: Bool = false
    @Published public var transparencyEnabled: Bool = true
    @Published public var transparencyMode: TransparencyMode = .onLosingFocus
    @Published public var transparencyOpacity: Double = 0.85
    @Published public var searchResultsList: [SearchResultItem] = []
    @Published public var searchResultsSummary: String = ""

    @Published public var searchMatches: [NSRange] = []
    @Published public var currentMatchIndex: Int = 0 // 1-based (0 if none)
    @Published public var searchStatusMessage: String = ""

    // Terminal State
    @Published public var terminalCommand: String = ""
    @Published public var terminalWorkingDirectory: String = FileManager.default.currentDirectoryPath
    @Published public var isTerminalRunning: Bool = false
    public var currentTerminalProcess: Process? = nil
    @Published public var terminalOutput: [String] = [
        "NPad++ Developer Terminal — zsh / bash",
        "Ready. Persistent working directory & shell execution active."
    ]

    private var saveWorkItem: DispatchWorkItem?

    public static func defaultStorageDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let legacyDir = appSupport.appendingPathComponent("CodePad/Recovery", isDirectory: true)
        let newDir = appSupport.appendingPathComponent("NPadPlusPlus/Recovery", isDirectory: true)

        // Seamless migration: preserve legacy session data while supporting NPad++
        if FileManager.default.fileExists(atPath: legacyDir.path) && !FileManager.default.fileExists(atPath: newDir.path) {
            try? FileManager.default.copyItem(at: legacyDir, to: newDir)
        }
        if FileManager.default.fileExists(atPath: newDir.path) {
            return newDir
        }
        return legacyDir
    }

    public init(storageDirectoryURL: URL? = nil, restorePreviousSession: Bool = true) {
        self.storageDirectoryURL = storageDirectoryURL ?? Self.defaultStorageDirectory()
        try? FileManager.default.createDirectory(at: self.storageDirectoryURL, withIntermediateDirectories: true)

        // Load appearance mode
        if let savedMode = UserDefaults.standard.string(forKey: kAppearanceMode) {
            if savedMode == "System" || savedMode == "Auto" {
                self.appearanceMode = .auto
            } else if let mode = AppAppearanceMode(rawValue: savedMode) {
                self.appearanceMode = mode
            } else {
                self.appearanceMode = .auto
            }
        } else {
            self.appearanceMode = .auto
        }

        // Load theme
        let savedTheme = UserDefaults.standard.string(forKey: kTheme)
        if savedTheme == "Notepad++ Classic" || savedTheme == "N Pad++ Classic" || savedTheme == "NPad++ Classic" || savedTheme == nil {
            self.theme = "NPad++ Classic"
        } else {
            self.theme = savedTheme!
        }

        // Load persisted font or defaults
        let savedFamily = UserDefaults.standard.string(forKey: kFontFamily)
        self.fontFamily = savedFamily ?? "SF Mono"

        let savedSize = UserDefaults.standard.double(forKey: kFontSize)
        self.fontSize = savedSize > 8.0 ? CGFloat(savedSize) : 13.5

        let sessionRestored = restorePreviousSession && self.restoreSessionFromDisk()
        if sessionRestored {
            // Restored previous session successfully
        } else {
            let initialDoc = EditorDocument(
                title: "DemoApplication.java",
                content: """
                package com.example.demo;

                public class DemoApplication {

                    public static void main(String[] args) {
                        System.out.println("Hello from NPad++!");
                    }
                }
                """,
                language: "Java"
            )
            self.documents = [initialDoc]
            self.activeDocumentId = initialDoc.id
        }

        for doc in self.documents {
            registerDocumentBinding(doc)
        }

        if self.leftDocumentIds.isEmpty {
            self.leftDocumentIds = self.documents.map(\.id)
        }
        if self.leftActiveDocumentId == nil {
            self.leftActiveDocumentId = self.activeDocumentId ?? self.documents.first?.id
        }
        self.leftDocumentId = self.leftActiveDocumentId
        if self.rightActiveDocumentId == nil {
            self.rightActiveDocumentId = self.rightDocumentIds.first
        }
        self.rightDocumentId = self.rightActiveDocumentId

        applyAppearance()

        // First-launch welcome experience:
        // Automatically display on first launch for a new user if not restoring an existing session
        if !hasCompletedWelcome && !sessionRestored {
            self.showWelcomeSheet = true
        }
    }

    // MARK: - Session Persistence & Recovery (Priority 1)
    public func scheduleSessionSave(immediate: Bool = false) {
        saveWorkItem?.cancel()
        if immediate {
            saveSessionToDisk()
            return
        }
        let item = DispatchWorkItem { [weak self] in
            self?.saveSessionToDisk()
        }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
    }

    @discardableResult
    public func saveSessionToDisk() -> Bool {
        do {
            try FileManager.default.createDirectory(at: storageDirectoryURL, withIntermediateDirectories: true)
            let session = PersistedWorkspaceSession(
                version: 2,
                activeDocumentId: activeDocumentId,
                tabOrder: documents.map { $0.id },
                documents: documents.map { $0.toPersistedSnapshot() },
                terminalWorkingDirectory: terminalWorkingDirectory,
                workspaceRootURLString: workspaceRootURL?.path,
                updatedAt: Date().timeIntervalSince1970,
                leftTabOrder: leftDocumentIds,
                rightTabOrder: rightDocumentIds,
                isSplitViewActive: isSplitViewActive,
                splitRatio: Double(splitRatio),
                activePane: activePane.rawValue
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(session)
            try data.write(to: sessionFileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    public func restoreSessionFromDisk() -> Bool {
        guard FileManager.default.fileExists(atPath: sessionFileURL.path) else {
            return false
        }
        do {
            let data = try Data(contentsOf: sessionFileURL)
            let decoder = JSONDecoder()
            let session = try decoder.decode(PersistedWorkspaceSession.self, from: data)
            guard !session.documents.isEmpty else { return false }

            var docMap: [UUID: EditorDocument] = [:]
            for snap in session.documents {
                let doc = EditorDocument.fromPersistedSnapshot(snap)
                docMap[doc.id] = doc
            }

            var ordered: [EditorDocument] = []
            for id in session.tabOrder {
                if let doc = docMap.removeValue(forKey: id) {
                    ordered.append(doc)
                }
            }
            for remaining in docMap.values {
                ordered.append(remaining)
            }

            guard !ordered.isEmpty else { return false }
            for doc in ordered {
                registerDocumentBinding(doc)
            }
            self.documents = ordered
            if let activeId = session.activeDocumentId, ordered.contains(where: { $0.id == activeId }) {
                self.activeDocumentId = activeId
            } else {
                self.activeDocumentId = ordered.first?.id
            }

            if let savedCwd = session.terminalWorkingDirectory,
               FileManager.default.fileExists(atPath: savedCwd) {
                self.terminalWorkingDirectory = savedCwd
            }

            if let wsPath = session.workspaceRootURLString, !wsPath.isEmpty {
                let url = URL(fileURLWithPath: wsPath)
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: wsPath, isDirectory: &isDir) && isDir.boolValue {
                    self.workspaceRootURL = url
                    self.loadProject(from: url)
                }
            }

            if let isSplit = session.isSplitViewActive {
                self.isSplitViewActive = isSplit
            }
            if let ratio = session.splitRatio {
                self.splitRatio = CGFloat(ratio)
            }
            if let paneStr = session.activePane, let p = EditorPaneSide(rawValue: paneStr) {
                self.activePane = p
            }
            if let leftTabs = session.leftTabOrder, !leftTabs.isEmpty {
                self.leftDocumentIds = leftTabs.filter { id in ordered.contains(where: { $0.id == id }) }
            } else {
                self.leftDocumentIds = ordered.map(\.id)
            }
            if let rightTabs = session.rightTabOrder {
                self.rightDocumentIds = rightTabs.filter { id in ordered.contains(where: { $0.id == id }) }
            }
            for doc in ordered {
                if !self.leftDocumentIds.contains(doc.id) && !self.rightDocumentIds.contains(doc.id) {
                    self.leftDocumentIds.append(doc.id)
                }
            }
            self.leftActiveDocumentId = self.leftDocumentIds.first
            self.rightActiveDocumentId = self.rightDocumentIds.first
            self.leftDocumentId = self.leftActiveDocumentId
            self.rightDocumentId = self.rightActiveDocumentId

            return true
        } catch {
            return false
        }
    }

    // MARK: - Document Lifecycle & Safe Closing (Priority 1.1 - 1.5)
    public var leftDocuments: [EditorDocument] {
        if leftDocumentIds.isEmpty && !isSplitViewActive {
            return documents
        }
        return leftDocumentIds.compactMap { id in documents.first(where: { $0.id == id }) }
    }

    public var rightDocuments: [EditorDocument] {
        return rightDocumentIds.compactMap { id in documents.first(where: { $0.id == id }) }
    }

    public var leftDocument: EditorDocument? {
        if let id = leftActiveDocumentId ?? leftDocumentId, let doc = documents.first(where: { $0.id == id }) {
            return doc
        }
        return leftDocuments.first ?? documents.first
    }

    public var rightDocument: EditorDocument? {
        if let id = rightActiveDocumentId ?? rightDocumentId, let doc = documents.first(where: { $0.id == id }) {
            return doc
        }
        return rightDocuments.first
    }

    public var activeDocument: EditorDocument? {
        get {
            if isSplitViewActive {
                if activePane == .left {
                    return leftDocument
                } else {
                    return rightDocument ?? leftDocument
                }
            }
            if let id = activeDocumentId, let doc = documents.first(where: { $0.id == id }) {
                return doc
            }
            if let first = documents.first {
                activeDocumentId = first.id
                return first
            }
            return nil
        }
        set {
            activeDocumentId = newValue?.id
            if isSplitViewActive {
                if activePane == .left {
                    leftActiveDocumentId = newValue?.id
                    leftDocumentId = newValue?.id
                } else {
                    rightActiveDocumentId = newValue?.id
                    rightDocumentId = newValue?.id
                }
            } else {
                leftActiveDocumentId = newValue?.id
                leftDocumentId = newValue?.id
            }
        }
    }

    public func document(for side: EditorPaneSide) -> EditorDocument? {
        return (side == .left) ? leftDocument : rightDocument
    }

    public func registerDocumentBinding(_ doc: EditorDocument) {
        doc.onContentDidChange = { [weak self, weak doc] in
            guard let self = self, let d = doc else { return }
            if self.isComparing && (d.id == self.leftDocumentId || d.id == self.rightDocumentId) {
                self.recompare()
            }
        }
    }

    @discardableResult
    public func createNewDocument(pane: EditorPaneSide? = nil) -> EditorDocument {
        let existingNumbers = documents.compactMap { doc -> Int? in
            if doc.title.lowercased().hasPrefix("new ") {
                let numPart = doc.title.dropFirst(4).trimmingCharacters(in: .whitespaces)
                return Int(numPart)
            }
            return nil
        }
        let nextNum = (existingNumbers.max() ?? documents.count) + 1
        let doc = EditorDocument(
            title: "new \(nextNum)",
            fileURL: nil,
            content: "",
            savedContent: "",
            language: "Plain Text",
            hasEverBeenSaved: false,
            isModified: false
        )
        registerDocumentBinding(doc)
        documents.append(doc)

        let targetPane = pane ?? (isSplitViewActive ? activePane : .left)
        if isSplitViewActive && targetPane == .right {
            rightDocumentIds.append(doc.id)
            rightActiveDocumentId = doc.id
            rightDocumentId = doc.id
            activePane = .right
        } else {
            leftDocumentIds.append(doc.id)
            leftActiveDocumentId = doc.id
            leftDocumentId = doc.id
            if !isSplitViewActive {
                activePane = .left
            }
        }
        activeDocumentId = doc.id
        scheduleSessionSave(immediate: true)
        return doc
    }

    @discardableResult
    public func openFileFromURL(_ url: URL) throws -> EditorDocument {
        if let existing = documents.first(where: { $0.fileURL?.standardizedFileURL == url.standardizedFileURL }) {
            if isSplitViewActive {
                if activePane == .left {
                    if !leftDocumentIds.contains(existing.id) {
                        rightDocumentIds.removeAll(where: { $0 == existing.id })
                        leftDocumentIds.append(existing.id)
                    }
                    leftActiveDocumentId = existing.id
                    leftDocumentId = existing.id
                } else {
                    if !rightDocumentIds.contains(existing.id) {
                        leftDocumentIds.removeAll(where: { $0 == existing.id })
                        rightDocumentIds.append(existing.id)
                    }
                    rightActiveDocumentId = existing.id
                    rightDocumentId = existing.id
                }
            } else {
                if !leftDocumentIds.contains(existing.id) {
                    leftDocumentIds.append(existing.id)
                }
                leftActiveDocumentId = existing.id
                leftDocumentId = existing.id
            }
            activeDocumentId = existing.id
            return existing
        }

        let data = try Data(contentsOf: url)
        var loadedText: String = ""
        var detectedEncoding: DocumentEncoding = .utf8
        if let str = String(data: data, encoding: .utf8) {
            loadedText = str
            detectedEncoding = .utf8
        } else if let str = String(data: data, encoding: .utf16) {
            loadedText = str
            detectedEncoding = .utf16LE
        } else if let str = String(data: data, encoding: .isoLatin1) {
            loadedText = str
            detectedEncoding = .ascii
        } else {
            loadedText = String(decoding: data, as: UTF8.self)
        }

        let ending: LineEndingFormat
        if loadedText.contains("\r\n") {
            ending = .crlf
        } else if loadedText.contains("\r") && !loadedText.contains("\n") {
            ending = .cr
        } else {
            ending = .lf
        }

        let filename = url.lastPathComponent
        let lang = SyntaxEngine.detectLanguage(from: filename, content: loadedText)

        let newDoc = EditorDocument(
            title: filename,
            fileURL: url,
            content: loadedText,
            savedContent: loadedText,
            language: lang,
            hasEverBeenSaved: true,
            isModified: false
        )
        newDoc.encoding = detectedEncoding
        newDoc.lineEnding = ending
        registerDocumentBinding(newDoc)
        documents.append(newDoc)

        if isSplitViewActive {
            if activePane == .left {
                leftDocumentIds.append(newDoc.id)
                leftActiveDocumentId = newDoc.id
                leftDocumentId = newDoc.id
            } else {
                rightDocumentIds.append(newDoc.id)
                rightActiveDocumentId = newDoc.id
                rightDocumentId = newDoc.id
            }
        } else {
            leftDocumentIds.append(newDoc.id)
            leftActiveDocumentId = newDoc.id
            leftDocumentId = newDoc.id
        }
        activeDocumentId = newDoc.id
        scheduleSessionSave(immediate: true)
        return newDoc
    }

    @discardableResult
    public func saveDocument(_ doc: EditorDocument, to targetURL: URL? = nil) throws -> Bool {
        guard let url = targetURL ?? doc.fileURL else {
            return false
        }
        try doc.content.write(to: url, atomically: true, encoding: .utf8)
        doc.markAsSaved(at: url)
        doc.language = SyntaxEngine.detectLanguage(from: url.lastPathComponent, content: doc.content)
        self.objectWillChange.send()
        scheduleSessionSave(immediate: true)
        return true
    }

    /// Closes a document safely. If the document is modified, invokes `decisionHandler`
    /// (or presents a Save / Don't Save / Cancel NSAlert when running in interactive UI).
    @discardableResult
    public func closeDocument(
        id: UUID,
        decisionHandler: ((EditorDocument) -> TabCloseDecision)? = nil
    ) -> Bool {
        guard let idx = documents.firstIndex(where: { $0.id == id }) else {
            return false
        }
        let doc = documents[idx]
        doc.recalculateModifiedState()

        if doc.isModified {
            let decision: TabCloseDecision
            if let handler = decisionHandler {
                decision = handler(doc)
            } else {
                decision = promptSaveDecisionAlert(for: doc)
            }

            switch decision {
            case .cancel:
                return false
            case .save:
                if let url = doc.fileURL {
                    do {
                        try saveDocument(doc, to: url)
                    } catch {
                        return false
                    }
                } else {
                    // Needs Save As panel in GUI
                    activeDocumentId = doc.id
                    let saved = saveActiveDocumentWithPanelIfNeeded()
                    if !saved {
                        return false
                    }
                }
            case .dontSave:
                break
            }
        }

        documents.remove(at: idx)
        leftDocumentIds.removeAll(where: { $0 == id })
        rightDocumentIds.removeAll(where: { $0 == id })

        if documents.isEmpty {
            let fallback = EditorDocument(
                title: "new 1",
                fileURL: nil,
                content: "",
                savedContent: "",
                language: "Plain Text",
                hasEverBeenSaved: false,
                isModified: false
            )
            registerDocumentBinding(fallback)
            documents.append(fallback)
            activeDocumentId = fallback.id
            leftDocumentIds = [fallback.id]
            leftActiveDocumentId = fallback.id
            leftDocumentId = fallback.id
            rightDocumentIds = []
            rightActiveDocumentId = nil
            rightDocumentId = nil
            isSplitViewActive = false
            clearComparison()
        } else {
            if isSplitViewActive {
                if leftActiveDocumentId == id {
                    leftActiveDocumentId = leftDocumentIds.last
                    leftDocumentId = leftActiveDocumentId
                }
                if rightActiveDocumentId == id {
                    rightActiveDocumentId = rightDocumentIds.last
                    rightDocumentId = rightActiveDocumentId
                }
                if isComparing {
                    recompare()
                }
            }
            if activeDocumentId == id {
                if isSplitViewActive {
                    activeDocumentId = (activePane == .left ? leftActiveDocumentId : rightActiveDocumentId) ?? documents.first?.id
                } else {
                    let nextIdx = min(idx, documents.count - 1)
                    activeDocumentId = documents[nextIdx].id
                }
            }
        }

        scheduleSessionSave(immediate: true)
        return true
    }

    private func promptSaveDecisionAlert(for doc: EditorDocument) -> TabCloseDecision {
        let alert = NSAlert()
        alert.messageText = "Do you want to save the changes made to \"\(doc.title)\"?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            return .save
        case .alertSecondButtonReturn:
            return .dontSave
        default:
            return .cancel
        }
    }

    @discardableResult
    public func saveActiveDocumentWithPanelIfNeeded(saveAs: Bool = false) -> Bool {
        guard let doc = activeDocument else { return false }
        if doc.fileURL == nil || saveAs {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = doc.title
            if panel.runModal() == .OK, let url = panel.url {
                do {
                    let ok = try saveDocument(doc, to: url)
                    self.objectWillChange.send()
                    return ok
                } catch {
                    return false
                }
            }
            return false
        } else if let url = doc.fileURL {
            do {
                let ok = try saveDocument(doc, to: url)
                self.objectWillChange.send()
                return ok
            } catch {
                return false
            }
        }
        return false
    }

    // MARK: - Per-Document Undo & Redo (Priority 2)
    public func undoActiveDocument() {
        guard let doc = activeDocument else { return }
        doc.undo()
        editorActionSubject.send(.contentReplacedFromUndoRedo)
        scheduleSessionSave()
    }

    public func redoActiveDocument() {
        guard let doc = activeDocument else { return }
        doc.redo()
        editorActionSubject.send(.contentReplacedFromUndoRedo)
        scheduleSessionSave()
    }

    // MARK: - Print Document
    public func printActiveDocument() {
        guard activeDocument != nil else { return }
        NSApp.sendAction(#selector(CodePadTextView.handleContextPrint), to: nil, from: nil)
    }

    // MARK: - Terminal & Open Terminal Here (Priority 1 & Priority 3)
    public func changeTerminalDirectory(to path: String) -> Bool {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        var targetPath = trimmed
        if targetPath.isEmpty || targetPath == "~" {
            targetPath = NSHomeDirectory()
        } else if targetPath.hasPrefix("~/") {
            targetPath = (NSHomeDirectory() as NSString).appendingPathComponent(String(targetPath.dropFirst(2)))
        } else if !targetPath.hasPrefix("/") {
            targetPath = (terminalWorkingDirectory as NSString).appendingPathComponent(targetPath)
        }

        targetPath = (targetPath as NSString).standardizingPath
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: targetPath, isDirectory: &isDir), isDir.boolValue {
            terminalWorkingDirectory = targetPath
            scheduleSessionSave()
            return true
        }
        return false
    }

    /// Resolves the best directory for "Open Terminal Here":
    /// 1. Parent directory of active saved file
    /// 2. Workspace root directory (if open)
    /// 3. Current terminal working directory / user home
    public func resolveTerminalDirectory(for doc: EditorDocument? = nil, preferFileDirectory: Bool = true) -> String {
        let targetDoc = doc ?? activeDocument
        let fileDir = targetDoc?.fileURL?.deletingLastPathComponent().path
        let workspaceDir = workspaceRootURL?.path

        if preferFileDirectory {
            if let fd = fileDir, FileManager.default.fileExists(atPath: fd) {
                return fd
            }
            if let wd = workspaceDir, FileManager.default.fileExists(atPath: wd) {
                return wd
            }
        } else {
            if let wd = workspaceDir, FileManager.default.fileExists(atPath: wd) {
                return wd
            }
            if let fd = fileDir, FileManager.default.fileExists(atPath: fd) {
                return fd
            }
        }

        if FileManager.default.fileExists(atPath: terminalWorkingDirectory) {
            return terminalWorkingDirectory
        }
        return NSHomeDirectory()
    }

    /// Opens the integrated terminal panel in the active file's directory (Priority 3).
    @discardableResult
    public func openTerminalHere(for doc: EditorDocument? = nil) -> String {
        let resolved = resolveTerminalDirectory(for: doc, preferFileDirectory: true)
        isBottomPanelVisible = true
        activeBottomTab = "Terminal"

        if isTerminalRunning {
            terminalOutput.append("[Terminal busy running command. Target directory: \(resolved)]")
        } else {
            _ = changeTerminalDirectory(to: resolved)
            terminalOutput.append("[Opened terminal at: \(terminalWorkingDirectory)]")
        }
        return resolved
    }

    public func cancelTerminalCommand() {
        currentTerminalProcess?.terminate()
        currentTerminalProcess = nil
        isTerminalRunning = false
        terminalOutput.append("[Command cancelled]")
    }

    // MARK: - Run Source Code Directly From Editor (Priority 4)
    public func buildRunPlan(for doc: EditorDocument) -> CodeExecutionPlan {
        let ext = (doc.title as NSString).pathExtension.lowercased()
        let lang = doc.language.lowercased()
        let stagingDir = storageDirectoryURL
            .deletingLastPathComponent()
            .appendingPathComponent("RunStaging", isDirectory: true)
        try? FileManager.default.createDirectory(at: stagingDir, withIntermediateDirectories: true)

        let baseDir = resolveTerminalDirectory(for: doc, preferFileDirectory: true)

        // 1. Java (.java)
        if lang == "java" || ext == "java" {
            let (pkg, className) = Self.extractJavaPackageAndClass(from: doc.content, fallbackTitle: doc.title)
            let qualifiedName = pkg != nil ? "\(pkg!).\(className)" : className
            let relDir = pkg?.replacingOccurrences(of: ".", with: "/") ?? ""
            let targetSubdir = relDir.isEmpty ? stagingDir : stagingDir.appendingPathComponent(relDir, isDirectory: true)
            try? FileManager.default.createDirectory(at: targetSubdir, withIntermediateDirectories: true)

            let stagedFile = targetSubdir.appendingPathComponent("\(className).java")
            try? doc.content.write(to: stagedFile, atomically: true, encoding: .utf8)
            let relSourcePath = relDir.isEmpty ? "\(className).java" : "\(relDir)/\(className).java"
            let cmd = "javac -d . \"\(relSourcePath)\" && java -cp . \(qualifiedName)"
            return CodeExecutionPlan(
                supported: true,
                language: "Java",
                command: cmd,
                workingDirectory: stagingDir.path,
                stagedFileURL: stagedFile,
                errorMessage: nil
            )
        }

        // 2. Python (.py)
        if lang == "python" || ext == "py" {
            let safeName = doc.title.hasSuffix(".py") ? doc.title : "\(doc.title).py"
            let targetURL = (doc.fileURL != nil && !doc.isModified) ? doc.fileURL! : stagingDir.appendingPathComponent(safeName)
            if doc.fileURL == nil || doc.isModified {
                try? doc.content.write(to: targetURL, atomically: true, encoding: .utf8)
            }
            return CodeExecutionPlan(
                supported: true,
                language: "Python",
                command: "python3 \"\(targetURL.path)\"",
                workingDirectory: baseDir,
                stagedFileURL: targetURL,
                errorMessage: nil
            )
        }

        // 3. JavaScript (.js)
        if lang == "javascript" || ext == "js" || ext == "mjs" {
            let safeName = doc.title.hasSuffix(".js") ? doc.title : "\(doc.title).js"
            let targetURL = (doc.fileURL != nil && !doc.isModified) ? doc.fileURL! : stagingDir.appendingPathComponent(safeName)
            if doc.fileURL == nil || doc.isModified {
                try? doc.content.write(to: targetURL, atomically: true, encoding: .utf8)
            }
            return CodeExecutionPlan(
                supported: true,
                language: "JavaScript",
                command: "node \"\(targetURL.path)\"",
                workingDirectory: baseDir,
                stagedFileURL: targetURL,
                errorMessage: nil
            )
        }

        // 4. Shell (.sh / .zsh)
        if lang == "shell" || ext == "sh" || ext == "zsh" || ext == "bash" {
            let safeName = doc.title.hasSuffix(".sh") ? doc.title : "\(doc.title).sh"
            let targetURL = (doc.fileURL != nil && !doc.isModified) ? doc.fileURL! : stagingDir.appendingPathComponent(safeName)
            if doc.fileURL == nil || doc.isModified {
                try? doc.content.write(to: targetURL, atomically: true, encoding: .utf8)
            }
            return CodeExecutionPlan(
                supported: true,
                language: "Shell",
                command: "bash \"\(targetURL.path)\"",
                workingDirectory: baseDir,
                stagedFileURL: targetURL,
                errorMessage: nil
            )
        }

        // 5. Swift (.swift)
        if lang == "swift" || ext == "swift" {
            let safeName = doc.title.hasSuffix(".swift") ? doc.title : "\(doc.title).swift"
            let targetURL = (doc.fileURL != nil && !doc.isModified) ? doc.fileURL! : stagingDir.appendingPathComponent(safeName)
            if doc.fileURL == nil || doc.isModified {
                try? doc.content.write(to: targetURL, atomically: true, encoding: .utf8)
            }
            return CodeExecutionPlan(
                supported: true,
                language: "Swift",
                command: "swift \"\(targetURL.path)\"",
                workingDirectory: baseDir,
                stagedFileURL: targetURL,
                errorMessage: nil
            )
        }

        // 6. C / C++
        if lang == "c" || ext == "c" || lang == "c++" || ext == "cpp" {
            let isCpp = (lang == "c++" || ext == "cpp")
            let safeName = doc.title.contains(".") ? doc.title : (isCpp ? "main.cpp" : "main.c")
            let targetURL = stagingDir.appendingPathComponent(safeName)
            let binURL = stagingDir.appendingPathComponent("npad_bin_out")
            try? doc.content.write(to: targetURL, atomically: true, encoding: .utf8)
            let compiler = isCpp ? "clang++ -std=c++17" : "clang"
            return CodeExecutionPlan(
                supported: true,
                language: isCpp ? "C++" : "C",
                command: "\(compiler) \"\(targetURL.path)\" -o \"\(binURL.path)\" && \"\(binURL.path)\"",
                workingDirectory: stagingDir.path,
                stagedFileURL: targetURL,
                errorMessage: nil
            )
        }

        // 7. HTML (.html / .htm)
        if lang == "html" || ext == "html" || ext == "htm" {
            let safeName = (doc.title.hasSuffix(".html") || doc.title.hasSuffix(".htm")) ? doc.title : "\(doc.title).html"
            let targetURL = (doc.fileURL != nil && !doc.isModified) ? doc.fileURL! : stagingDir.appendingPathComponent(safeName)
            if doc.fileURL == nil || doc.isModified {
                try? doc.content.write(to: targetURL, atomically: true, encoding: .utf8)
            }
            return CodeExecutionPlan(
                supported: true,
                language: "HTML",
                command: "open \"\(targetURL.path)\"",
                workingDirectory: baseDir,
                stagedFileURL: targetURL,
                errorMessage: nil
            )
        }

        return CodeExecutionPlan(
            supported: false,
            language: doc.language,
            command: "",
            workingDirectory: baseDir,
            stagedFileURL: nil,
            errorMessage: "Direct execution is not configured for \(doc.language) (\(doc.title))."
        )
    }

    public static func extractJavaPackageAndClass(from source: String, fallbackTitle: String) -> (String?, String) {
        var pkgName: String? = nil
        if let pkgRegex = try? NSRegularExpression(pattern: #"(?m)^\s*package\s+([A-Za-z_][\w.]*)\s*;"#),
           let match = pkgRegex.firstMatch(in: source, range: NSRange(location: 0, length: (source as NSString).length)),
           match.numberOfRanges > 1 {
            pkgName = (source as NSString).substring(with: match.range(at: 1))
        }

        var className = (fallbackTitle as NSString).deletingPathExtension
        if className.isEmpty { className = "Main" }

        if let clsRegex = try? NSRegularExpression(pattern: #"\bpublic\s+(?:final\s+|abstract\s+)?class\s+([A-Za-z_]\w*)"#),
           let match = clsRegex.firstMatch(in: source, range: NSRange(location: 0, length: (source as NSString).length)),
           match.numberOfRanges > 1 {
            className = (source as NSString).substring(with: match.range(at: 1))
        } else if let anyClsRegex = try? NSRegularExpression(pattern: #"\bclass\s+([A-Za-z_]\w*)"#),
                  let match = anyClsRegex.firstMatch(in: source, range: NSRange(location: 0, length: (source as NSString).length)),
                  match.numberOfRanges > 1 {
            className = (source as NSString).substring(with: match.range(at: 1))
        }

        return (pkgName, className)
    }

    // Action notifications for Editor View
    public let findActionSubject = PassthroughSubject<EditorSearchCommand, Never>()
    public let editorActionSubject = PassthroughSubject<EditorGlobalCommand, Never>()

    public enum EditorSearchCommand {
        case selectMatch(NSRange)
        case replaceCurrent(replacement: String, range: NSRange)
        case replaceAll(query: String, replacement: String, options: SearchOptions)
        case clearHighlights
        case focusEditor
        case focusSearch
    }

    public enum EditorGlobalCommand {
        case fontChanged
        case languageChanged
        case marksChanged
        case themeChanged
        case contentReplacedFromUndoRedo
        case diffUpdated
        case scrollToDifference(DiffChunk)
        case synchronizedScroll(senderPane: EditorPaneSide, scrollRatio: CGFloat)
    }

    public var isDarkMode: Bool {
        switch appearanceMode {
        case .light: return false
        case .dark: return true
        case .auto:
            let app = NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
            return app == .darkAqua
        }
    }

    public func applyAppearance() {
        guard NSApp != nil else { return }
        switch appearanceMode {
        case .auto:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    public var availableFontFamilies: [String] {
        let preferred = [
            "SF Mono", "Menlo", "JetBrains Mono", "Fira Code", "Source Code Pro",
            "Courier New", "Courier", "Monaco", "PT Mono", "Andale Mono"
        ]
        let installed = Set(NSFontManager.shared.availableFontFamilies)
        var result: [String] = []
        for c in preferred {
            if installed.contains(c) || c == "SF Mono" {
                result.append(c)
            }
        }
        let otherMono = installed.filter { name in
            !preferred.contains(name) && (
                name.localizedCaseInsensitiveContains("mono") ||
                name.localizedCaseInsensitiveContains("code")
            )
        }.sorted()
        result.append(contentsOf: otherMono)

        if result.isEmpty {
            result = ["SF Mono", "Menlo", "Courier", "Monaco"]
        }
        return result
    }

    // MARK: - Font Size Shortcuts
    public func increaseFontSize() {
        if fontSize < 36.0 {
            fontSize += 1.0
        }
    }

    public func decreaseFontSize() {
        if fontSize > 9.0 {
            fontSize -= 1.0
        }
    }

    public func resetFontSize() {
        fontSize = 13.5
    }

    // MARK: - Persistent Text Marking
    public func markSelection() {
        guard let doc = activeDocument, doc.selectedRange.length > 0 else { return }
        doc.toggleMark(for: doc.selectedRange, colorName: activeMarkColor)
        editorActionSubject.send(.marksChanged)
        scheduleSessionSave()
    }

    public func clearAllMarksInActiveDocument() {
        guard let doc = activeDocument else { return }
        doc.clearAllMarks()
        editorActionSubject.send(.marksChanged)
        scheduleSessionSave()
    }

    // MARK: - Language Mode Changing
    public func setLanguageForActiveDocument(_ lang: String) {
        guard let doc = activeDocument else { return }
        doc.language = lang
        editorActionSubject.send(.languageChanged)
        scheduleSessionSave()
    }

    // MARK: - Search Operations
    public var currentSearchOptions: SearchOptions {
        SearchOptions(
            caseSensitive: searchCaseSensitive,
            wholeWord: searchWholeWord,
            isRegex: searchRegex || (searchMode == .regex),
            wrapAround: searchWrapAround,
            backward: searchBackward,
            searchMode: searchMode,
            dotMatchesNewline: searchDotMatchesNewline,
            inSelection: searchInSelection
        )
    }

    public func openFindBar(withReplace: Bool = false) {
        openFindDialog(tab: withReplace ? .replace : .find)
    }

    public func openFindDialog(tab: FindDialogTab = .find) {
        self.findDialogTab = tab
        self.showFindWindow = true
        self.isFindBarVisible = false
        self.isReplaceBarVisible = (tab == .replace)

        if searchDirectory.isEmpty {
            if let activeURL = activeDocument?.fileURL {
                searchDirectory = activeURL.deletingLastPathComponent().path
            } else {
                searchDirectory = terminalWorkingDirectory
            }
        }

        if let doc = activeDocument, doc.selectedRange.length > 0, doc.selectedRange.length < 200 {
            let nsStr = doc.content as NSString
            if doc.selectedRange.location + doc.selectedRange.length <= nsStr.length {
                searchQuery = nsStr.substring(with: doc.selectedRange)
            }
        }

        updateSearchMatches()
        findActionSubject.send(.focusSearch)
        NotepadPlusFindWindowController.shared.show(appState: self, tab: tab)
    }

    public func closeFindDialog() {
        showFindWindow = false
        isFindBarVisible = false
        isReplaceBarVisible = false
        NotepadPlusFindWindowController.shared.close()
        searchMatches.removeAll()
        currentMatchIndex = 0
        searchStatusMessage = ""
        findActionSubject.send(.clearHighlights)
        findActionSubject.send(.focusEditor)
    }

    public func closeFindBar() {
        closeFindDialog()
    }

    public func updateSearchMatches() {
        guard (isFindBarVisible || showFindWindow), let doc = activeDocument else {
            searchMatches = []
            currentMatchIndex = 0
            searchStatusMessage = ""
            findActionSubject.send(.clearHighlights)
            return
        }

        let result = SearchEngine.findAll(
            in: doc.content,
            query: searchQuery,
            options: currentSearchOptions,
            selectedRange: doc.selectedRange
        )

        if let err = result.errorMessage {
            searchMatches = []
            currentMatchIndex = 0
            searchStatusMessage = err
            return
        }

        searchMatches = result.matchingRanges
        currentMatchIndex = result.activeIndex

        if searchMatches.isEmpty {
            searchStatusMessage = searchQuery.isEmpty ? "" : "No matches"
        } else {
            searchStatusMessage = "\(currentMatchIndex) of \(searchMatches.count)"
            if currentMatchIndex > 0 && currentMatchIndex <= searchMatches.count {
                findActionSubject.send(.selectMatch(searchMatches[currentMatchIndex - 1]))
            }
        }
    }

    public func findNext() {
        guard let doc = activeDocument, !searchQuery.isEmpty else { return }

        // Record query into search history
        if !searchHistory.contains(searchQuery) {
            searchHistory.insert(searchQuery, at: 0)
            if searchHistory.count > 25 { searchHistory.removeLast() }
        }

        if searchMatches.isEmpty {
            updateSearchMatches()
        }
        guard !searchMatches.isEmpty else { return }

        if searchBackward {
            findPrevious()
            return
        }

        if let nextIdx = SearchEngine.nextIndex(
            from: doc.selectedRange,
            in: searchMatches,
            wrap: searchWrapAround
        ) {
            currentMatchIndex = nextIdx + 1
            searchStatusMessage = "\(currentMatchIndex) of \(searchMatches.count)"
            findActionSubject.send(.selectMatch(searchMatches[nextIdx]))
        }
    }

    public func findPrevious() {
        guard !searchMatches.isEmpty, let doc = activeDocument else { return }

        if let prevIdx = SearchEngine.previousIndex(
            from: doc.selectedRange,
            in: searchMatches,
            wrap: searchWrapAround
        ) {
            currentMatchIndex = prevIdx + 1
            searchStatusMessage = "\(currentMatchIndex) of \(searchMatches.count)"
            findActionSubject.send(.selectMatch(searchMatches[prevIdx]))
        }
    }

    public func performReplace() {
        guard activeDocument != nil, !searchQuery.isEmpty else { return }

        // Record replace query into history
        if !replaceHistory.contains(replaceQuery) {
            replaceHistory.insert(replaceQuery, at: 0)
            if replaceHistory.count > 25 { replaceHistory.removeLast() }
        }

        if searchMatches.isEmpty {
            updateSearchMatches()
        }
        guard !searchMatches.isEmpty,
              currentMatchIndex > 0,
              currentMatchIndex <= searchMatches.count else { return }

        let targetRange = searchMatches[currentMatchIndex - 1]
        let actualReplacement = searchMode == .extended ? SearchEngine.parseExtendedString(replaceQuery) : replaceQuery
        findActionSubject.send(.replaceCurrent(replacement: actualReplacement, range: targetRange))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.findNext()
        }
    }

    public func performReplaceAll() {
        guard !searchQuery.isEmpty, let doc = activeDocument else { return }

        let actualReplacement = searchMode == .extended ? SearchEngine.parseExtendedString(replaceQuery) : replaceQuery
        let (newContent, count, err) = SearchEngine.replaceAll(
            in: doc.content,
            query: searchQuery,
            replacement: actualReplacement,
            options: currentSearchOptions
        )

        if let err = err {
            searchStatusMessage = err
            return
        }

        if count > 0 {
            doc.applyEdit(newContent, actionName: "Replace All")
            editorActionSubject.send(.contentReplacedFromUndoRedo)
            searchStatusMessage = "Replaced \(count) occurrence\(count == 1 ? "" : "s")."
            updateSearchMatches()
            scheduleSessionSave()
        } else {
            searchStatusMessage = "No matches found."
        }
    }

    public func countMatches() {
        guard let doc = activeDocument, !searchQuery.isEmpty else {
            searchStatusMessage = "Count: 0 matches."
            return
        }
        let result = SearchEngine.findAll(in: doc.content, query: searchQuery, options: currentSearchOptions)
        searchStatusMessage = "Count: \(result.totalCount) matches."
    }

    public func findInCurrentDocument() {
        findNext()
    }

    public func findInAllDocuments() {
        guard !searchQuery.isEmpty else { return }
        var allResults: [SearchResultItem] = []
        for doc in documents {
            let docMatches = SearchEngine.findLines(
                in: doc.content,
                fileTitle: doc.title,
                fileURL: doc.fileURL,
                query: searchQuery,
                options: currentSearchOptions
            )
            allResults.append(contentsOf: docMatches)
        }
        self.searchResultsList = allResults
        self.searchResultsSummary = "Search \"\(searchQuery)\" (\(allResults.count) hits in \(Set(allResults.map { $0.fileTitle }).count) documents)"
        self.activeBottomTab = "Search Results"
        self.isBottomPanelVisible = true
        self.searchStatusMessage = "Found \(allResults.count) hits in \(Set(allResults.map { $0.fileTitle }).count) documents."
    }

    public func replaceInAllDocuments() {
        guard !searchQuery.isEmpty else { return }
        var totalCount = 0
        var docCount = 0
        let actualReplacement = searchMode == .extended ? SearchEngine.parseExtendedString(replaceQuery) : replaceQuery

        for doc in documents {
            let (newContent, count, _) = SearchEngine.replaceAll(
                in: doc.content,
                query: searchQuery,
                replacement: actualReplacement,
                options: currentSearchOptions
            )
            if count > 0 {
                doc.applyEdit(newContent, actionName: "Replace in All Documents")
                totalCount += count
                docCount += 1
            }
        }
        self.editorActionSubject.send(.contentReplacedFromUndoRedo)
        self.searchStatusMessage = "Replaced \(totalCount) occurrences across \(docCount) documents."
        scheduleSessionSave()
    }

    public func findInFiles() {
        guard !searchQuery.isEmpty else { return }
        let targetDir = searchDirectory.isEmpty ? terminalWorkingDirectory : searchDirectory
        let results = SearchEngine.findInFiles(
            directory: targetDir,
            filters: searchFilters.isEmpty ? "*.*" : searchFilters,
            query: searchQuery,
            options: currentSearchOptions,
            recursive: searchInSubfolders,
            includeHidden: searchInHiddenFolders
        )
        self.searchResultsList = results
        let fileCount = Set(results.map { $0.fileTitle }).count
        self.searchResultsSummary = "Search in Files \"\(searchQuery)\" (\(results.count) hits in \(fileCount) files)"
        self.activeBottomTab = "Search Results"
        self.isBottomPanelVisible = true
        self.searchStatusMessage = "Found \(results.count) hits in \(fileCount) files."
    }

    public func replaceInFiles() {
        guard !searchQuery.isEmpty else { return }
        let targetDir = searchDirectory.isEmpty ? terminalWorkingDirectory : searchDirectory
        let (files, replacements, err) = SearchEngine.replaceInFiles(
            directory: targetDir,
            filters: searchFilters.isEmpty ? "*.*" : searchFilters,
            query: searchQuery,
            replacement: replaceQuery,
            options: currentSearchOptions,
            recursive: searchInSubfolders,
            includeHidden: searchInHiddenFolders
        )
        if let err = err {
            self.searchStatusMessage = "Error: \(err)"
        } else {
            self.searchStatusMessage = "Replaced \(replacements) occurrences in \(files) files."
            // If any open documents were affected, reload them
            for doc in documents {
                if let url = doc.fileURL, let updatedDisk = try? String(contentsOf: url, encoding: .utf8), updatedDisk != doc.content {
                    doc.applyEdit(updatedDisk, actionName: "Reload from Replace in Files")
                }
            }
            self.editorActionSubject.send(.contentReplacedFromUndoRedo)
        }
    }

    public func findInProjects() {
        let projDir = workspaceRootURL?.path ?? terminalWorkingDirectory
        searchDirectory = projDir
        findInFiles()
    }

    public func replaceInProjects() {
        let projDir = workspaceRootURL?.path ?? terminalWorkingDirectory
        searchDirectory = projDir
        replaceInFiles()
    }

    public func markAll() {
        guard let doc = activeDocument, !searchQuery.isEmpty else { return }
        if markPurgeForSearch {
            doc.marks.removeAll()
        }

        let result = SearchEngine.findAll(in: doc.content, query: searchQuery, options: currentSearchOptions)
        for range in result.matchingRanges {
            doc.marks.append(TextMark(range: range, colorName: activeMarkColor))
        }

        if markBookmarkLine {
            let lines = SearchEngine.findLines(
                in: doc.content,
                fileTitle: doc.title,
                fileURL: doc.fileURL,
                query: searchQuery,
                options: currentSearchOptions
            )
            for item in lines {
                doc.bookmarks.insert(item.lineNumber)
            }
        }

        self.editorActionSubject.send(.marksChanged)
        self.searchStatusMessage = "Marked \(result.totalCount) occurrences."
    }

    public func copyMarkedText() {
        guard let doc = activeDocument else { return }
        let nsText = doc.content as NSString
        var extracted: [String] = []
        for mark in doc.marks {
            if mark.location + mark.length <= nsText.length {
                extracted.append(nsText.substring(with: mark.range))
            }
        }
        if extracted.isEmpty && !doc.bookmarks.isEmpty {
            let lines = doc.content.components(separatedBy: "\n")
            for b in doc.bookmarks.sorted() {
                if b > 0 && b <= lines.count {
                    extracted.append(lines[b - 1])
                }
            }
        }
        let combined = extracted.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(combined, forType: .string)
        self.searchStatusMessage = "Copied \(extracted.count) marked items to clipboard."
    }

    public func jumpToSearchResult(_ item: SearchResultItem) {
        if let url = item.fileURL {
            if let existing = documents.first(where: { $0.fileURL?.path == url.path }) {
                activeDocumentId = existing.id
                existing.cursorLine = item.lineNumber
                existing.selectedRange = item.matchRange
                findActionSubject.send(.selectMatch(item.matchRange))
                findActionSubject.send(.focusEditor)
            } else {
                if let opened = try? openFileFromURL(url) {
                    opened.cursorLine = item.lineNumber
                    opened.selectedRange = item.matchRange
                    findActionSubject.send(.selectMatch(item.matchRange))
                    findActionSubject.send(.focusEditor)
                }
            }
        } else if let active = activeDocument {
            active.cursorLine = item.lineNumber
            active.selectedRange = item.matchRange
            findActionSubject.send(.selectMatch(item.matchRange))
            findActionSubject.send(.focusEditor)
        }
    }

    // MARK: - Line Editing Operations (Recorded in Undo Stack)
    public func duplicateCurrentLine() {
        guard let doc = activeDocument else { return }
        let lines = doc.content.components(separatedBy: "\n")
        guard !lines.isEmpty else { return }
        let targetIdx = max(0, min(doc.cursorLine - 1, lines.count - 1))
        let savedLine = doc.cursorLine
        let savedCol = doc.cursorColumn
        var newLines = lines
        newLines.insert(lines[targetIdx], at: targetIdx + 1)
        let newContent = newLines.joined(separator: "\n")
        let newLoc = doc.characterIndex(forLine: savedLine, column: savedCol, in: newContent)
        doc.applyEdit(newContent, newSelectedRange: NSRange(location: newLoc, length: 0), actionName: "Duplicate Line")
        doc.cursorLine = savedLine
        doc.cursorColumn = savedCol
        scheduleSessionSave()
    }

    public func deleteCurrentLine() {
        guard let doc = activeDocument else { return }
        var lines = doc.content.components(separatedBy: "\n")
        if lines.count > 1 {
            let targetIdx = max(0, min(doc.cursorLine - 1, lines.count - 1))
            lines.remove(at: targetIdx)
            let newContent = lines.joined(separator: "\n")
            let newLine = max(1, min(doc.cursorLine, lines.count))
            let newLoc = doc.characterIndex(forLine: newLine, column: doc.cursorColumn, in: newContent)
            doc.applyEdit(newContent, newSelectedRange: NSRange(location: newLoc, length: 0), actionName: "Delete Line")
            doc.cursorLine = newLine
        } else {
            doc.applyEdit("", newSelectedRange: NSRange(location: 0, length: 0), actionName: "Delete Line")
            doc.cursorLine = 1
            doc.cursorColumn = 1
        }
        scheduleSessionSave()
    }

    public func joinLines() {
        guard let doc = activeDocument else { return }
        var lines = doc.content.components(separatedBy: "\n")
        let targetIdx = max(0, min(doc.cursorLine - 1, lines.count - 1))
        if targetIdx < lines.count - 1 {
            let savedLine = doc.cursorLine
            let savedCol = doc.cursorColumn
            lines[targetIdx] = lines[targetIdx] + " " + lines[targetIdx + 1].trimmingCharacters(in: .whitespaces)
            lines.remove(at: targetIdx + 1)
            let newContent = lines.joined(separator: "\n")
            let newLoc = doc.characterIndex(forLine: savedLine, column: savedCol, in: newContent)
            doc.applyEdit(newContent, newSelectedRange: NSRange(location: newLoc, length: 0), actionName: "Join Lines")
            doc.cursorLine = savedLine
            scheduleSessionSave()
        }
    }

    public func toggleComment() {
        guard let doc = activeDocument else { return }
        var lines = doc.content.components(separatedBy: "\n")
        guard !lines.isEmpty else { return }
        let targetIdx = max(0, min(doc.cursorLine - 1, lines.count - 1))
        let savedLine = doc.cursorLine
        let savedCol = doc.cursorColumn
        let line = lines[targetIdx]
        let prefix = (doc.language == "Python" || doc.language == "Shell" || doc.language == "Properties" || doc.language == "YAML") ? "# " : "// "
        let trimmedPrefix = prefix.trimmingCharacters(in: .whitespaces)

        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        if trimmedLine.hasPrefix(prefix) {
            if let range = line.range(of: prefix) {
                var modified = line
                modified.removeSubrange(range)
                lines[targetIdx] = modified
            }
        } else if trimmedLine.hasPrefix(trimmedPrefix) {
            if let range = line.range(of: trimmedPrefix) {
                var modified = line
                modified.removeSubrange(range)
                lines[targetIdx] = modified
            }
        } else {
            lines[targetIdx] = prefix + line
        }
        let newContent = lines.joined(separator: "\n")
        let newLoc = doc.characterIndex(forLine: savedLine, column: savedCol, in: newContent)
        doc.applyEdit(newContent, newSelectedRange: NSRange(location: newLoc, length: 0), actionName: "Toggle Comment")
        doc.cursorLine = savedLine
        scheduleSessionSave()
    }

    // MARK: - Bookmarks Navigation
    public func toggleBookmark(at line: Int? = nil) {
        guard let doc = activeDocument else { return }
        let targetLine = line ?? doc.cursorLine
        doc.toggleBookmark(targetLine)
        scheduleSessionSave()
    }

    public func nextBookmark() {
        guard let doc = activeDocument, !doc.bookmarks.isEmpty else { return }
        let sorted = doc.bookmarks.sorted()
        if let next = sorted.first(where: { $0 > doc.cursorLine }) {
            doc.cursorLine = next
        } else {
            doc.cursorLine = sorted[0]
        }
    }

    public func prevBookmark() {
        guard let doc = activeDocument, !doc.bookmarks.isEmpty else { return }
        let sorted = doc.bookmarks.sorted(by: >)
        if let prev = sorted.first(where: { $0 < doc.cursorLine }) {
            doc.cursorLine = prev
        } else {
            doc.cursorLine = sorted[0]
        }
    }

    public func clearBookmarks() {
        guard let doc = activeDocument else { return }
        doc.bookmarks.removeAll()
        scheduleSessionSave()
    }

    // MARK: - Base64 Encoding & Decoding (Plugins)
    public func base64EncodeSelectionOrDocument() {
        guard let doc = activeDocument else { return }
        let text = doc.content as NSString
        let sel = doc.selectedRange

        if sel.length > 0 && sel.location + sel.length <= text.length {
            let selectedText = text.substring(with: sel)
            let encoded = Data(selectedText.utf8).base64EncodedString()
            let newText = text.replacingCharacters(in: sel, with: encoded)
            let newRange = NSRange(location: sel.location, length: (encoded as NSString).length)
            doc.applyEdit(newText, newSelectedRange: newRange, actionName: "Base64 Encode")
        } else {
            let encoded = Data(doc.content.utf8).base64EncodedString()
            doc.applyEdit(encoded, newSelectedRange: NSRange(location: (encoded as NSString).length, length: 0), actionName: "Base64 Encode")
        }
        self.editorActionSubject.send(.contentReplacedFromUndoRedo)
        scheduleSessionSave()
    }

    public func base64DecodeSelectionOrDocument() {
        guard let doc = activeDocument else { return }
        let text = doc.content as NSString
        let sel = doc.selectedRange

        let rawTarget: String
        let isSelection = sel.length > 0 && sel.location + sel.length <= text.length
        if isSelection {
            rawTarget = text.substring(with: sel)
        } else {
            rawTarget = doc.content
        }

        let cleaned = rawTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data(base64Encoded: cleaned, options: [.ignoreUnknownCharacters]),
              let decodedString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            let alert = NSAlert()
            alert.messageText = "Base64 Decode Failed"
            alert.informativeText = "The input text is not valid Base64 encoded data."
            alert.alertStyle = .warning
            alert.runModal()
            return
        }

        if isSelection {
            let newText = text.replacingCharacters(in: sel, with: decodedString)
            let newRange = NSRange(location: sel.location, length: (decodedString as NSString).length)
            doc.applyEdit(newText, newSelectedRange: newRange, actionName: "Base64 Decode")
        } else {
            doc.applyEdit(decodedString, newSelectedRange: NSRange(location: (decodedString as NSString).length, length: 0), actionName: "Base64 Decode")
        }
        self.editorActionSubject.send(.contentReplacedFromUndoRedo)
        scheduleSessionSave()
    }

    // MARK: - Web Browser Integration for HTML
    public func openActiveDocumentInBrowser() {
        guard let doc = activeDocument else { return }
        let stagingDir = storageDirectoryURL.appendingPathComponent("RunStaging", isDirectory: true)
        try? FileManager.default.createDirectory(at: stagingDir, withIntermediateDirectories: true)
        let safeName = (doc.title.hasSuffix(".html") || doc.title.hasSuffix(".htm")) ? doc.title : "\(doc.title).html"
        let targetURL = (doc.fileURL != nil && !doc.isModified) ? doc.fileURL! : stagingDir.appendingPathComponent(safeName)
        if doc.fileURL == nil || doc.isModified {
            try? doc.content.write(to: targetURL, atomically: true, encoding: .utf8)
        }
        NSWorkspace.shared.open(targetURL)
        terminalOutput.append("[HTML] Opened \(doc.title) in default web browser.")
    }

    // MARK: - Split View & Side-by-Side Editing
    public func splitVertically() {
        if isSplitViewActive { return }
        isSplitViewActive = true
        if leftDocumentIds.isEmpty {
            leftDocumentIds = documents.map(\.id)
        }
        let originalLeftActiveId = activeDocumentId ?? leftDocumentIds.first

        if rightDocumentIds.isEmpty {
            if leftDocumentIds.count > 1 {
                if let targetForRight = leftDocumentIds.first(where: { $0 != originalLeftActiveId }) {
                    leftDocumentIds.removeAll(where: { $0 == targetForRight })
                    rightDocumentIds = [targetForRight]
                }
            } else {
                let newDoc = createNewDocument(pane: .right)
                rightActiveDocumentId = newDoc.id
                rightDocumentId = newDoc.id
            }
        }
        leftActiveDocumentId = leftDocumentIds.contains(originalLeftActiveId ?? UUID()) ? originalLeftActiveId : leftDocumentIds.first
        rightActiveDocumentId = rightDocumentIds.first
        leftDocumentId = leftActiveDocumentId
        rightDocumentId = rightActiveDocumentId
        activePane = .left
        activeDocumentId = leftActiveDocumentId
        scheduleSessionSave()
    }

    public func closeSplitView() {
        closeRightPane()
    }

    public func closeLeftPane() {
        guard isSplitViewActive else { return }
        let docsToMove = leftDocumentIds.filter { !rightDocumentIds.contains($0) }
        rightDocumentIds = docsToMove + rightDocumentIds
        leftDocumentIds = rightDocumentIds
        rightDocumentIds.removeAll()
        isSplitViewActive = false
        clearComparison()
        activePane = .left
        leftActiveDocumentId = leftDocumentIds.first
        leftDocumentId = leftActiveDocumentId
        activeDocumentId = leftActiveDocumentId
        scheduleSessionSave()
    }

    public func closeRightPane() {
        guard isSplitViewActive else { return }
        let docsToMove = rightDocumentIds.filter { !leftDocumentIds.contains($0) }
        leftDocumentIds.append(contentsOf: docsToMove)
        rightDocumentIds.removeAll()
        isSplitViewActive = false
        clearComparison()
        activePane = .left
        activeDocumentId = leftActiveDocumentId ?? leftDocumentIds.first
        leftDocumentId = activeDocumentId
        scheduleSessionSave()
    }

    public func swapPanes() {
        guard isSplitViewActive else { return }
        let tempIds = leftDocumentIds
        leftDocumentIds = rightDocumentIds
        rightDocumentIds = tempIds

        let tempActive = leftActiveDocumentId
        leftActiveDocumentId = rightActiveDocumentId
        rightActiveDocumentId = tempActive

        leftDocumentId = leftActiveDocumentId
        rightDocumentId = rightActiveDocumentId

        activePane = (activePane == .left) ? .right : .left
        activeDocumentId = (activePane == .left) ? leftDocumentId : rightDocumentId

        if isComparing {
            recompare()
        }
        scheduleSessionSave()
    }

    public func moveTabToRightPane(docId: UUID? = nil) {
        guard isSplitViewActive else { return }
        let targetId = docId ?? leftActiveDocumentId ?? leftDocumentId
        guard let id = targetId, leftDocumentIds.contains(id) else { return }
        moveDocument(id: id, to: .right)
    }

    public func moveTabToLeftPane(docId: UUID? = nil) {
        guard isSplitViewActive else { return }
        let targetId = docId ?? rightActiveDocumentId ?? rightDocumentId
        guard let id = targetId, rightDocumentIds.contains(id) else { return }
        moveDocument(id: id, to: .left)
    }

    public func moveDocument(id: UUID, to targetPane: EditorPaneSide, targetIndex: Int? = nil) {
        leftDocumentIds.removeAll(where: { $0 == id })
        rightDocumentIds.removeAll(where: { $0 == id })

        if targetPane == .left {
            if let idx = targetIndex, idx >= 0, idx <= leftDocumentIds.count {
                leftDocumentIds.insert(id, at: idx)
            } else {
                leftDocumentIds.append(id)
            }
            leftActiveDocumentId = id
            leftDocumentId = id
            if rightActiveDocumentId == id || rightActiveDocumentId == nil {
                rightActiveDocumentId = rightDocumentIds.first
                rightDocumentId = rightActiveDocumentId
            }
        } else {
            if let idx = targetIndex, idx >= 0, idx <= rightDocumentIds.count {
                rightDocumentIds.insert(id, at: idx)
            } else {
                rightDocumentIds.append(id)
            }
            rightActiveDocumentId = id
            rightDocumentId = id
            if leftActiveDocumentId == id || leftActiveDocumentId == nil {
                leftActiveDocumentId = leftDocumentIds.first
                leftDocumentId = leftActiveDocumentId
            }
        }

        activePane = targetPane
        activeDocumentId = id
        scheduleSessionSave()
    }

    @discardableResult
    public func openFileInPane(url: URL, pane: EditorPaneSide) -> EditorDocument? {
        do {
            let doc = try openFileFromURL(url)
            if isSplitViewActive {
                if pane == .left {
                    if !leftDocumentIds.contains(doc.id) {
                        rightDocumentIds.removeAll(where: { $0 == doc.id })
                        leftDocumentIds.append(doc.id)
                    }
                    leftActiveDocumentId = doc.id
                    leftDocumentId = doc.id
                } else {
                    if !rightDocumentIds.contains(doc.id) {
                        leftDocumentIds.removeAll(where: { $0 == doc.id })
                        rightDocumentIds.append(doc.id)
                    }
                    rightActiveDocumentId = doc.id
                    rightDocumentId = doc.id
                }
                activePane = pane
                activeDocumentId = doc.id
            } else {
                if !leftDocumentIds.contains(doc.id) {
                    leftDocumentIds.append(doc.id)
                }
                leftActiveDocumentId = doc.id
                leftDocumentId = doc.id
                activeDocumentId = doc.id
            }
            scheduleSessionSave()
            return doc
        } catch {
            return nil
        }
    }

    public func reorderDocument(id: UUID, toIndex: Int) {
        guard let currentIdx = documents.firstIndex(where: { $0.id == id }) else { return }
        let doc = documents.remove(at: currentIdx)
        let clampedIdx = min(max(toIndex, 0), documents.count)
        documents.insert(doc, at: clampedIdx)
        if !isSplitViewActive {
            leftDocumentIds = documents.map(\.id)
            leftActiveDocumentId = id
            leftDocumentId = id
            activeDocumentId = id
        }
        scheduleSessionSave()
    }

    public func splitWithDocument(id: UUID, to pane: EditorPaneSide = .right) {
        guard let _ = documents.first(where: { $0.id == id }) else { return }
        if !isSplitViewActive {
            isSplitViewActive = true
            var newLeft = documents.map(\.id).filter { $0 != id }
            if newLeft.isEmpty {
                let newLeftDoc = createNewDocument(pane: .left)
                newLeft = [newLeftDoc.id]
            }
            leftDocumentIds = newLeft
            rightDocumentIds = [id]
            leftActiveDocumentId = leftDocumentIds.first
            leftDocumentId = leftActiveDocumentId
            rightActiveDocumentId = id
            rightDocumentId = id
            activePane = pane
            activeDocumentId = id
        } else {
            moveDocument(id: id, to: pane)
        }
        scheduleSessionSave()
    }

    public func splitWithFileURL(_ url: URL, to pane: EditorPaneSide = .right) {
        do {
            let doc = try openFileFromURL(url)
            splitWithDocument(id: doc.id, to: pane)
        } catch {
            EditorDiagnostics.log("Failed to split with file URL: \(error)")
        }
    }

    public func toggleSynchronizedScrolling() {
        isSynchronizedScrollingEnabled.toggle()
    }

    public func openInOtherPane(doc: EditorDocument) {
        if !isSplitViewActive {
            splitVertically()
            moveDocument(id: doc.id, to: .right)
        } else {
            let targetPane: EditorPaneSide = (activePane == .left) ? .right : .left
            moveDocument(id: doc.id, to: targetPane)
        }
        if isComparing {
            recompare()
        }
        scheduleSessionSave()
    }

    // MARK: - Notepad++ Style File Comparison
    public func selectFirstToCompare(doc: EditorDocument? = nil) {
        let target = doc ?? activeDocument
        guard let target = target else { return }
        firstComparisonDocId = target.id
    }

    public func compareWithSelected(doc: EditorDocument? = nil) {
        let secondDoc = doc ?? activeDocument
        guard let firstId = firstComparisonDocId,
              let firstDoc = documents.first(where: { $0.id == firstId }),
              let second = secondDoc,
              firstDoc.id != second.id else {
            return
        }
        compareDocuments(left: firstDoc, right: second)
    }

    public func compareWithOtherPane() {
        guard isSplitViewActive, let left = leftDocument, let right = rightDocument, left.id != right.id else {
            return
        }
        compareDocuments(left: left, right: right)
    }

    public func compareDocuments(left: EditorDocument, right: EditorDocument) {
        isSplitViewActive = true
        if !leftDocumentIds.contains(left.id) {
            rightDocumentIds.removeAll(where: { $0 == left.id })
            leftDocumentIds.append(left.id)
        }
        if !rightDocumentIds.contains(right.id) {
            leftDocumentIds.removeAll(where: { $0 == right.id })
            rightDocumentIds.append(right.id)
        }
        leftActiveDocumentId = left.id
        rightActiveDocumentId = right.id
        leftDocumentId = left.id
        rightDocumentId = right.id
        activePane = .left
        activeDocumentId = left.id
        isComparing = true

        let diff = FileComparisonService.compare(leftText: left.content, rightText: right.content)
        self.comparisonResult = diff
        self.firstComparisonDocId = nil

        editorActionSubject.send(.diffUpdated)
        if let firstChunk = diff.chunks.first {
            editorActionSubject.send(.scrollToDifference(firstChunk))
        }
        scheduleSessionSave()
    }

    public func recompare() {
        guard isComparing, let left = leftDocument, let right = rightDocument else { return }
        let oldIdx = comparisonResult?.activeChunkIndex ?? 0
        var diff = FileComparisonService.compare(leftText: left.content, rightText: right.content)
        if !diff.chunks.isEmpty {
            diff.activeChunkIndex = min(oldIdx, diff.chunks.count - 1)
        }
        self.comparisonResult = diff
        editorActionSubject.send(.diffUpdated)
    }

    public func clearComparison() {
        isComparing = false
        comparisonResult = nil
        firstComparisonDocId = nil
        editorActionSubject.send(.diffUpdated)
    }

    public func nextDifference() {
        guard isComparing, var diff = comparisonResult, !diff.chunks.isEmpty else { return }
        var nextIdx = diff.activeChunkIndex + 1
        if nextIdx >= diff.chunks.count {
            nextIdx = 0
        }
        diff.activeChunkIndex = nextIdx
        self.comparisonResult = diff
        editorActionSubject.send(.diffUpdated)
        if let chunk = diff.activeChunk {
            editorActionSubject.send(.scrollToDifference(chunk))
        }
    }

    public func previousDifference() {
        guard isComparing, var diff = comparisonResult, !diff.chunks.isEmpty else { return }
        var prevIdx = diff.activeChunkIndex - 1
        if prevIdx < 0 {
            prevIdx = diff.chunks.count - 1
        }
        diff.activeChunkIndex = prevIdx
        self.comparisonResult = diff
        editorActionSubject.send(.diffUpdated)
        if let chunk = diff.activeChunk {
            editorActionSubject.send(.scrollToDifference(chunk))
        }
    }

    public func firstDifference() {
        guard isComparing, var diff = comparisonResult, !diff.chunks.isEmpty else { return }
        diff.activeChunkIndex = 0
        self.comparisonResult = diff
        editorActionSubject.send(.diffUpdated)
        if let chunk = diff.activeChunk {
            editorActionSubject.send(.scrollToDifference(chunk))
        }
    }

    public func lastDifference() {
        guard isComparing, var diff = comparisonResult, !diff.chunks.isEmpty else { return }
        diff.activeChunkIndex = diff.chunks.count - 1
        self.comparisonResult = diff
        editorActionSubject.send(.diffUpdated)
        if let chunk = diff.activeChunk {
            editorActionSubject.send(.scrollToDifference(chunk))
        }
    }

    public func compareFilesFromDisk() {
        let panel1 = NSOpenPanel()
        panel1.title = "Select First File to Compare"
        panel1.prompt = "Choose First File"
        panel1.allowsMultipleSelection = false
        panel1.canChooseFiles = true
        panel1.canChooseDirectories = false
        if panel1.runModal() == .OK, let url1 = panel1.url {
            let panel2 = NSOpenPanel()
            panel2.title = "Select Second File to Compare"
            panel2.prompt = "Compare"
            panel2.allowsMultipleSelection = false
            panel2.canChooseFiles = true
            panel2.canChooseDirectories = false
            if panel2.runModal() == .OK, let url2 = panel2.url {
                do {
                    let doc1 = try openFileFromURL(url1)
                    let doc2 = try openFileFromURL(url2)
                    compareDocuments(left: doc1, right: doc2)
                } catch {
                    let alert = NSAlert()
                    alert.messageText = "Failed to Open Files for Comparison"
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            }
        }
    }
}
