import SwiftUI
import AppKit

// MARK: - Notepad++ Multi-Tab Find & Replace Dialog View
public struct NotepadPlusFindDialogView: View {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Tab Selector Bar
            HStack(spacing: 4) {
                ForEach(FindDialogTab.allCases) { tab in
                    Button(action: {
                        appState.findDialogTab = tab
                        if tab == .replace {
                            appState.isReplaceBarVisible = true
                        }
                        NotepadPlusFindWindowController.shared.updateTitleAndOpacity()
                    }) {
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: appState.findDialogTab == tab ? .semibold : .regular))
                            .foregroundColor(appState.findDialogTab == tab ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                appState.findDialogTab == tab
                                    ? Color.accentColor
                                    : Color(NSColor.controlColor).opacity(0.6)
                            )
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // 2. Main Content Area (Form Fields + Options + Actions)
            HStack(alignment: .top, spacing: 16) {
                // Left Column: Input Fields, Checkboxes, Search Mode & Transparency
                VStack(alignment: .leading, spacing: 10) {
                    inputFieldsForCurrentTab

                    // Option Checkboxes
                    optionsCheckboxesForCurrentTab

                    // Bottom Row: Search Mode Card & Transparency Card
                    HStack(alignment: .top, spacing: 12) {
                        searchModeCard
                            .frame(maxWidth: .infinity, alignment: .leading)

                        transparencyCard
                            .frame(width: 220, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right Column: Vertical Action Buttons Stack
                VStack(spacing: 6) {
                    actionButtonsForCurrentTab

                    Spacer()

                    Button("Close") {
                        appState.closeFindDialog()
                    }
                    .keyboardShortcut(.cancelAction)
                    .frame(maxWidth: .infinity)
                }
                .frame(width: 175)
            }
            .padding(14)

            // Status message footer if present
            if !appState.searchStatusMessage.isEmpty {
                HStack {
                    Text(appState.searchStatusMessage)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 710, height: 380)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Input Fields Per Tab
    @ViewBuilder
    private var inputFieldsForCurrentTab: some View {
        switch appState.findDialogTab {
        case .find:
            HStack(spacing: 8) {
                Text("Find what:")
                    .font(.system(size: 11))
                    .frame(width: 80, alignment: .trailing)

                TextField("", text: $appState.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))

                if !appState.searchHistory.isEmpty {
                    Menu {
                        ForEach(appState.searchHistory, id: \.self) { item in
                            Button(item) { appState.searchQuery = item }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 18)
                }

                Toggle("In selection", isOn: $appState.searchInSelection)
                    .font(.system(size: 11))
                    .toggleStyle(.checkbox)
            }

        case .replace:
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("Find what:")
                        .font(.system(size: 11))
                        .frame(width: 80, alignment: .trailing)

                    TextField("", text: $appState.searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))

                    Toggle("In selection", isOn: $appState.searchInSelection)
                        .font(.system(size: 11))
                        .toggleStyle(.checkbox)
                }

                HStack(spacing: 8) {
                    Text("Replace with:")
                        .font(.system(size: 11))
                        .frame(width: 80, alignment: .trailing)

                    TextField("", text: $appState.replaceQuery)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))

                    if !appState.replaceHistory.isEmpty {
                        Menu {
                            ForEach(appState.replaceHistory, id: \.self) { item in
                                Button(item) { appState.replaceQuery = item }
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9))
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 18)
                    }
                }
            }

        case .findInFiles:
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("Find what:")
                        .font(.system(size: 11))
                        .frame(width: 80, alignment: .trailing)
                    TextField("", text: $appState.searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                }

                HStack(spacing: 8) {
                    Text("Replace with:")
                        .font(.system(size: 11))
                        .frame(width: 80, alignment: .trailing)
                    TextField("", text: $appState.replaceQuery)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                }

                HStack(spacing: 8) {
                    Text("Filters:")
                        .font(.system(size: 11))
                        .frame(width: 80, alignment: .trailing)
                    TextField("*.*", text: $appState.searchFilters)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                }

                HStack(spacing: 6) {
                    Text("Directory:")
                        .font(.system(size: 11))
                        .frame(width: 80, alignment: .trailing)
                    TextField("", text: $appState.searchDirectory)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))

                    Button("...") {
                        selectDirectory()
                    }
                    .font(.system(size: 10))
                    .frame(width: 28)

