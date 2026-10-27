import SwiftUI
import AppKit

// MARK: - Language Icon & Color Helpers
func languageSymbol(for language: String) -> String {
    switch language.lowercased() {
    case "java", "gradle": return "cup.and.saucer.fill"
    case "swift": return "swift"
    case "python": return "chevron.left.forwardslash.chevron.right"
    case "typescript", "javascript": return "curlybraces"
    case "json", "xml", "yaml", "html", "css": return "curlybraces"
    case "shell", "bash", "zsh": return "terminal"
    case "sql": return "cylinder.split.1x2"
    case "markdown": return "text.quote"
    case "c", "c++", "c#", "rust", "go": return "hammer"
    case "log": return "doc.plaintext"
    default: return "doc.text"
    }
}

func languageColor(for language: String) -> Color {
    switch language.lowercased() {
    case "java": return Color(red: 0.85, green: 0.45, blue: 0.15)
    case "swift": return Color(red: 0.95, green: 0.35, blue: 0.15)
    case "python": return Color.blue
    case "typescript": return Color.blue
    case "javascript": return Color.orange
    case "shell", "bash", "zsh": return Color.green
    case "json", "xml", "html", "css": return Color.purple
    case "rust", "c", "c++", "c#": return Color.red
    case "sql": return Color.teal
    default: return Color.secondary
    }
}

// MARK: - Document Tab Bar View
public struct DocumentTabBar: View {
    @ObservedObject var appState: AppStateManager

    public var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(Array(appState.documents.enumerated()), id: \.element.id) { idx, doc in
                        // Drop insertion line before tab
                        if appState.dragTargetPane == nil && appState.dragTargetIndex == idx {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: 3, height: 26)
                        }

                        DocumentTabItem(doc: doc, index: idx, appState: appState)
                    }

                    // Drop insertion line at end
                    if appState.dragTargetPane == nil && appState.dragTargetIndex == appState.documents.count {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 3, height: 26)
                    }

                    // Plus button for new document
                    Button(action: { appState.createNewDocument() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("New Tab (⌘N)")
                    .padding(.leading, 4)
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                }
                .padding(.leading, 6)
                .padding(.trailing, 8)
                .padding(.top, 4)
            }
            .onDrop(of: ["public.file-url", "public.text"], isTargeted: Binding(
                get: { appState.dragTargetPane == nil && appState.dragTargetIndex == appState.documents.count },
                set: { targeted in
                    if targeted {
                        appState.dragTargetPane = nil
                        appState.dragTargetIndex = appState.documents.count
                    } else if appState.dragTargetPane == nil && appState.dragTargetIndex == appState.documents.count {
                        appState.dragTargetIndex = nil
                    }
                }
            )) { providers in
                if let draggingId = appState.draggingDocumentId {
                    appState.reorderDocument(id: draggingId, toIndex: appState.documents.count)
                    appState.draggingDocumentId = nil
                    appState.dragTargetIndex = nil
                    return true
                }
                return appState.openDroppedProviders(providers)
            }

            Spacer(minLength: 0)
        }
        .frame(height: 32)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(Divider(), alignment: .bottom)
    }
}

// MARK: - Individual Tab Item (Macro-free)
public struct DocumentTabItem: View {
    @ObservedObject var doc: EditorDocument
    let index: Int
    @ObservedObject var appState: AppStateManager

    public init(doc: EditorDocument, index: Int, appState: AppStateManager) {
        self.doc = doc
        self.index = index
        self.appState = appState
    }

    var isActive: Bool {
        doc.id == appState.activeDocumentId
    }

    var isHovering: Bool {
        appState.hoveredDocumentId == doc.id
    }

    public var body: some View {
        HStack(spacing: 6) {
            // Language Icon (SF Symbol)
            Image(systemName: languageSymbol(for: doc.language))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(languageColor(for: doc.language))

            // File Title
            Text(doc.title)
                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .primary : .secondary)
                .lineLimit(1)

            // Modified / Dirty Dot Indicator
            if doc.isModified {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                    .help("Unsaved changes")
            }

            // Close Tab Button
            Button(action: {
                appState.closeDocument(id: doc.id)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(isHovering || isActive ? .primary : .secondary.opacity(0.6))
                    .frame(width: 14, height: 14)
                    .background(isHovering ? Color(NSColor.separatorColor).opacity(0.3) : Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Close (⌘W)")
            .onHover { inside in
                if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(
            isActive
                ? Color(NSColor.textBackgroundColor)
                : (isHovering ? Color(NSColor.controlBackgroundColor) : Color(NSColor.windowBackgroundColor).opacity(0.6))
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
        )
        .overlay(
            VStack(spacing: 0) {
                if isActive {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 2.5)
                }
                Spacer()
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(isActive ? Color(NSColor.separatorColor).opacity(0.6) : Color.clear, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                appState.hoveredDocumentId = doc.id
                NSCursor.pointingHand.push()
            } else {
                if appState.hoveredDocumentId == doc.id {
                    appState.hoveredDocumentId = nil
                }
                NSCursor.pop()
            }
        }
        .onTapGesture {
            appState.activeDocumentId = doc.id
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        .onDrag {
            appState.draggingDocumentId = doc.id
            return NSItemProvider(object: doc.id.uuidString as NSString)
        }
        .onDrop(of: ["public.file-url", "public.text"], isTargeted: Binding(
            get: { appState.dragTargetPane == nil && appState.dragTargetIndex == index },
            set: { targeted in
                if targeted {
                    appState.dragTargetPane = nil
                    appState.dragTargetIndex = index
                } else if appState.dragTargetPane == nil && appState.dragTargetIndex == index {
                    appState.dragTargetIndex = nil
                }
            }
        )) { providers in
            if let draggingId = appState.draggingDocumentId {
                appState.reorderDocument(id: draggingId, toIndex: index)
                appState.draggingDocumentId = nil
                appState.dragTargetIndex = nil
                return true
            }
            return appState.openDroppedProviders(providers)
        }
        .contextMenu {
            Button("Close Tab") {
                appState.closeDocument(id: doc.id)
            }
            Button("Close Other Tabs") {
                let otherIds = appState.documents.map(\.id).filter { $0 != doc.id }
                for oId in otherIds {
                    _ = appState.closeDocument(id: oId)
                }
            }
            Divider()
            Button("Split to Right") {
                appState.splitWithDocument(id: doc.id, to: .right)
            }
            Divider()
            Button("Copy Full Path") {
                if let path = doc.fileURL?.path {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(path, forType: .string)
                }
            }
            .disabled(doc.fileURL == nil)
            Button("Open in Terminal") {
                if let dir = doc.fileURL?.deletingLastPathComponent().path {
                    _ = appState.changeTerminalDirectory(to: dir)
                    appState.showTerminal = true
                }
            }
            .disabled(doc.fileURL == nil)
        }
    }
}

// MARK: - Active Document Undo & Redo Toolbar Controls
public struct ActiveDocumentUndoRedoButtons: View {
    @ObservedObject var appState: AppStateManager
    @ObservedObject var doc: EditorDocument

    public var body: some View {
        HStack(spacing: 8) {
            Button(action: { appState.undoActiveDocument() }) {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!doc.canUndo)
            .help("Undo (⌘Z)")

            Button(action: { appState.redoActiveDocument() }) {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!doc.canRedo)
            .help("Redo (⇧⌘Z)")
        }
    }
}

// MARK: - Toolbar Item Button Style with Pointer Cursor & Motion Support (Macro-Free)
public struct ToolbarItemButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isPressed ? Color.accentColor.opacity(0.18) : Color.clear)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.08), value: configuration.isPressed)
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

// MARK: - Quick Action Toolbar View
public struct QuickActionToolbar: View {
    @ObservedObject var appState: AppStateManager

    public var body: some View {
        HStack(spacing: 8) {
            // Sidebar toggle
            Button(action: { withAnimation(.easeInOut(duration: 0.15)) { appState.isSidebarVisible.toggle() } }) {
                Image(systemName: "sidebar.left")
                    .foregroundColor(appState.isSidebarVisible ? .accentColor : .primary)
            }
            .help("Sidebar: show or hide the file explorer (⌘B)")
            .accessibilityLabel("Sidebar")
            .accessibilityHint("Show or hide the file explorer")

            Divider().frame(height: 16)

            // File operations
            Button(action: { appState.createNewDocument() }) {
                Image(systemName: "doc.badge.plus")
            }
            .help("New: create a new file (⌘N)")
            .accessibilityLabel("New")
            .accessibilityHint("Create a new file")

            Button(action: { appState.openDocument() }) {
                Image(systemName: "folder")
            }
            .help("Open: open files from disk (⌘O)")
            .accessibilityLabel("Open")
            .accessibilityHint("Open files from disk")

            Button(action: { appState.saveActiveDocument() }) {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(appState.activeDocument?.isModified == true ? .accentColor : .primary)
            }
            .help("Save: save the current file (⌘S)")
            .accessibilityLabel("Save")
            .accessibilityHint("Save the current file")

            Divider().frame(height: 16)

            // Undo & Redo (Priority 2)
            if let activeDoc = appState.activeDocument {
                ActiveDocumentUndoRedoButtons(appState: appState, doc: activeDoc)
            } else {
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(true)
                    .help("Undo (⌘Z)")

                    Button(action: {}) {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .disabled(true)
                    .help("Redo (⇧⌘Z)")
                }
            }

            Divider().frame(height: 16)

            // Persistent Text Marking Controls
            HStack(spacing: 2) {
                Button(action: { appState.markSelection() }) {
                    Image(systemName: "highlighter")
                        .foregroundColor(markColorSwiftUI(appState.activeMarkColor))
                }
                .help("Highlight: mark the selected text in \(appState.activeMarkColor.lowercased()) (⌘M)")
                .accessibilityLabel("Highlight")
                .accessibilityHint("Highlights the selected text in \(appState.activeMarkColor)")

                Menu {
                    ForEach(MarkPalette.names, id: \.self) { cName in
                        Button(action: { appState.markSelection(colorName: cName) }) {
                            Label {
                                Text(appState.activeMarkColor == cName ? "\(cName)  ✓" : cName)
                            } icon: {
                                Image(nsImage: MarkPalette.swatch(cName))
                            }
                        }
                    }
                    Divider()
                    Button("Remove Highlight from Selection") {
                        appState.removeMarkFromSelection()
                    }
                    Button("Clear All Highlights in Document") {
                        appState.clearAllMarksInActiveDocument()
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(nsImage: MarkPalette.swatch(appState.activeMarkColor, size: 10))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
                .menuStyle(.borderlessButton)
                .frame(width: 34)
                .help("Highlight color: choose Yellow, Green, Pink, Blue or Orange and apply it to the selection")
                .accessibilityLabel("Highlight color")
                .accessibilityValue(appState.activeMarkColor)
                .accessibilityHint("Choose Yellow, Green, Pink, Blue or Orange and apply it to the selection")
            }

            Divider().frame(height: 16)

            // Run File (Priority 4)
            Button(action: { appState.runActiveDocumentInTerminal() }) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                    Text("Run File")
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.18))
                .foregroundColor(.green)
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .help("Run: run the current source file (F5)")
            .accessibilityLabel("Run")
            .accessibilityHint("Run the current source file")
            .onHover { inside in
                if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }

            // Terminal toggle
            Button(action: { withAnimation(.easeInOut(duration: 0.15)) { appState.isBottomPanelVisible.toggle() } }) {
                Image(systemName: "terminal")
                    .foregroundColor(appState.isBottomPanelVisible ? .green : .primary)
            }
            .help("Terminal: show or hide the developer terminal (^`)")
            .accessibilityLabel("Terminal")
            .accessibilityHint("Show or hide the developer terminal")

            // Bookmarks
            Button(action: { appState.nextBookmark() }) {
                Image(systemName: "bookmark")
            }
            .help("Bookmark: jump to the next bookmark (F2)")
            .accessibilityLabel("Bookmark")
            .accessibilityHint("Jump to the next bookmark")

            // Word Wrap Toggle (⌥Z)
            Button(action: { appState.wordWrap.toggle() }) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.turn.down.right")
                    if appState.wordWrap {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                    }
                }
                .foregroundColor(appState.wordWrap ? .accentColor : .secondary)
            }
            .help(appState.wordWrap ? "Word Wrap: on, click to turn off (⌥Z)" : "Word Wrap: off, click to turn on (⌥Z)")
            .accessibilityLabel("Word Wrap")
            .accessibilityValue(appState.wordWrap ? "On" : "Off")

            // Search & Replace Dialog Controls (Retained single Search button)
            Button(action: {
                if appState.showFindWindow && appState.findDialogTab == .find {
                    appState.closeFindDialog()
                } else {
                    appState.openFindDialog(tab: .find)
                }
            }) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(appState.showFindWindow && appState.findDialogTab == .find ? .accentColor : .primary)
            }
            .help("Search: find text in the current file (⌘F)")
            .accessibilityLabel("Search")
            .accessibilityHint("Find text in the current file")

            Button(action: {
                if appState.showFindWindow && appState.findDialogTab == .replace {
                    appState.closeFindDialog()
                } else {
                    appState.openFindDialog(tab: .replace)
                }
            }) {
                Image(systemName: "arrow.triangle.swap")
                    .foregroundColor(appState.showFindWindow && appState.findDialogTab == .replace ? .accentColor : .primary)
            }
            .help("Replace: find and replace text (⌘H)")
            .accessibilityLabel("Replace")
            .accessibilityHint("Find and replace text")

            Divider().frame(height: 16)

            // Split View Toggle
            Button(action: {
                if appState.isSplitViewActive {
                    appState.closeSplitView()
                } else {
                    appState.splitVertically()
                }
            }) {
                Image(systemName: "square.split.2x1")
                    .foregroundColor(appState.isSplitViewActive ? .accentColor : .primary)
            }
            .help(appState.isSplitViewActive ? "Split: close the split view (⇧⌥⌘S)" : "Split: view two files side by side (⌥⌘S)")
            .accessibilityLabel("Split View")
            .accessibilityValue(appState.isSplitViewActive ? "Active" : "Off")

            // Compare Files Menu
            Menu {
                Button("Compare Open Panes") {
                    appState.compareWithOtherPane()
                }
                .disabled(!appState.isSplitViewActive || appState.leftDocumentId == appState.rightDocumentId)

                Button("Select First to Compare") {
                    appState.selectFirstToCompare()
                }

                Button("Compare with Selected") {
                    appState.compareWithSelected()
                }
                .disabled(appState.firstComparisonDocId == nil || appState.firstComparisonDocId == appState.activeDocument?.id)

                Divider()

                Button("Compare Files from Disk...") {
                    appState.compareFilesFromDisk()
                }

                if appState.isComparing {
                    Divider()
                    Button("Clear Comparison") {
                        appState.clearComparison()
                    }
                }
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.left.and.right.square")
                        .foregroundColor(appState.isComparing ? .accentColor : .primary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
            .menuStyle(.borderlessButton)
            .help("Compare: compare two files and show differences")
            .accessibilityLabel("Compare")
            .accessibilityHint("Compare two files and show differences")

            Spacer()

            // Active Document Title
            if let doc = appState.activeDocument {
                Text("\(doc.title)\(doc.isModified ? " *" : "") — NPad++")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Font Size Quick Adjust
            HStack(spacing: 4) {
                Button(action: { appState.decreaseFontSize() }) {
                    Image(systemName: "textformat.size.smaller")
                        .font(.system(size: 11))
                }
                .help("Smaller: decrease the font size (⌘-)")
                .accessibilityLabel("Smaller")
                .accessibilityHint("Decrease the font size")

                Text("\(Int(appState.fontSize))pt")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)

                Button(action: { appState.increaseFontSize() }) {
                    Image(systemName: "textformat.size.larger")
                        .font(.system(size: 11))
                }
                .help("Larger: increase the font size (⌘+)")
                .accessibilityLabel("Larger")
                .accessibilityHint("Increase the font size")
            }

            Divider().frame(height: 16)

            // Settings
            Button(action: { appState.showSettingsSheet = true }) {
                Image(systemName: "gearshape")
            }
            .help("Settings: open preferences (⌘,)")
            .accessibilityLabel("Settings")
            .accessibilityHint("Open preferences")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(Divider(), alignment: .bottom)
        .buttonStyle(ToolbarItemButtonStyle())
    }

    private func markColorSwiftUI(_ name: String) -> Color {
        switch name.lowercased() {
        case "green": return .green
        case "blue", "cyan": return .blue
        case "pink": return .pink
        case "orange": return .orange
        default: return .yellow
        }
    }
}

// MARK: - In-Editor Find & Replace Bar View
public struct FindReplaceBarView: View {
    @ObservedObject var appState: AppStateManager

    public var body: some View {
        VStack(spacing: 6) {
            // Find Row
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))

                TextField("Find...", text: $appState.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .onSubmit {
                        appState.findNext()
                    }

                if !appState.searchStatusMessage.isEmpty {
                    Text(appState.searchStatusMessage)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(appState.searchMatches.isEmpty ? .secondary : .accentColor)
                        .padding(.horizontal, 4)
                }

                Button(action: { appState.findPrevious() }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(appState.searchMatches.isEmpty)
                .help("Previous Match (⇧⏎)")

                Button(action: { appState.findNext() }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(appState.searchMatches.isEmpty)
                .help("Next Match (⏎)")

                Divider().frame(height: 16)

                Button(action: { appState.searchCaseSensitive.toggle() }) {
                    Text("Aa")
                        .font(.system(size: 11, weight: appState.searchCaseSensitive ? .bold : .regular))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(appState.searchCaseSensitive ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(3)
                }
                .buttonStyle(.plain)
                .help("Match Case")

                Button(action: { appState.searchWholeWord.toggle() }) {
                    Text("\\bW\\b")
                        .font(.system(size: 10, weight: appState.searchWholeWord ? .bold : .regular, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(appState.searchWholeWord ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(3)
                }
                .buttonStyle(.plain)
                .help("Match Whole Word")

                Button(action: { appState.searchRegex.toggle() }) {
                    Text(".*")
                        .font(.system(size: 11, weight: appState.searchRegex ? .bold : .regular, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(appState.searchRegex ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(3)
                }
                .buttonStyle(.plain)
                .help("Use Regular Expression")

                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { appState.isReplaceBarVisible.toggle() } }) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 11))
                        .foregroundColor(appState.isReplaceBarVisible ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help("Toggle Replace (⌘H)")

                Spacer()

                Button(action: { appState.closeFindBar() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Find Bar (Esc)")
            }

            // Replace Row
            if appState.isReplaceBarVisible {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))

                    TextField("Replace with...", text: $appState.replaceQuery)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .onSubmit {
                            appState.performReplace()
                        }

                    Button("Replace") {
                        appState.performReplace()
                    }
                    .font(.system(size: 11))
                    .disabled(appState.searchMatches.isEmpty)

                    Button("Replace All") {
                        appState.performReplaceAll()
                    }
                    .font(.system(size: 11))
                    .disabled(appState.searchQuery.isEmpty)

                    Spacer()
                }
                .padding(.leading, 20)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(Divider(), alignment: .bottom)
    }
}

// MARK: - Document Sidebar Row View (Observes doc directly for instant updates on rename/save)
public struct DocumentSidebarRow: View {
    @ObservedObject var doc: EditorDocument
    @ObservedObject var appState: AppStateManager

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: languageSymbol(for: doc.language))
                .font(.system(size: 11))
                .foregroundColor(languageColor(for: doc.language))

            Text(doc.title)
                .font(.system(size: 12))
                .lineLimit(1)

            Spacer()

            if doc.isModified {
                Circle().fill(Color.red).frame(width: 6, height: 6)
            }
        }
        .tag(doc.id)
    }
}

// MARK: - Document Sidebar View (Project Explorer + Open Documents + Bookmarks - Macro-free)
public struct DocumentSidebar: View {
    @ObservedObject var appState: AppStateManager

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Hierarchical Project Explorer Section
            ProjectExplorerView(appState: appState)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // 2. Open Documents Section (Collapsible)
            VStack(alignment: .leading, spacing: 0) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        appState.isSidebarDocumentsExpanded.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: appState.isSidebarDocumentsExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("OPEN DOCUMENTS (\(appState.documents.count))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                }
                .buttonStyle(.plain)

                if appState.isSidebarDocumentsExpanded {
                    List(selection: $appState.activeDocumentId) {
                        ForEach(appState.documents, id: \.id) { doc in
                            DocumentSidebarRow(doc: doc, appState: appState)
                        }
                    }
                    .listStyle(.sidebar)
                    .frame(maxHeight: min(CGFloat(max(appState.documents.count, 1) * 28 + 10), 160))
                }
            }

            // 3. Bookmarks Section (Collapsible, shown when document has bookmarks)
            if let doc = appState.activeDocument, !doc.bookmarks.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            appState.isSidebarBookmarksExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: appState.isSidebarBookmarksExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("BOOKMARKS (\(doc.bookmarks.count))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                    }
                    .buttonStyle(.plain)

                    if appState.isSidebarBookmarksExpanded {
                        List(Array(doc.bookmarks).sorted(), id: \.self) { lineNum in
                            Button(action: {
                                doc.cursorLine = lineNum
                            }) {
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 10))
                                    Text("Line \(lineNum)")
                                        .font(.system(size: 11, design: .monospaced))
                                }
                            }
                            .buttonStyle(.plain)
                            .help("Go to bookmarked line \(lineNum)")
                        }
                        .frame(maxHeight: 110)
                    }
                }
            }
        }
        .frame(minWidth: 180, idealWidth: 240, maxWidth: 350)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Bottom Developer Panel View (Macro-free)
public struct BottomDeveloperPanel: View {
    @ObservedObject var appState: AppStateManager