                    Button("<<") {
                        if let url = appState.activeDocument?.fileURL {
                            appState.searchDirectory = url.deletingLastPathComponent().path
                        } else {
                            appState.searchDirectory = appState.terminalWorkingDirectory
                        }
                    }
                    .font(.system(size: 10))
                    .frame(width: 28)
                    .help("Follow current active file directory")
                }
            }

        case .findInProjects:
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("Find what:")
                        .font(.system(size: 11))
                        .frame(width: 80, alignment: .trailing)
                    TextField("", text: $appState.searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                }

                HStack(spacing: 8) {
                    Text("Replace with:")
                        .font(.system(size: 11))
                        .frame(width: 80, alignment: .trailing)
                    TextField("", text: $appState.replaceQuery)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                }

                HStack(spacing: 8) {
                    Text("Filters:")
                        .font(.system(size: 11))
                        .frame(width: 80, alignment: .trailing)
                    TextField("*.*", text: $appState.searchFilters)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                }
            }

        case .mark:
            HStack(spacing: 8) {
                Text("Find what:")
                    .font(.system(size: 11))
                    .frame(width: 80, alignment: .trailing)

                TextField("", text: $appState.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))

                Toggle("In selection", isOn: $appState.searchInSelection)
                    .font(.system(size: 11))
                    .toggleStyle(.checkbox)
            }
        }
    }

    // MARK: - Option Checkboxes Per Tab
    @ViewBuilder
    private var optionsCheckboxesForCurrentTab: some View {
        switch appState.findDialogTab {
        case .find, .replace:
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Backward direction", isOn: $appState.searchBackward)
                Toggle("Match whole word only", isOn: $appState.searchWholeWord)
                Toggle("Match case", isOn: $appState.searchCaseSensitive)
                Toggle("Wrap around", isOn: $appState.searchWrapAround)
            }
            .font(.system(size: 11))
            .toggleStyle(.checkbox)
            .padding(.leading, 88)

        case .findInFiles:
            HStack(alignment: .top, spacing: 30) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Match whole word only", isOn: $appState.searchWholeWord)
                    Toggle("Match case", isOn: $appState.searchCaseSensitive)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("In all sub-folders", isOn: $appState.searchInSubfolders)
                    Toggle("In hidden folders", isOn: $appState.searchInHiddenFolders)
                }
            }
            .font(.system(size: 11))
            .toggleStyle(.checkbox)
            .padding(.leading, 88)

        case .findInProjects:
            HStack(alignment: .top, spacing: 30) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Match whole word only", isOn: $appState.searchWholeWord)
                    Toggle("Match case", isOn: $appState.searchCaseSensitive)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Project Panel 1", isOn: $appState.projectPanel1)
                    Toggle("Project Panel 2", isOn: $appState.projectPanel2)
                    Toggle("Project Panel 3", isOn: $appState.projectPanel3)
                }
            }
            .font(.system(size: 11))
            .toggleStyle(.checkbox)
            .padding(.leading, 88)

        case .mark:
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Bookmark line", isOn: $appState.markBookmarkLine)
                Toggle("Purge for each search", isOn: $appState.markPurgeForSearch)
                Toggle("Backward direction", isOn: $appState.searchBackward)
                Toggle("Match whole word only", isOn: $appState.searchWholeWord)
                Toggle("Match case", isOn: $appState.searchCaseSensitive)
                Toggle("Wrap around", isOn: $appState.searchWrapAround)
            }
            .font(.system(size: 11))
            .toggleStyle(.checkbox)
            .padding(.leading, 88)
        }
    }

    // MARK: - Search Mode Card
    private var searchModeCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Search Mode")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Button(action: {
                    appState.searchMode = .normal
                }) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.secondary, lineWidth: 1.5)
                                .frame(width: 14, height: 14)
                            if appState.searchMode == .normal {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        Text("Normal")
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: {
                    appState.searchMode = .extended
                }) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.secondary, lineWidth: 1.5)
                                .frame(width: 14, height: 14)
                            if appState.searchMode == .extended {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        Text("Extended (\\n, \\r, \\t, \\0, \\x...)")
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    Button(action: {
                        appState.searchMode = .regex
                    }) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color.secondary, lineWidth: 1.5)
                                    .frame(width: 14, height: 14)
                                if appState.searchMode == .regex {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            Text("Regular expression")
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Toggle(". matches newline", isOn: $appState.searchDotMatchesNewline)
                        .font(.system(size: 10))
                        .toggleStyle(.checkbox)
                        .disabled(appState.searchMode != .regex)
                }

                if appState.findDialogTab == .find {
                    Button(action: {
                        appState.searchMode = .fuzzy
                    }) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color.secondary, lineWidth: 1.5)
                                    .frame(width: 14, height: 14)
                                if appState.searchMode == .fuzzy {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            Text("Fuzzy search")
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Transparency Card
    private var transparencyCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Transparency", isOn: $appState.transparencyEnabled)
                .font(.system(size: 11, weight: .medium))
                .toggleStyle(.checkbox)
                .onChange(of: appState.transparencyEnabled) {
                    NotepadPlusFindWindowController.shared.updateTitleAndOpacity()
                }

            VStack(alignment: .leading, spacing: 3) {
                Button(action: {
                    appState.transparencyMode = .onLosingFocus
                    NotepadPlusFindWindowController.shared.updateTitleAndOpacity()
                }) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.secondary, lineWidth: 1.5)
                                .frame(width: 14, height: 14)
                            if appState.transparencyMode == .onLosingFocus {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        Text("On losing focus")
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: {
                    appState.transparencyMode = .always
                    NotepadPlusFindWindowController.shared.updateTitleAndOpacity()
                }) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.secondary, lineWidth: 1.5)
                                .frame(width: 14, height: 14)
                            if appState.transparencyMode == .always {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        Text("Always")
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Slider(value: $appState.transparencyOpacity, in: 0.2...1.0)
                    .disabled(!appState.transparencyEnabled)
                    .onChange(of: appState.transparencyOpacity) {
                        NotepadPlusFindWindowController.shared.updateTitleAndOpacity()
                    }
            }
            .padding(.leading, 12)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Action Buttons Stack Per Tab
    @ViewBuilder
    private var actionButtonsForCurrentTab: some View {
        switch appState.findDialogTab {
        case .find:
            Button("Find Next") {
                appState.findNext()
            }
            .keyboardShortcut(.defaultAction)
            .frame(maxWidth: .infinity)

            Button("Count") {
                appState.countMatches()
            }
            .frame(maxWidth: .infinity)

            Button("Find in Current Document") {
                appState.findInCurrentDocument()
            }
            .frame(maxWidth: .infinity)

            Button("Find in All Documents") {
                appState.findInAllDocuments()
            }
            .frame(maxWidth: .infinity)

        case .replace:
            Button("Find Next") {
                appState.findNext()
            }
            .keyboardShortcut(.defaultAction)
            .frame(maxWidth: .infinity)

            Button("Replace") {
                appState.performReplace()
            }
            .frame(maxWidth: .infinity)

            Button("Replace All") {
                appState.performReplaceAll()
            }
            .frame(maxWidth: .infinity)

            Button("Replace in All Documents") {
                appState.replaceInAllDocuments()
            }
            .frame(maxWidth: .infinity)

        case .findInFiles:
            Button("Find All") {
                appState.findInFiles()
            }
            .keyboardShortcut(.defaultAction)
            .frame(maxWidth: .infinity)

            Button("Replace in Files") {
                appState.replaceInFiles()
            }
            .frame(maxWidth: .infinity)

        case .findInProjects:
            Button("Find All") {
                appState.findInProjects()
            }
            .keyboardShortcut(.defaultAction)
            .frame(maxWidth: .infinity)

            Button("Replace in Projects") {
                appState.replaceInProjects()
            }
            .frame(maxWidth: .infinity)

        case .mark:
            Button("Mark All") {
                appState.markAll()
            }
            .keyboardShortcut(.defaultAction)
            .frame(maxWidth: .infinity)

            Button("Clear all marks") {
                appState.clearAllMarksInActiveDocument()
            }
            .frame(maxWidth: .infinity)

            Button("Copy Marked Text") {
                appState.copyMarkedText()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Folder"
        if panel.runModal() == .OK, let url = panel.url {
            appState.searchDirectory = url.path
        }
    }
}

// MARK: - Radio Button Helper View
private struct RadioButton: View {
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .strokeBorder(Color.secondary, lineWidth: 1.5)
                .background(Circle().fill(selected ? Color.accentColor : Color.clear).padding(3))
                .frame(width: 14, height: 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modeless Floating Window Controller (NSPanel with Live Transparency)
public final class NotepadPlusFindWindowController: NSObject, NSWindowDelegate {
    public static let shared = NotepadPlusFindWindowController()
    public private(set) var window: NSPanel?
    private weak var currentAppState: AppStateManager?

    public func show(appState: AppStateManager, tab: FindDialogTab? = nil) {
        self.currentAppState = appState
        if let targetTab = tab {
            appState.findDialogTab = targetTab
        }

        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 710, height: 380),
                styleMask: [.titled, .closable, .utilityWindow],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.becomesKeyOnlyIfNeeded = false
            panel.acceptsMouseMovedEvents = true
            panel.title = appState.findDialogTab.rawValue
            panel.center()
            panel.isReleasedWhenClosed = false
            panel.delegate = self
            panel.hidesOnDeactivate = false
            panel.contentView = NSHostingView(rootView: NotepadPlusFindDialogView(appState: appState))
            self.window = panel
        } else {
            window?.contentView = NSHostingView(rootView: NotepadPlusFindDialogView(appState: appState))
        }

        updateTitleAndOpacity()
        window?.makeKeyAndOrderFront(nil)
    }

    public func updateTitleAndOpacity() {
        guard let panel = window, let appState = currentAppState else { return }
        panel.title = appState.findDialogTab.rawValue

        if appState.transparencyEnabled {
            if appState.transparencyMode == .always {
                panel.alphaValue = CGFloat(appState.transparencyOpacity)
            } else {
                panel.alphaValue = panel.isKeyWindow ? 1.0 : CGFloat(appState.transparencyOpacity)
            }
        } else {
            panel.alphaValue = 1.0
        }
    }

    public func close() {
        window?.orderOut(nil)
        currentAppState?.showFindWindow = false
    }

    public func windowDidBecomeKey(_ notification: Notification) {
        updateTitleAndOpacity()
    }

    public func windowDidResignKey(_ notification: Notification) {
        updateTitleAndOpacity()
    }

    public func windowWillClose(_ notification: Notification) {
        currentAppState?.showFindWindow = false
    }
}