    public var body: some View {
        VStack(spacing: 0) {
            // Header tabs
            HStack(spacing: 12) {
                Button(action: { appState.activeBottomTab = "Terminal" }) {
                    Label("Developer Terminal", systemImage: "terminal")
                        .font(.system(size: 11, weight: appState.activeBottomTab == "Terminal" ? .bold : .regular))
                        .foregroundColor(appState.activeBottomTab == "Terminal" ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)

                Button(action: { appState.activeBottomTab = "Git" }) {
                    Label("Git", systemImage: "arrow.triangle.branch")
                        .font(.system(size: 11, weight: appState.activeBottomTab == "Git" ? .bold : .regular))
                        .foregroundColor(appState.activeBottomTab == "Git" ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)

                Button(action: { appState.activeBottomTab = "Java" }) {
                    Label("Java & Spring Boot", systemImage: "cup.and.saucer")
                        .font(.system(size: 11, weight: appState.activeBottomTab == "Java" ? .bold : .regular))
                        .foregroundColor(appState.activeBottomTab == "Java" ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)

                Button(action: { appState.activeBottomTab = "Search Results" }) {
                    Label(
                        appState.searchResultsList.isEmpty ? "Search Results" : "Search Results (\(appState.searchResultsList.count))",
                        systemImage: "doc.text.magnifyingglass"
                    )
                    .font(.system(size: 11, weight: appState.activeBottomTab == "Search Results" ? .bold : .regular))
                    .foregroundColor(appState.activeBottomTab == "Search Results" ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: { withAnimation { appState.isBottomPanelVisible = false } }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .help("Close: hide the bottom panel")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(Divider(), alignment: .bottom)

            // Content
            if appState.activeBottomTab == "Terminal" {
                VStack(spacing: 0) {
                    // Quick command presets row
                    HStack(spacing: 6) {
                        Text("PRESETS:")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)

                        Group {
                            Button("pwd") {
                                appState.terminalCommand = "pwd"
                                appState.executeTerminalCommand()
                            }
                            Button("ls -la") {
                                appState.terminalCommand = "ls -la"
                                appState.executeTerminalCommand()
                            }
                            Button("cd /tmp") {
                                appState.terminalCommand = "cd /tmp"
                                appState.executeTerminalCommand()
                            }
                            Button("java -version") {
                                appState.terminalCommand = "java -version"
                                appState.executeTerminalCommand()
                            }
                            Button("which java") {
                                appState.terminalCommand = "which java"
                                appState.executeTerminalCommand()
                            }
                            Button("echo test") {
                                appState.terminalCommand = "echo \"Terminal works\""
                                appState.executeTerminalCommand()
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(3)
                        .font(.system(size: 10, design: .monospaced))

                        Spacer()

                        if appState.isTerminalRunning {
                            Button("Cancel") {
                                appState.cancelTerminalCommand()
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(3)
                            .font(.system(size: 10, weight: .semibold))
                        }

                        Button("Clear") {
                            appState.terminalOutput.removeAll()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.windowBackgroundColor))
                    .overlay(Divider(), alignment: .bottom)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(appState.terminalOutput, id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(line.starts(with: "$") ? .green : .primary)
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(NSColor.textBackgroundColor))

                    HStack {
                        let dirName = URL(fileURLWithPath: appState.terminalWorkingDirectory).lastPathComponent
                        Text("\(dirName.isEmpty ? "/" : dirName) ➜")
                            .foregroundColor(.green)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))

                        TextField("Type shell command...", text: $appState.terminalCommand)
                            .font(.system(size: 11, design: .monospaced))
                            .textFieldStyle(.plain)
                            .onSubmit { appState.executeTerminalCommand() }
                            .disabled(appState.isTerminalRunning)

                        Button("Run") { appState.executeTerminalCommand() }
                            .font(.system(size: 11))
                            .disabled(appState.isTerminalRunning)
                    }
                    .padding(6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .overlay(Divider(), alignment: .top)
                }
            } else if appState.activeBottomTab == "Git" {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Git Status")
                        .font(.system(size: 12, weight: .bold))
                    Text("Branch: main")
                        .font(.system(size: 11, design: .monospaced))
                    Text("Changed files in workspace:")
                        .font(.system(size: 11, weight: .semibold))
                    Text("• DemoApplication.java (modified)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if appState.activeBottomTab == "Search Results" {
                VStack(alignment: .leading, spacing: 0) {
                    if !appState.searchResultsSummary.isEmpty {
                        HStack {
                            Text(appState.searchResultsSummary)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Clear Results") {
                                appState.searchResultsList.removeAll()
                                appState.searchResultsSummary = ""
                            }
                            .font(.system(size: 10))
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        Divider()
                    }

                    if appState.searchResultsList.isEmpty {
                        VStack(spacing: 6) {
                            Spacer()
                            Text("No search results to display.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("Use Find in All Documents or Find in Files (⌘F) to search across files.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.8))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(appState.searchResultsList) { item in
                            Button(action: {
                                appState.jumpToSearchResult(item)
                            }) {
                                HStack(spacing: 8) {
                                    Text(item.fileTitle)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.accentColor)
                                        .frame(width: 140, alignment: .leading)

                                    Text("Line \(item.lineNumber):")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 60, alignment: .leading)

                                    Text(item.lineContent)
                                        .font(.system(size: 11, design: .monospaced))
                                        .lineLimit(1)

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.activeBottomTab == "Java" {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Java & Spring Boot Developer Toolkit (Java 8 / 17 / 21+)")
                        .font(.system(size: 12, weight: .bold))
                    Text("Recognized frameworks: Spring Boot 3.x, Maven, Gradle")
                        .font(.system(size: 11))
                    HStack(spacing: 8) {
                        Button("Insert @RestController") {
                            if let doc = appState.activeDocument {
                                doc.content += "\n@RestController\npublic class NewController {\n    @GetMapping(\"/hello\")\n    public String hello() { return \"Hello!\"; }\n}\n"
                            }
                        }
                        Button("Insert Spring Properties") {
                            if let doc = appState.activeDocument {
                                doc.content += "\nserver.port=8080\nspring.application.name=npad-demo\n"
                            }
                        }
                    }
                    Spacer()
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if appState.activeBottomTab == "Search Results" {
                VStack(alignment: .leading, spacing: 0) {
                    if !appState.searchResultsSummary.isEmpty {
                        HStack {
                            Text(appState.searchResultsSummary)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Clear Results") {
                                appState.searchResultsList.removeAll()
                                appState.searchResultsSummary = ""
                            }
                            .font(.system(size: 10))
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        Divider()
                    }

                    if appState.searchResultsList.isEmpty {
                        VStack(spacing: 6) {
                            Spacer()
                            Text("No search results to display.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("Use Find in All Documents or Find in Files (⌘F) to search across files.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.8))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(appState.searchResultsList) { item in
                            Button(action: {
                                appState.jumpToSearchResult(item)
                            }) {
                                HStack(spacing: 8) {
                                    Text(item.fileTitle)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.accentColor)
                                        .frame(width: 140, alignment: .leading)

                                    Text("Line \(item.lineNumber):")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 60, alignment: .leading)

                                    Text(item.lineContent)
                                        .font(.system(size: 11, design: .monospaced))
                                        .lineLimit(1)

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minHeight: 120, idealHeight: 180, maxHeight: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Editor Status Bar View
public struct EditorStatusBar: View {
    @ObservedObject var appState: AppStateManager

    public var body: some View {
        HStack(spacing: 16) {
            if let doc = appState.activeDocument {
                Text("Line \(doc.cursorLine), Column \(doc.cursorColumn)")
                    .font(.system(size: 11, design: .monospaced))

                if doc.selectionLength > 0 {
                    Text("Sel: \(doc.selectionLength) chars")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.orange)
                }

                let linesCount = doc.content.components(separatedBy: "\n").count
                Text("Length: \(linesCount) lines")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Editable (INS)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.green)
                }
                .help("Document editing and text addition are fully enabled")
            }

            Spacer()

            if let doc = appState.activeDocument {
                // Line Ending format
                Menu(doc.lineEnding.rawValue) {
                    ForEach(LineEndingFormat.allCases) { ending in
                        Button(ending.rawValue) {
                            doc.convertLineEndings(to: ending)
                        }
                    }
                }
                .menuStyle(.borderlessButton)
                .font(.system(size: 11, design: .monospaced))

                // Encoding
                Menu(doc.encoding.rawValue) {
                    ForEach(DocumentEncoding.allCases) { enc in
                        Button(enc.rawValue) {
                            doc.encoding = enc
                        }
                    }
                }
                .menuStyle(.borderlessButton)
                .font(.system(size: 11, design: .monospaced))

                // Language Selector (A-Z Dictionary organized)
                Menu(doc.language) {
                    Button("Plain Text") {
                        appState.setLanguageForActiveDocument("Plain Text")
                    }
                    Divider()
                    ForEach(SyntaxEngine.alphabeticalGroups) { group in
                        Menu(group.letter) {
                            ForEach(group.languages, id: \.self) { lang in
                                Button(lang) {
                                    appState.setLanguageForActiveDocument(lang)
                                }
                            }
                        }
                    }
                }
                .menuStyle(.borderlessButton)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }

            // Split View Active Pane Indicator
            if appState.isSplitViewActive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                    Text("\(appState.activePane.rawValue) Pane")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.12))
                .cornerRadius(3)
            }

            // Comparison Status Indicator
            if appState.isComparing, let diff = appState.comparisonResult {
                HStack(spacing: 4) {
                    Image(systemName: "square.split.2x1")
                        .font(.system(size: 9))
                    Text("Diff \(diff.activeChunkIndex + 1)/\(diff.totalDifferences)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.12))
                .cornerRadius(3)
            }

            // Quick Appearance Switcher
            Button(action: {
                switch appState.appearanceMode {
                case .auto, .system: appState.appearanceMode = .light
                case .light: appState.appearanceMode = .dark
                case .dark: appState.appearanceMode = .auto
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: appState.appearanceMode.iconName)
                        .font(.system(size: 10))
                    Text(appState.appearanceMode.rawValue)
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
            .help("Switch Appearance Mode (System / Light / Dark)")

            // Clean Product Badge
            Text("NPad++")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 1.5)
                .background(Color.accentColor.opacity(0.15))
                .foregroundColor(.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(Divider(), alignment: .top)
    }
}

// MARK: - Main Window View
public struct MainWindowView: View {
    @EnvironmentObject var appState: AppStateManager

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Quick Action Toolbar
            QuickActionToolbar(appState: appState)

            // 2. Document Tab Bar (single-pane mode; split view provides per-pane tab bars)
            if !appState.isSplitViewActive {
                DocumentTabBar(appState: appState)
            }

            // 3. Main Workspace: Sidebar + Editor (+ Find Bar) + Bottom Panel
            HStack(spacing: 0) {
                if appState.isSidebarVisible {
                    DocumentSidebar(appState: appState)
                    Divider()
                }

                VStack(spacing: 0) {
                    Group {
                        if appState.isSplitViewActive {
                            SplitEditorContainerView(appState: appState)
                        } else if let doc = appState.activeDocument {
                            SingleEditorContainerView(document: doc, appState: appState)
                                .id(doc.id)
                                .frame(minWidth: 350, maxWidth: .infinity, minHeight: 250, maxHeight: .infinity)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 44))
                                    .foregroundColor(.secondary.opacity(0.6))
                                Text("No Document Open")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Button("Create New Document (⌘N)") {
                                    appState.createNewDocument()
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(NSColor.textBackgroundColor))
                        }
                    }

                    if appState.isBottomPanelVisible {
                        Divider()
                        BottomDeveloperPanel(appState: appState)
                    }
                }
            }

            // 4. Status Bar
            if appState.isStatusBarVisible {
                EditorStatusBar(appState: appState)
            }
        }
        .preferredColorScheme(appState.effectiveColorScheme)
        // Sheet: Go to Line
        .sheet(isPresented: $appState.showGoToLineSheet) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Go to Line").font(.headline)
                TextField("Line number", text: $appState.targetLineNumber)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Spacer()
                    Button("Cancel") { appState.showGoToLineSheet = false }
                    Button("Go") {
                        if let num = Int(appState.targetLineNumber), let doc = appState.activeDocument {
                            doc.cursorLine = num
                        }
                        appState.showGoToLineSheet = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(16)
            .frame(width: 260)
        }
        // Sheet: Preferences
        .sheet(isPresented: $appState.showSettingsSheet) {
            VStack(alignment: .leading, spacing: 16) {
                Text("NPad++ Preferences").font(.headline)

                // Appearance & Theme Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Appearance:").font(.subheadline).bold()
                    Picker("", selection: $appState.appearanceMode) {
                        ForEach(AppAppearanceMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.iconName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                HStack {
                    Text("Editor Theme:").font(.subheadline).bold()
                    Spacer()
                    Picker("", selection: $appState.theme) {
                        ForEach(ThemeManager.allThemeNames, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }

                Divider()

                // Font Family Selector
                VStack(alignment: .leading, spacing: 6) {
                    Text("Editor Font:").font(.subheadline).bold()
                    Picker("", selection: $appState.fontFamily) {
                        ForEach(appState.availableFontFamilies, id: \.self) { fam in
                            Text(fam).tag(fam)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Font Size Adjuster
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Font Size:").font(.subheadline).bold()
                        Spacer()
                        Text("\(Int(appState.fontSize)) pt")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Slider(value: $appState.fontSize, in: 9...32, step: 1)
                        Stepper("", value: $appState.fontSize, in: 9...32, step: 1)
                    }
                }

                // Live Preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview:").font(.caption).foregroundColor(.secondary)
                    HStack {
                        Text("package ")
                            .foregroundColor(appState.isDarkMode ? Color(red: 0.50, green: 0.70, blue: 1.0) : Color(red: 0.05, green: 0.25, blue: 0.78))
                            .bold()
                        + Text("demo;\n")
                            .foregroundColor(appState.isDarkMode ? .white : .black)
                        + Text("public class ")
                            .foregroundColor(appState.isDarkMode ? Color(red: 0.50, green: 0.70, blue: 1.0) : Color(red: 0.05, green: 0.25, blue: 0.78))
                            .bold()
                        + Text("NPadPlusPlus ")
                            .foregroundColor(appState.isDarkMode ? Color(red: 0.45, green: 0.88, blue: 0.85) : Color(red: 0.08, green: 0.52, blue: 0.58))
                            .bold()
                        + Text("{\n    ")
                            .foregroundColor(appState.isDarkMode ? .white : .black)
                        + Text("// High-speed editor\n    ")
                            .foregroundColor(appState.isDarkMode ? Color(red: 0.45, green: 0.78, blue: 0.45) : Color(red: 0.12, green: 0.55, blue: 0.18))
                        + Text("String ")
                            .foregroundColor(appState.isDarkMode ? Color(red: 0.45, green: 0.88, blue: 0.85) : Color(red: 0.08, green: 0.52, blue: 0.58))
                        + Text("msg = ")
                            .foregroundColor(appState.isDarkMode ? .white : .black)
                        + Text("\"Hello, Apple Silicon!\";\n}")
                            .foregroundColor(appState.isDarkMode ? Color(red: 1.0, green: 0.72, blue: 0.45) : Color(red: 0.75, green: 0.22, blue: 0.12))
                    }
                    .font(.custom(appState.fontFamily, size: appState.fontSize))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(appState.isDarkMode ? Color(NSColor(calibratedWhite: 0.12, alpha: 1.0)) : Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }

                Divider()

                // Editor Options
                Toggle("Word Wrap", isOn: $appState.wordWrap)
                Toggle("Show Whitespace Characters", isOn: $appState.showWhitespace)
                Toggle("Show Sidebar", isOn: $appState.isSidebarVisible)

                // Default Highlight Color
                HStack {
                    Text("Highlight Mark Color:")
                    Picker("", selection: $appState.activeMarkColor) {
                        ForEach(MarkPalette.names, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                    .pickerStyle(.menu)
                }

                HStack {
                    Spacer()
                    Button("Done") { appState.showSettingsSheet = false }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(18)
            .frame(width: 420)
        }
        // Native macOS Welcome Window Presentation
        .onAppear {
            if appState.showWelcomeSheet {
                NativeWelcomeWindowController.shared.show(appState: appState, showFeatures: false)
            }
        }
        .onChange(of: appState.showWelcomeSheet) { _, show in
            if show {
                NativeWelcomeWindowController.shared.show(appState: appState, showFeatures: false)
            } else {
                NativeWelcomeWindowController.shared.close()
            }
        }
        // Sheet: Documentation & Support
        .sheet(isPresented: $appState.showDocumentationSheet) {
            DocumentationAndSupportView(appState: appState)
        }
    }
}

// MARK: - AppStateManager Extensions for Real File Operations & Line Editing
extension AppStateManager {
    public func executeTerminalCommand() {
        let cmd = terminalCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }

        terminalCommand = ""

        // Handle 'clear' command
        if cmd == "clear" {
            terminalOutput.removeAll()
            return
        }

        let dirName = URL(fileURLWithPath: terminalWorkingDirectory).lastPathComponent
        terminalOutput.append("[\(dirName.isEmpty ? "/" : dirName)] $ \(cmd)")

        // Handle 'cd' directory changes with working directory persistence
        if cmd == "cd" || cmd.hasPrefix("cd ") {
            let targetArg = cmd == "cd" ? "~" : String(cmd.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            if changeTerminalDirectory(to: targetArg) {
                terminalOutput.append("[Directory: \(terminalWorkingDirectory)]")
            } else {
                terminalOutput.append("cd: no such file or directory: \(targetArg)")
            }
            return
        }

        // Handle other shell commands in background with full environment
        isTerminalRunning = true

        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        // Use login zsh or bash
        let shellPath = FileManager.default.fileExists(atPath: "/bin/zsh") ? "/bin/zsh" : "/bin/bash"
        process.executableURL = URL(fileURLWithPath: shellPath)
        process.arguments = ["-l", "-c", cmd]
        process.currentDirectoryURL = URL(fileURLWithPath: terminalWorkingDirectory)

        // Enrich environment with Homebrew, System, and Java paths
        var env = ProcessInfo.processInfo.environment
        let extraPaths = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        let currentPath = env["PATH"] ?? ""
        env["PATH"] = "\(extraPaths):\(currentPath)"
        env["TERM"] = "xterm-256color"
        process.environment = env

        currentTerminalProcess = process

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                let raw = String(data: data, encoding: .utf8) ?? ""
                let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)

                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isTerminalRunning = false
                    self.currentTerminalProcess = nil

                    if !cleaned.isEmpty {
                        self.terminalOutput.append(cleaned)
                    } else if process.terminationStatus != 0 {
                        self.terminalOutput.append("[Process exited with code \(process.terminationStatus)]")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isTerminalRunning = false
                    self.currentTerminalProcess = nil
                    self.terminalOutput.append("Error executing command: \(error.localizedDescription)")
                }
            }
        }
    }

    public func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.showsHiddenFiles = true
        panel.allowsOtherFileTypes = true
        panel.title = "Open Files"
        if panel.runModal() == .OK {
            openFilesInteractively(panel.urls)
        }
    }

    public func openFilesInteractively(_ urls: [URL]) {
        for url in urls {
            openFileInteractively(url)
        }
    }

    /// Opens a file (or a folder as the project workspace) from a user-facing entry point: the open panel,
    /// drag & drop, Finder "Open With", or the project explorer. Warns before opening binary or very large
    /// files and reports failures instead of silently ignoring them.
    @discardableResult
    public func openFileInteractively(_ url: URL, inPane pane: EditorPaneSide? = nil) -> EditorDocument? {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
            workspaceRootURL = url
            loadProject(from: url)
            scheduleSessionSave()
            return nil
        }
        if let pane = pane {
            return openFileInPane(url: url, pane: pane)
        }
        guard confirmOpenable(url) else { return nil }
        do {
            return try openFileFromURL(url)
        } catch {
            presentOpenError(error, for: url)
            return nil
        }
    }

    /// Returns false when the user declines to open a binary or very large file.
    public func confirmOpenable(_ url: URL) -> Bool {
        if documents.contains(where: { $0.fileURL?.standardizedFileURL == url.standardizedFileURL }) {
            return true
        }

        if FileTypeRegistry.isKnownBinaryExtension(url) {
            let alert = NSAlert()
            alert.messageText = "Cannot Open Binary File"
            alert.informativeText = "'\(url.lastPathComponent)' is a binary or package format and cannot be opened as text.\n\nNPad++ is designed for source code and text files (.java, .py, .swift, .ts, .json, .env, .txt, etc.). Please choose a text or source code file."
            alert.alertStyle = .warning
            alert.runModal()
            return false
        }

        let maxSafeBytes = 100 * 1024 * 1024
        if let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize, size > maxSafeBytes {
            let alert = NSAlert()
            alert.messageText = "Large File"
            alert.informativeText = "'\(url.lastPathComponent)' is \(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)). Opening it may make the editor slow.\n\nDo you want to open it anyway?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "Open Anyway")
            if alert.runModal() != .alertSecondButtonReturn { return false }
        }

        if let handle = try? FileHandle(forReadingFrom: url) {
            defer { try? handle.close() }
            let head = (try? handle.read(upToCount: 8192)) ?? Data()
            if FileTypeRegistry.looksBinary(head) {
                let alert = NSAlert()
                alert.messageText = "Binary Data Detected"
                alert.informativeText = "'\(url.lastPathComponent)' contains binary data and may not display correctly as text.\n\nDo you want to attempt opening anyway?"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Cancel")
                alert.addButton(withTitle: "Open Anyway")
                if alert.runModal() != .alertSecondButtonReturn { return false }
            }
        }
        return true
    }

    public func presentOpenError(_ error: Error, for url: URL) {
        let alert = NSAlert()
        alert.messageText = "Failed to Open \(url.lastPathComponent)"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }

    /// Opens every file URL carried by drag & drop providers (not just the first).
    @discardableResult
    public func openDroppedProviders(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier("public.file-url") {
            handled = true
            _ = provider.loadObject(ofClass: NSURL.self) { item, _ in
                if let url = item as? URL {
                    DispatchQueue.main.async {
                        self.openFileInteractively(url)
                    }
                }
            }
        }
        return handled
    }

    public func saveActiveDocument(saveAs: Bool = false) {
        _ = saveActiveDocumentWithPanelIfNeeded(saveAs: saveAs)
    }

    public func runActiveDocumentInTerminal() {
        guard let doc = activeDocument else { return }
        isBottomPanelVisible = true
        activeBottomTab = "Terminal"

        let plan = buildRunPlan(for: doc)
        if !plan.supported {
            terminalOutput.append("[Run File] \(plan.errorMessage ?? "Unsupported file type.")")
            return
        }

        // For HTML documents, open directly in the default web browser via AppKit NSWorkspace
        if plan.language == "HTML", let targetURL = plan.stagedFileURL {
            NSWorkspace.shared.open(targetURL)
        }

        _ = changeTerminalDirectory(to: plan.workingDirectory)
        terminalOutput.append("[Running \(doc.title) (\(plan.language))]")
        terminalCommand = plan.command
        executeTerminalCommand()
    }
}

// MARK: - Native macOS Menu Commands
public struct FileCommands: Commands {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Document") {
                appState.createNewDocument()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Open...") {
                appState.openDocument()
            }
            .keyboardShortcut("o", modifiers: .command)

            Button("Open Folder...") {
                appState.openFolder()
            }
            .keyboardShortcut("o", modifiers: [.command, .option])

            Button("Close Folder") {
                appState.closeFolder()
            }
            .disabled(appState.workspaceRootURL == nil)

            Divider()

            Button("Save") {
                appState.saveActiveDocument()
            }
            .keyboardShortcut("s", modifiers: .command)

            Button("Save As...") {
                appState.saveActiveDocument(saveAs: true)
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Divider()

            Button("Print...") {
                appState.printActiveDocument()
            }
            .keyboardShortcut("p", modifiers: .command)

            Divider()

            Button("Close Document") {
                if let activeId = appState.activeDocumentId {
                    appState.closeDocument(id: activeId)
                }
            }
            .keyboardShortcut("w", modifiers: .command)
        }
    }
}

public struct EditCommands: Commands {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some Commands {
        CommandGroup(replacing: .undoRedo) {
            Button("Undo") {
                appState.undoActiveDocument()
            }
            .keyboardShortcut("z", modifiers: .command)

            Button("Redo") {
                appState.redoActiveDocument()
            }
            .keyboardShortcut("y", modifiers: .command)
        }

        // Suppress default macOS textEditing find submenu to avoid duplicate Search menu
        CommandGroup(replacing: .textEditing) { }

        CommandGroup(after: .pasteboard) {
            Divider()

            Button("Mark Selected Text") {
                appState.markSelection()
            }
            .keyboardShortcut("m", modifiers: .command)

            Button("Clear Marks in Document") {
                appState.clearAllMarksInActiveDocument()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])

            Divider()

            Button("Duplicate Line") {
                appState.duplicateCurrentLine()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Button("Delete Line") {
                appState.deleteCurrentLine()
            }
            .keyboardShortcut("d", modifiers: .command)

            Button("Join Lines") {
                appState.joinLines()
            }
            .keyboardShortcut("j", modifiers: .command)

            Button("Toggle Line Comment") {
                appState.toggleComment()
            }
            .keyboardShortcut("/", modifiers: .command)
        }
    }
}

public struct RunCommands: Commands {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some Commands {
        CommandMenu("Run") {
            Button("Run Current File") {
                appState.runActiveDocumentInTerminal()
            }
            .keyboardShortcut(.init(Character(UnicodeScalar(NSF5FunctionKey)!)), modifiers: [])

            Button("View in Default Browser") {
                appState.openActiveDocumentInBrowser()
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])

            Button("Open Terminal Here") {
                _ = appState.openTerminalHere()
            }
            .keyboardShortcut("`", modifiers: .control)
        }
    }
}

public struct SearchCommands: Commands {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some Commands {
        CommandMenu("Search") {
            Button("Find in File...") {
                appState.openFindDialog(tab: .find)
            }
            .keyboardShortcut("f", modifiers: .command)

            Button("Find and Replace...") {
                appState.openFindDialog(tab: .replace)
            }
            .keyboardShortcut("h", modifiers: .command)

            Button("Find in Files...") {
                appState.openFindDialog(tab: .findInFiles)
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])

            Button("Find in Projects...") {
                appState.openFindDialog(tab: .findInProjects)
            }

            Button("Mark...") {
                appState.openFindDialog(tab: .mark)
            }

            Divider()

            Button("Find Next") {
                appState.findNext()
            }
            .keyboardShortcut("g", modifiers: .command)

            Button("Find Previous") {
                appState.findPrevious()
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])

            Divider()

            Button("Go to Line...") {
                appState.showGoToLineSheet = true
            }
            .keyboardShortcut("l", modifiers: .command)

            Divider()

            Button("Toggle Bookmark") {
                appState.toggleBookmark()
            }
            .keyboardShortcut(.init(Character(UnicodeScalar(NSF2FunctionKey)!)), modifiers: .command)

            Button("Next Bookmark") {
                appState.nextBookmark()
            }
            .keyboardShortcut(.init(Character(UnicodeScalar(NSF2FunctionKey)!)), modifiers: [])

            Button("Previous Bookmark") {
                appState.prevBookmark()
            }
            .keyboardShortcut(.init(Character(UnicodeScalar(NSF2FunctionKey)!)), modifiers: .shift)

            Button("Clear All Bookmarks") {
                appState.clearBookmarks()
            }
        }
    }
}

public struct ViewCommands: Commands {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some Commands {
        CommandMenu("View") {
            Toggle("Sidebar", isOn: $appState.isSidebarVisible)
                .keyboardShortcut("b", modifiers: .command)

            Toggle("Status Bar", isOn: $appState.isStatusBarVisible)

            Toggle("Line Numbers", isOn: $appState.showLineNumbers)

            Toggle("Developer Terminal", isOn: $appState.isBottomPanelVisible)
                .keyboardShortcut("`", modifiers: .control)

            Toggle("Word Wrap", isOn: $appState.wordWrap)
                .keyboardShortcut("z", modifiers: .option)

            Toggle("Show Whitespace", isOn: $appState.showWhitespace)

            Toggle("Syntax Highlighting", isOn: $appState.syntaxHighlightingEnabled)

            Divider()

            Button("Split Vertically") {
                appState.splitVertically()
            }
            .keyboardShortcut("s", modifiers: [.command, .option])

            Button("Move Tab to Left Pane") {
                appState.moveTabToLeftPane()
            }
            .disabled(!appState.isSplitViewActive || appState.activePane == .left)

            Button("Move Tab to Right Pane") {
                appState.moveTabToRightPane()
            }
            .disabled(!appState.isSplitViewActive || appState.activePane == .right)

            Button("Move Tab to Other Pane") {
                if appState.activePane == .left {
                    appState.moveTabToRightPane()
                } else {
                    appState.moveTabToLeftPane()
                }
            }
            .disabled(!appState.isSplitViewActive)

            Button("Swap Editor Panes") {
                appState.swapPanes()
            }
            .disabled(!appState.isSplitViewActive)
            .keyboardShortcut("w", modifiers: [.command, .option])

            Button("Close Left Pane") {
                appState.closeLeftPane()
            }
            .disabled(!appState.isSplitViewActive)

            Button("Close Right Pane") {
                appState.closeRightPane()
            }
            .disabled(!appState.isSplitViewActive)

            Button("Close Split View") {
                appState.closeSplitView()
            }
            .disabled(!appState.isSplitViewActive)
            .keyboardShortcut("s", modifiers: [.command, .option, .shift])

            Toggle("Synchronize Scrolling", isOn: Binding(
                get: { appState.isSynchronizedScrollingEnabled },
                set: { _ in appState.toggleSynchronizedScrolling() }
            ))
            .disabled(!appState.isSplitViewActive)

            Divider()

            Button("Increase Font Size") {
                appState.increaseFontSize()
            }
            .keyboardShortcut("+", modifiers: .command)

            Button("Decrease Font Size") {
                appState.decreaseFontSize()
            }
            .keyboardShortcut("-", modifiers: .command)

            Button("Reset Font Size") {
                appState.resetFontSize()
            }
            .keyboardShortcut("0", modifiers: .command)

            Divider()

            Menu("Appearance") {
                Button(action: { appState.appearanceMode = .auto }) {
                    Text(appState.appearanceMode == .auto ? "✓ Auto" : "   Auto")
                }
                Button(action: { appState.appearanceMode = .light }) {
                    Text(appState.appearanceMode == .light ? "✓ Light" : "   Light")
                }
                Button(action: { appState.appearanceMode = .dark }) {
                    Text(appState.appearanceMode == .dark ? "✓ Dark" : "   Dark")
                }
            }

            Menu("Editor Theme") {
                ForEach(ThemeManager.allThemeNames, id: \.self) { t in
                    Button(action: { appState.theme = t }) {
                        Text(appState.theme == t ? "✓ \(t)" : "   \(t)")
                    }
                }
            }
        }
    }
}

// MARK: - Compare Commands (Notepad++ Style File Comparison)
public struct CompareCommands: Commands {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some Commands {
        CommandMenu("Compare") {
            Button("Select First to Compare") {
                if let active = appState.activeDocument {
                    appState.selectFirstToCompare(doc: active)
                }
            }
            .disabled(appState.activeDocument == nil)

            Button("Compare with Selected") {
                if let active = appState.activeDocument {
                    appState.compareWithSelected(doc: active)
                }
            }
            .disabled(appState.firstComparisonDocId == nil || appState.activeDocument == nil || appState.firstComparisonDocId == appState.activeDocument?.id)

            Button("Compare Active Panes") {
                appState.compareWithOtherPane()
            }
            .disabled(!appState.isSplitViewActive || appState.leftDocument == nil || appState.rightDocument == nil)

            Button("Compare Files…") {
                appState.compareFilesFromDisk()
            }

            Divider()

            Button("Next Difference") {
                appState.nextDifference()
            }
            .keyboardShortcut("]", modifiers: [.command, .option])
            .disabled(!appState.isComparing || (appState.comparisonResult?.chunks.isEmpty ?? true))

            Button("Previous Difference") {
                appState.previousDifference()
            }
            .keyboardShortcut("[", modifiers: [.command, .option])
            .disabled(!appState.isComparing || (appState.comparisonResult?.chunks.isEmpty ?? true))

            Button("First Difference") {
                appState.firstDifference()
            }
            .keyboardShortcut("1", modifiers: [.command, .option])
            .disabled(!appState.isComparing || (appState.comparisonResult?.chunks.isEmpty ?? true))

            Button("Last Difference") {
                appState.lastDifference()
            }
            .keyboardShortcut("9", modifiers: [.command, .option])
            .disabled(!appState.isComparing || (appState.comparisonResult?.chunks.isEmpty ?? true))

            Divider()

            Button("Recompare / Refresh Comparison") {
                appState.recompare()
            }
            .keyboardShortcut("r", modifiers: [.command, .option])
            .disabled(!appState.isComparing)

            Button("Swap Comparison Files") {
                appState.swapPanes()
            }
            .disabled(!appState.isComparing)

            Toggle("Synchronize Scrolling", isOn: Binding(
                get: { appState.isSynchronizedScrollingEnabled },
                set: { _ in appState.toggleSynchronizedScrolling() }
            ))
            .disabled(!appState.isSplitViewActive)

            Divider()

            Button("Clear Comparison") {
                appState.clearComparison()
            }
            .keyboardShortcut("x", modifiers: [.command, .option])
            .disabled(!appState.isComparing)
        }
    }
}

public struct EncodingCommands: Commands {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some Commands {
        CommandMenu("Encoding") {
            Menu("Character Encoding") {
                ForEach(DocumentEncoding.allCases) { enc in
                    Button(enc.rawValue) {
                        appState.activeDocument?.encoding = enc
                    }
                }
            }

            Menu("Line Ending Format") {
                ForEach(LineEndingFormat.allCases) { ending in
                    Button(ending.rawValue) {
                        appState.activeDocument?.convertLineEndings(to: ending)
                    }
                }
            }
        }
    }
}

public struct LanguageCommands: Commands {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some Commands {
        CommandMenu("Language") {
            Button(action: {
                appState.setLanguageForActiveDocument("Plain Text")
            }) {
                HStack {
                    Text("None (Normal Text)")
                    if appState.activeDocument?.language.caseInsensitiveCompare("Plain Text") == .orderedSame {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(SyntaxEngine.alphabeticalGroups) { group in
                Menu(group.letter) {
                    ForEach(group.languages, id: \.self) { lang in
                        Button(action: {
                            appState.setLanguageForActiveDocument(lang)
                        }) {
                            HStack {
                                Text(lang)
                                if appState.activeDocument?.language.caseInsensitiveCompare(lang) == .orderedSame {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

public enum PluginManagerWindow {
    public static let id = "plugin-manager"
}

public struct PluginCommands: Commands {
    @ObservedObject var appState: AppStateManager
    @ObservedObject private var registry = PluginRegistry.shared
    @Environment(\.openWindow) private var openWindow

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some Commands {
        CommandMenu("Plugins") {
            Button("Plugin Manager...") {
                openWindow(id: PluginManagerWindow.id)
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])

            Divider()

            Menu("JSON Tools") {
                Button("Format & Prettify JSON") {
                    PluginRegistry.shared.jsonPrettify(appState: appState)
                }
                Button("Minify JSON") {
                    PluginRegistry.shared.jsonMinify(appState: appState)
                }
                Button("Validate JSON") {
                    PluginRegistry.shared.jsonValidate(appState: appState)
                }
            }

            Menu("XML Tools") {
                Button("Format & Indent XML") {
                    PluginRegistry.shared.xmlFormat(appState: appState)
                }
            }

            Menu("Line Tools") {
                Button("Sort Lines Ascending (A-Z)") {
                    PluginRegistry.shared.sortLinesAscending(appState: appState)
                }
                Button("Sort Lines Descending (Z-A)") {
                    PluginRegistry.shared.sortLinesDescending(appState: appState)
                }
                Button("Remove Duplicate Lines") {
                    PluginRegistry.shared.removeDuplicateLines(appState: appState)
                }
            }

            Menu("Encoding & Cryptography") {
                Button("Base64 Encode Text") {
                    PluginRegistry.shared.base64Encode(appState: appState)
                }
                Button("Base64 Decode Text") {
                    PluginRegistry.shared.base64Decode(appState: appState)
                }
            }

            let community = registry.plugins.filter { $0.source == .community && $0.isInstalled && $0.isEnabled && !$0.commands.isEmpty }
            if !community.isEmpty {
                Divider()
                ForEach(community) { plugin in
                    Menu(plugin.name) {
                        ForEach(plugin.commands) { command in
                            Button(command.title) {
                                registry.runCommand(pluginID: plugin.id, commandID: command.id, appState: appState)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Help Commands (Welcome Screen & Documentation)
public struct HelpCommands: Commands {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("Welcome to NPad++") {
                NativeWelcomeWindowController.shared.show(appState: appState, showFeatures: false)
            }

            Button("NPad++ Features") {
                NativeWelcomeWindowController.shared.show(appState: appState, showFeatures: true)
            }

            Divider()

            Button("NPad++ Documentation & Support...") {
                appState.showDocumentationSheet = true
            }

            Divider()

            Button("Official GitHub Repository") {
                if let url = URL(string: AppStateManager.githubRepositoryURL) {
                    NSWorkspace.shared.open(url)
                }
            }

            Button("Report an Issue / Feedback") {
                if let url = URL(string: AppStateManager.githubIssuesURL) {
                    NSWorkspace.shared.open(url)
                }
            }

            Button("Check for Updates...") {
                if let url = URL(string: "\(AppStateManager.githubRepositoryURL)/releases") {
                    NSWorkspace.shared.open(url)
                }
            }

            Divider()

            Button("Made By Vijay (@made.by.vijay)") {
                if let url = URL(string: AppStateManager.authorInstagramURL) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

// MARK: - Welcome Experience View (First-Launch & Help -> Welcome)
public struct WelcomeExperienceView: View {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some View {
        NativeWelcomeHostView(appState: appState) {
            appState.showWelcomeSheet = false
        }
    }
}

// MARK: - Main Welcome Screen Content
public struct WelcomeMainView: View {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar with Close (xmark)
            HStack {
                Spacer()
                Button(action: {
                    appState.markWelcomeCompleted()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Welcome Screen")
            }
            .padding(.top, 14)
            .padding(.trailing, 16)

            // App Icon & Hero Title
            VStack(spacing: 6) {
                if let icon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 68, height: 68)
                } else {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                }

                Text("Welcome to NPad++")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)

                Text("Your workspace for coding, editing, and building.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Text("Thank you for installing NPad++. Get started by creating a new file or opening an existing project.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.top, 2)
            }
            .padding(.top, -10)
            .padding(.bottom, 16)

            // Quick Actions List
            VStack(spacing: 8) {
                WelcomeActionRow(
                    icon: "doc.badge.plus",
                    iconColor: .blue,
                    title: "New File",
                    description: "Create a new, editable document."
                ) {
                    appState.markWelcomeCompleted()
                    appState.createNewDocument()
                }

                WelcomeActionRow(
                    icon: "folder",
                    iconColor: .orange,
                    title: "Open File",
                    description: "Open an existing file from your Mac."
                ) {
                    appState.markWelcomeCompleted()
                    DispatchQueue.main.async {
                        appState.openDocument()
                    }
                }

                WelcomeActionRow(
                    icon: "sidebar.left",
                    iconColor: .purple,
                    title: "Open Folder",
                    description: "Open a folder or project workspace."
                ) {
                    appState.markWelcomeCompleted()
                    DispatchQueue.main.async {
                        appState.openFolder()
                    }
                }

                WelcomeActionRow(
                    icon: "sparkles",
                    iconColor: .green,
                    title: "Explore Features",
                    description: "Briefly introduce syntax highlighting, tabs, Find and Replace, Undo/Redo, and the Developer Terminal."
                ) {
                    appState.welcomeExploreFeaturesActive = true
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            Divider()

            // Footer
            HStack {
                Button(action: {
                    if let url = URL(string: AppStateManager.githubRepositoryURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("GitHub Repository", systemImage: "link")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Button("Get Started") {
                    appState.markWelcomeCompleted()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.regular)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
    }
}

// MARK: - Welcome Action Button Style (Macro-free)
public struct WelcomeActionButtonStyle: ButtonStyle {
    public let iconColor: Color

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? Color(NSColor.selectedControlColor).opacity(0.25) : Color(NSColor.controlBackgroundColor).opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(configuration.isPressed ? iconColor.opacity(0.5) : Color.secondary.opacity(0.15), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
    }
}

// MARK: - Welcome Action Interactive Row (Macro-free)
public struct WelcomeActionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let action: () -> Void

    public init(icon: String, iconColor: Color, title: String, description: String, action: @escaping () -> Void) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.description = description
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.16))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(WelcomeActionButtonStyle(iconColor: iconColor))
    }
}

// MARK: - Explore Features View
public struct ExploreFeaturesView: View {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar with Back Button
            HStack {
                Button(action: {
                    appState.welcomeExploreFeaturesActive = false
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 12, weight: .bold))
                        Text("Back")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Spacer()

                Text("NPad++ Features")
                    .font(.system(size: 14, weight: .bold))

                Spacer()

                Button(action: {
                    appState.markWelcomeCompleted()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Welcome Screen")
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 12) {
                    FeatureHighlightRow(
                        icon: "curlybraces",
                        iconColor: .blue,
                        title: "Syntax Highlighting",
                        summary: "Real-time, high-contrast syntax highlighting for over 20 languages including Java, Swift, Python, JS/TS, C++, JSON, XML, HTML, and Markdown."
                    )

                    FeatureHighlightRow(
                        icon: "square.stack.3d.up.fill",
                        iconColor: .purple,
                        title: "Tabs & Workspace Persistence",
                        summary: "Multi-tab document management with unsaved change tracking and automatic session recovery across restarts."
                    )

                    FeatureHighlightRow(
                        icon: "magnifyingglass",
                        iconColor: .orange,
                        title: "Find & Replace",
                        summary: "High-performance search with regex support, case-sensitivity, whole-word matching, and instant in-editor highlight navigation."
                    )

                    FeatureHighlightRow(
                        icon: "arrow.uturn.backward",
                        iconColor: .green,
                        title: "Multi-Level Undo & Redo",
                        summary: "Isolated per-document undo/redo stacks that accurately preserve typing history with standard ⌘Z and ⇧⌘Z shortcuts."
                    )

                    FeatureHighlightRow(
                        icon: "terminal.fill",
                        iconColor: .pink,
                        title: "Developer Terminal & Direct Runner",
                        summary: "Built-in developer terminal (^`) with working-directory synchronization and direct one-click code execution (F5)."
                    )

                    FeatureHighlightRow(
                        icon: "folder.fill",
                        iconColor: .teal,
                        title: "Project Explorer & File Management",
                        summary: "Hierarchical tree structure with nested folder traversal, file creation, deletion with safety checks, and rename operations."
                    )

                    FeatureHighlightRow(
                        icon: "rectangle.split.2x1.fill",
                        iconColor: .indigo,
                        title: "Split View & File Comparison",
                        summary: "Side-by-side editing with Eugene Myers diff comparison, synchronized scrolling, and character-level difference highlighting."
                    )

                    FeatureHighlightRow(
                        icon: "puzzlepiece.extension.fill",
                        iconColor: .yellow,
                        title: "Plugin Ecosystem",
                        summary: "Manage and run developer plugins including JSON/XML formatters, Git integration, TODO trackers, and line sorters."
                    )
                }
                .padding(18)
            }

            Divider()

            // Footer
            HStack {
                Button(action: {
                    if let url = URL(string: AppStateManager.githubRepositoryURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("GitHub Repository", systemImage: "link")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Button("Start Coding") {
                    appState.markWelcomeCompleted()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
    }
}

// MARK: - Feature Highlight Row
public struct FeatureHighlightRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let summary: String

    public init(icon: String, iconColor: Color, title: String, summary: String) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.summary = summary
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.16))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(summary)
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
        )
    }
}

// MARK: - Comparison Toolbar View
public struct ComparisonToolbarView: View {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some View {
        HStack(spacing: 10) {
            // Icon & Comparing Titles
            HStack(spacing: 6) {
                Image(systemName: "arrow.left.and.right.square.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 13))

                Text("Comparing:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                Text(appState.leftDocument?.title ?? "Left File")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                Image(systemName: "arrow.right")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)

                Text(appState.rightDocument?.title ?? "Right File")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }

            Divider().frame(height: 16)

            // Diff summary pill
            if let result = appState.comparisonResult {
                HStack(spacing: 6) {
                    if result.totalDifferences == 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 11))
                            Text("Files are identical")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("\(result.totalDifferences) diffs")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(4)

                        HStack(spacing: 4) {
                            Text("+\(result.addedCount)")
                                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(red: 0.1, green: 0.6, blue: 0.2))
                            Text("-\(result.deletedCount)")
                                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(red: 0.85, green: 0.2, blue: 0.2))
                            Text("~\(result.modifiedCount)")
                                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(red: 0.9, green: 0.55, blue: 0.1))
                        }

                        if !result.chunks.isEmpty {
                            Text("Chunk \(result.activeChunkIndex + 1) of \(result.chunks.count)")
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Difference Navigation Controls
            HStack(spacing: 3) {
                Button(action: { appState.firstDifference() }) {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 22)
                .help("First Difference (⌥⌘1)")
                .disabled(appState.comparisonResult?.chunks.isEmpty ?? true)

                Button(action: { appState.previousDifference() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 22)
                .help("Previous Difference (⌥⌘[)")
                .disabled(appState.comparisonResult?.chunks.isEmpty ?? true)

                Button(action: { appState.nextDifference() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 22)
                .help("Next Difference (⌥⌘])")
                .disabled(appState.comparisonResult?.chunks.isEmpty ?? true)

                Button(action: { appState.lastDifference() }) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 22)
                .help("Last Difference (⌥⌘9)")
                .disabled(appState.comparisonResult?.chunks.isEmpty ?? true)
            }

            Divider().frame(height: 16)

            // Recompare & Sync Scroll & Swap & Clear
            HStack(spacing: 4) {
                Button(action: { appState.recompare() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 22)
                .help("Recompare Files (⌥⌘R)")

                Button(action: { appState.toggleSynchronizedScrolling() }) {
                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                        .font(.system(size: 10))
                        .foregroundColor(appState.isSynchronizedScrollingEnabled ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 22)
                .background(appState.isSynchronizedScrollingEnabled ? Color.accentColor.opacity(0.15) : Color.clear)
                .cornerRadius(4)
                .help(appState.isSynchronizedScrollingEnabled ? "Synchronized Scrolling: ON" : "Synchronized Scrolling: OFF")

                Button(action: { appState.swapPanes() }) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 22)
                .help("Swap Left and Right Panes (⌥⌘W)")

                Divider().frame(height: 16)

                Button(action: { appState.clearComparison() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 22)
                .help("Clear Comparison (⌥⌘X)")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(Divider(), alignment: .bottom)
    }
}

/// Geometry of the "drop here to split screen" target inside the editor area.
/// The zone is the right half of the editor container itself (not the window or screen), so it never reacts to
/// the toolbar, tab bar, sidebar or bottom panel, and it starts at the 50% line instead of the far edge.
public enum SplitDropZone {
    public static let activationFraction: CGFloat = 0.5

    public static func zoneWidth(containerWidth: CGFloat) -> CGFloat {
        max(0, containerWidth) * activationFraction
    }

    /// `x` is measured from the container's left edge.
    public static func isInside(x: CGFloat, containerWidth: CGFloat) -> Bool {
        guard containerWidth > 0, x >= 0, x <= containerWidth else { return false }
        return x >= containerWidth - zoneWidth(containerWidth: containerWidth)
    }
}

// MARK: - Single Editor Container View with Vertical Split Drop Zone
public struct SingleEditorContainerView: View {
    @ObservedObject var document: EditorDocument
    @ObservedObject var appState: AppStateManager

    public init(document: EditorDocument, appState: AppStateManager) {
        self.document = document
        self.appState = appState
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                // Main active editor
                MacEditorView(
                    document: document,
                    appState: appState,
                    fontSize: appState.fontSize,
                    fontFamily: appState.fontFamily,
                    wordWrap: appState.wordWrap,
                    showWhitespace: appState.showWhitespace
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Right-side Drop Zone: the right half of the editor. As soon as a dragged file crosses the
                // 50% line, the half lights up with a "Drop here to split screen" hint.
                let dropZoneWidth = SplitDropZone.zoneWidth(containerWidth: geometry.size.width)

                HStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        if appState.isSingleEditorDragOverRight {
                            ZStack {
                                Color.accentColor.opacity(0.12)
                                VStack(spacing: 10) {
                                    Image(systemName: "square.split.2x1")
                                        .font(.system(size: 34))
                                        .foregroundColor(.accentColor)
                                    Text("Drop here to split screen")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.accentColor)
                                    Text("The file opens in the right pane")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.accentColor, lineWidth: 2)
                            )
                            .padding(8)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: dropZoneWidth, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .onDrop(of: ["public.file-url", "public.text"], isTargeted: Binding(
                        get: { appState.isSingleEditorDragOverRight },
                        set: { val in appState.isSingleEditorDragOverRight = val }
                    )) { providers in
                        appState.isSingleEditorDragOverRight = false
                        if let draggingId = appState.draggingDocumentId {
                            appState.splitWithDocument(id: draggingId, to: .right)
                            appState.draggingDocumentId = nil
                            return true
                        }
                        for provider in providers {
                            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                                _ = provider.loadObject(ofClass: NSURL.self) { item, _ in
                                    if let url = item as? URL {
                                        DispatchQueue.main.async {
                                            appState.splitWithFileURL(url, to: .right)
                                        }
                                    }
                                }
                                return true
                            } else if provider.hasItemConformingToTypeIdentifier("public.text") {
                                _ = provider.loadObject(ofClass: NSString.self) { item, _ in
                                    if let str = item as? String, let docId = UUID(uuidString: str) {
                                        DispatchQueue.main.async {
                                            appState.splitWithDocument(id: docId, to: .right)
                                        }
                                    }
                                }
                                return true
                            }
                        }
                        return false
                    }
                }
            }
        }
    }
}

// MARK: - Split Editor Container View
public struct SplitEditorContainerView: View {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            if appState.isComparing {
                ComparisonToolbarView(appState: appState)
            }

            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let dividerWidth: CGFloat = 8
                let usableWidth = max(400, availableWidth - dividerWidth)
                let leftWidth = max(180, min(usableWidth - 180, usableWidth * appState.splitRatio))
                let rightWidth = usableWidth - leftWidth

                HStack(spacing: 0) {
                    // Left Editor Pane
                    EditorPaneView(
                        paneSide: .left,
                        appState: appState,
                        isActive: appState.activePane == .left
                    )
                    .frame(width: leftWidth)

                    // Draggable Split Divider
                    DraggableSplitDivider(splitRatio: $appState.splitRatio, totalWidth: usableWidth)
                        .frame(width: dividerWidth)

                    // Right Editor Pane
                    EditorPaneView(
                        paneSide: .right,
                        appState: appState,
                        isActive: appState.activePane == .right
                    )
                    .frame(width: rightWidth)
                }
            }
        }
    }
}

// MARK: - Draggable Split Divider
public struct DraggableSplitDivider: View {
    @Binding var splitRatio: CGFloat
    let totalWidth: CGFloat

    public init(splitRatio: Binding<CGFloat>, totalWidth: CGFloat) {
        self._splitRatio = splitRatio
        self.totalWidth = totalWidth
    }

    public var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(width: 1.5)

            // Grab Handle dots
            VStack(spacing: 3) {
                Circle().frame(width: 2.5, height: 2.5)
                Circle().frame(width: 2.5, height: 2.5)
                Circle().frame(width: 2.5, height: 2.5)
            }
            .foregroundColor(Color.secondary.opacity(0.6))
        }
        .frame(width: 8)
        .contentShape(Rectangle())
        .onHover { inside in
            if inside {
                NSCursor.resizeLeftRight.push()
            } else {
                NSCursor.pop()
            }
        }
        .gesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    let delta = value.translation.width
                    let ratioDelta = delta / max(totalWidth, 1)
                    let newRatio = min(max(splitRatio + ratioDelta * 0.05, 0.15), 0.85)
                    splitRatio = newRatio
                }
        )
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                splitRatio = 0.5
            }
        }
        .help("Drag to resize editor panes. Double-click to reset to 50/50.")
    }
}

// MARK: - Editor Pane View (Left/Right)
public struct EditorPaneView: View {
    let paneSide: EditorPaneSide
    @ObservedObject var appState: AppStateManager
    let isActive: Bool

    public init(paneSide: EditorPaneSide, appState: AppStateManager, isActive: Bool) {
        self.paneSide = paneSide
        self.appState = appState
        self.isActive = isActive
    }

    private var activeDoc: EditorDocument? {
        paneSide == .left ? appState.leftDocument : appState.rightDocument
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Pane Tab Bar
            PaneTabBar(paneSide: paneSide, appState: appState, isActive: isActive)

            // 2. Pane Content
            if let doc = activeDoc {
                MacEditorView(
                    document: doc,
                    appState: appState,
                    fontSize: appState.fontSize,
                    fontFamily: appState.fontFamily,
                    wordWrap: appState.wordWrap,
                    showWhitespace: appState.showWhitespace,
                    paneSide: paneSide
                )
                .id(doc.id)
                .frame(minWidth: 150, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
                .onTapGesture {
                    appState.activePane = paneSide
                    appState.activeDocumentId = doc.id
                }
                .overlay(
                    Group {
                        if (paneSide == .left ? appState.isPaneDragOverLeft : appState.isPaneDragOverRight) {
                            ZStack {
                                Color.accentColor.opacity(0.12)
                                VStack(spacing: 8) {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.accentColor)
                                    Text("Drop to open in \(paneSide.rawValue) Pane")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.accentColor, lineWidth: 2)
                            )
                        }
                    }
                )
            } else {
                EmptyPanePlaceholder(title: "\(paneSide.rawValue) Pane", side: paneSide, appState: appState)
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .onDrop(of: ["public.file-url", "public.text"], isTargeted: Binding(
            get: { paneSide == .left ? appState.isPaneDragOverLeft : appState.isPaneDragOverRight },
            set: { val in
                if paneSide == .left {
                    appState.isPaneDragOverLeft = val
                } else {
                    appState.isPaneDragOverRight = val
                }
            }
        )) { providers in
            if paneSide == .left {
                appState.isPaneDragOverLeft = false
            } else {
                appState.isPaneDragOverRight = false
            }
            if let draggingId = appState.draggingDocumentId {
                appState.moveDocument(id: draggingId, to: paneSide)
                appState.draggingDocumentId = nil
                return true
            }
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    _ = provider.loadObject(ofClass: NSURL.self) { item, _ in
                        if let url = item as? URL {
                            DispatchQueue.main.async {
                                appState.openFileInPane(url: url, pane: paneSide)
                            }
                        }
                    }
                    return true
                }
            }
            return false
        }
    }
}

// MARK: - Pane Tab Bar
public struct PaneTabBar: View {
    let paneSide: EditorPaneSide
    @ObservedObject var appState: AppStateManager
    let isActive: Bool

    public init(paneSide: EditorPaneSide, appState: AppStateManager, isActive: Bool) {
        self.paneSide = paneSide
        self.appState = appState
        self.isActive = isActive
    }

    private var documents: [EditorDocument] {
        paneSide == .left ? appState.leftDocuments : appState.rightDocuments
    }

    private var activeId: UUID? {
        paneSide == .left ? (appState.leftActiveDocumentId ?? appState.leftDocumentId) : (appState.rightActiveDocumentId ?? appState.rightDocumentId)
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Scrollable Tab List
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(documents.enumerated()), id: \.element.id) { idx, doc in
                        // Drop insertion line before tab
                        if appState.dragTargetPane == paneSide && appState.dragTargetIndex == idx {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: 3, height: 26)
                        }

                        PaneTabItem(
                            document: doc,
                            paneSide: paneSide,
                            index: idx,
                            isActiveTab: doc.id == activeId,
                            appState: appState
                        )
                    }

                    // Drop insertion line at end
                    if appState.dragTargetPane == paneSide && appState.dragTargetIndex == documents.count {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 3, height: 26)
                    }

                    // Plus button to add tab to this pane
                    Button(action: {
                        appState.createNewDocument(pane: paneSide)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                    .help("New Tab in \(paneSide.rawValue) Pane")
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                }
            }
            .onDrop(of: ["public.file-url", "public.text"], isTargeted: Binding(
                get: { appState.dragTargetPane == paneSide && appState.dragTargetIndex == documents.count },
                set: { targeted in
                    if targeted {
                        appState.dragTargetPane = paneSide
                        appState.dragTargetIndex = documents.count
                    } else if appState.dragTargetPane == paneSide && appState.dragTargetIndex == documents.count {
                        appState.dragTargetIndex = nil
                    }
                }
            )) { providers in
                if let draggingId = appState.draggingDocumentId {
                    appState.moveDocument(id: draggingId, to: paneSide, targetIndex: documents.count)
                    appState.draggingDocumentId = nil
                    appState.dragTargetPane = nil
                    appState.dragTargetIndex = nil
                    return true
                }
                for provider in providers {
                    if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                        _ = provider.loadObject(ofClass: NSURL.self) { item, _ in
                            if let url = item as? URL {
                                DispatchQueue.main.async {
                                    appState.openFileInPane(url: url, pane: paneSide)
                                }
                            }
                        }
                        return true
                    }
                }
                return false
            }

            Spacer()

            // Pane controls & badge
            HStack(spacing: 5) {
                Text(paneSide.rawValue.uppercased())
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(isActive ? Color.white : Color.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(isActive ? Color.accentColor : Color.secondary.opacity(0.18))
                    .cornerRadius(3)

                Button(action: {
                    appState.swapPanes()
                }) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Swap Panes (⌥⌘W)")

                Button(action: {
                    if paneSide == .left {
                        appState.closeLeftPane()
                    } else {
                        appState.closeRightPane()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close \(paneSide.rawValue) Pane")
            }
            .padding(.trailing, 6)
        }
        .frame(height: 28)
        .background(isActive ? Color.accentColor.opacity(0.08) : Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .fill(isActive ? Color.accentColor : Color.clear)
                .frame(height: 2),
            alignment: .top
        )
        .overlay(Divider(), alignment: .bottom)
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onTapGesture {
            appState.activePane = paneSide
            if let activeId = activeId {
                appState.activeDocumentId = activeId
            }
        }
    }
}

// MARK: - Pane Tab Item
public struct PaneTabItem: View {
    @ObservedObject var document: EditorDocument
    let paneSide: EditorPaneSide
    let index: Int
    let isActiveTab: Bool
    @ObservedObject var appState: AppStateManager

    public init(
        document: EditorDocument,
        paneSide: EditorPaneSide,
        index: Int,
        isActiveTab: Bool,
        appState: AppStateManager
    ) {
        self.document = document
        self.paneSide = paneSide
        self.index = index
        self.isActiveTab = isActiveTab
        self.appState = appState
    }

    public var body: some View {
        HStack(spacing: 5) {
            // Language icon
            Image(systemName: languageSymbol(for: document.language))
                .font(.system(size: 10))
                .foregroundColor(languageColor(for: document.language))

            // Title
            Text(document.title)
                .font(.system(size: 11.5, weight: isActiveTab ? .semibold : .regular))
                .foregroundColor(isActiveTab ? .primary : .secondary)
                .lineLimit(1)

            // Dirty indicator
            if document.isModified {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }

            // Close button
            Button(action: {
                appState.closeDocument(id: document.id)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.7))
                    .frame(width: 14, height: 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Close Tab")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(isActiveTab ? Color(NSColor.windowBackgroundColor) : Color.clear)
        .overlay(
            Rectangle()
                .fill(isActiveTab ? Color.accentColor : Color.clear)
                .frame(height: 2),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onTapGesture {
            appState.activePane = paneSide
            if paneSide == .left {
                appState.leftActiveDocumentId = document.id
                appState.leftDocumentId = document.id
            } else {
                appState.rightActiveDocumentId = document.id
                appState.rightDocumentId = document.id
            }
            appState.activeDocumentId = document.id
            if appState.isComparing {
                appState.recompare()
            }
        }
        .onDrag {
            appState.draggingDocumentId = document.id
            return NSItemProvider(object: document.id.uuidString as NSString)
        }
        .onDrop(of: ["public.file-url", "public.text"], isTargeted: Binding(
            get: { appState.dragTargetPane == paneSide && appState.dragTargetIndex == index },
            set: { targeted in
                if targeted {
                    appState.dragTargetPane = paneSide
                    appState.dragTargetIndex = index
                } else if appState.dragTargetPane == paneSide && appState.dragTargetIndex == index {
                    appState.dragTargetPane = nil
                    appState.dragTargetIndex = nil
                }
            }
        )) { providers in
            if let draggingId = appState.draggingDocumentId {
                appState.moveDocument(id: draggingId, to: paneSide, targetIndex: index)
                appState.draggingDocumentId = nil
                appState.dragTargetPane = nil
                appState.dragTargetIndex = nil
                return true
            }
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    _ = provider.loadObject(ofClass: NSURL.self) { item, _ in
                        if let url = item as? URL {
                            DispatchQueue.main.async {
                                appState.openFileInPane(url: url, pane: paneSide)
                            }
                        }
                    }
                    return true
                }
            }
            return false
        }
        .contextMenu {
            if paneSide == .left {
                Button("Move Tab to Right Pane") {
                    appState.moveTabToRightPane(docId: document.id)
                }
            } else {
                Button("Move Tab to Left Pane") {
                    appState.moveTabToLeftPane(docId: document.id)
                }
            }

            Button("Move to Other Pane") {
                if paneSide == .left {
                    appState.moveTabToRightPane(docId: document.id)
                } else {
                    appState.moveTabToLeftPane(docId: document.id)
                }
            }

            Divider()

            Button("Close Tab") {
                appState.closeDocument(id: document.id)
            }

            Button("Close Other Tabs in This Pane") {
                let paneDocIds = (paneSide == .left ? appState.leftDocumentIds : appState.rightDocumentIds).filter { $0 != document.id }
                for docId in paneDocIds {
                    _ = appState.closeDocument(id: docId)
                }
            }

            Divider()

            Button("Copy Full Path") {
                if let path = document.fileURL?.path {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(path, forType: .string)
                }
            }
            .disabled(document.fileURL == nil)

            Button("Open in Terminal") {
                if let dir = document.fileURL?.deletingLastPathComponent().path {
                    _ = appState.changeTerminalDirectory(to: dir)
                    appState.showTerminal = true
                }
            }
            .disabled(document.fileURL == nil)

            if !appState.isComparing {
                Button("Compare with Other Pane") {
                    appState.compareWithOtherPane()
                }
            }
        }
    }
}

// MARK: - Empty Pane Placeholder
public struct EmptyPanePlaceholder: View {
    let title: String
    let side: EditorPaneSide
    @ObservedObject var appState: AppStateManager

    public init(title: String, side: EditorPaneSide, appState: AppStateManager) {
        self.title = title
        self.side = side
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 38))
                .foregroundColor(.secondary.opacity(0.6))

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.primary)

            Text("No open documents in this pane.\nDrag a tab or file here, or choose an action below:")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            HStack(spacing: 10) {
                Button(action: {
                    appState.createNewDocument(pane: side)
                }) {
                    Label("New File", systemImage: "doc.badge.plus")
                        .font(.system(size: 11))
                }

                Button(action: {
                    appState.openDocument()
                }) {
                    Label("Open File...", systemImage: "folder")
                        .font(.system(size: 11))
                }

                Button(action: {
                    if side == .left {
                        appState.closeLeftPane()
                    } else {
                        appState.closeRightPane()
                    }
                }) {
                    Label("Close Pane", systemImage: "xmark")
                        .font(.system(size: 11))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.35))
        .onDrop(of: ["public.file-url", "public.text"], isTargeted: Binding(
            get: { side == .left ? appState.isPaneDragOverLeft : appState.isPaneDragOverRight },
            set: { val in
                if side == .left {
                    appState.isPaneDragOverLeft = val
                } else {
                    appState.isPaneDragOverRight = val
                }
            }
        )) { providers in
            if side == .left {
                appState.isPaneDragOverLeft = false
            } else {
                appState.isPaneDragOverRight = false
            }
            if let draggingId = appState.draggingDocumentId {
                appState.moveDocument(id: draggingId, to: side)
                appState.draggingDocumentId = nil
                return true
            }
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    _ = provider.loadObject(ofClass: NSURL.self) { item, _ in
                        if let url = item as? URL {
                            DispatchQueue.main.async {
                                appState.openFileInPane(url: url, pane: side)
                            }
                        }
                    }
                    return true
                }
            }
            return false
        }
    }
}
