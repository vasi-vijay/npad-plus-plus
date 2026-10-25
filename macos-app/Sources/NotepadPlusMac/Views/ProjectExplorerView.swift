import SwiftUI
import AppKit

// MARK: - Project Explorer Tree View (Macro-free)
public struct ProjectExplorerView: View {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Project Header
            HStack(spacing: 6) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 11))
                    .foregroundColor(.accentColor)

                Text(appState.workspaceRootURL?.lastPathComponent.uppercased() ?? "PROJECT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                // Quick Action Icons
                if appState.workspaceRootURL != nil {
                    Button(action: {
                        appState.explorerTargetFolderURL = appState.workspaceRootURL
                        appState.explorerInputName = ""
                        appState.explorerNewFileDialogPresented = true
                    }) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("New File in Project")
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }

                    Button(action: {
                        appState.explorerTargetFolderURL = appState.workspaceRootURL
                        appState.explorerInputName = ""
                        appState.explorerNewFolderDialogPresented = true
                    }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("New Folder in Project")
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }

                    Button(action: {
                        appState.refreshProject()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("Refresh Explorer")
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }

                    Button(action: {
                        appState.closeFolder()
                    }) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("Close Project Folder")
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
            .overlay(Divider(), alignment: .bottom)
            .contextMenu {
                if appState.workspaceRootURL != nil {
                    Button("New File in Project...") {
                        appState.explorerTargetFolderURL = appState.workspaceRootURL
                        appState.explorerInputName = ""
                        appState.explorerNewFileDialogPresented = true
                    }
                    Button("New Folder in Project...") {
                        appState.explorerTargetFolderURL = appState.workspaceRootURL
                        appState.explorerInputName = ""
                        appState.explorerNewFolderDialogPresented = true
                    }
                    Divider()
                    Button("Refresh Project") { appState.refreshProject() }
                    Divider()
                    Button("Close Folder") { appState.closeFolder() }
                }
            }

            // Tree Content
            if let root = appState.projectRootItem {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        if let children = root.children {
                            ForEach(children) { child in
                                ProjectItemRow(
                                    item: child,
                                    depth: 0,
                                    appState: appState,
                                    onNewFile: { url in
                                        appState.explorerTargetFolderURL = url
                                        appState.explorerInputName = ""
                                        appState.explorerNewFileDialogPresented = true
                                    },
                                    onNewFolder: { url in
                                        appState.explorerTargetFolderURL = url
                                        appState.explorerInputName = ""
                                        appState.explorerNewFolderDialogPresented = true
                                    },
                                    onRename: { url in
                                        appState.explorerTargetItemURL = url
                                        appState.explorerInputName = url.lastPathComponent
                                        appState.explorerRenameDialogPresented = true
                                    },
                                    onDelete: { url in
                                        appState.explorerTargetItemURL = url
                                        appState.explorerDeleteAlertPresented = true
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "folder")
                        .font(.system(size: 26))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("No Folder Open")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Button("Open Folder...") {
                        appState.openFolder()
                    }
                    .font(.system(size: 11))
                    .controlSize(.small)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Sheet: New File
        .sheet(isPresented: $appState.explorerNewFileDialogPresented) {
            VStack(alignment: .leading, spacing: 10) {
                Text("New File").font(.headline)
                TextField("e.g. App.java, styles.css", text: $appState.explorerInputName)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Spacer()
                    Button("Cancel") { appState.explorerNewFileDialogPresented = false }
                    Button("Create") {
                        if let folder = appState.explorerTargetFolderURL ?? appState.workspaceRootURL {
                            if let newURL = try? ProjectExplorerService.createFile(in: folder, name: appState.explorerInputName) {
                                appState.refreshProject()
                                appState.openFileFromProject(url: newURL)
                            }
                        }
                        appState.explorerNewFileDialogPresented = false
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(appState.explorerInputName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(16)
            .frame(width: 280)
        }
        // Sheet: New Folder
        .sheet(isPresented: $appState.explorerNewFolderDialogPresented) {
            VStack(alignment: .leading, spacing: 10) {
                Text("New Folder").font(.headline)
                TextField("Folder name", text: $appState.explorerInputName)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Spacer()
                    Button("Cancel") { appState.explorerNewFolderDialogPresented = false }
                    Button("Create") {
                        if let folder = appState.explorerTargetFolderURL ?? appState.workspaceRootURL {
                            _ = try? ProjectExplorerService.createFolder(in: folder, name: appState.explorerInputName)
                            appState.refreshProject()
                        }
                        appState.explorerNewFolderDialogPresented = false
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(appState.explorerInputName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(16)
            .frame(width: 280)
        }
        // Sheet: Rename
        .sheet(isPresented: $appState.explorerRenameDialogPresented) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Rename").font(.headline)
                TextField("New name", text: $appState.explorerInputName)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Spacer()
                    Button("Cancel") { appState.explorerRenameDialogPresented = false }
                    Button("Rename") {
                        if let itemURL = appState.explorerTargetItemURL {
                            _ = try? ProjectExplorerService.rename(at: itemURL, newName: appState.explorerInputName)
                            appState.refreshProject()
                        }
                        appState.explorerRenameDialogPresented = false
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(appState.explorerInputName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(16)
            .frame(width: 280)
        }
        // Confirmation Alert: Delete
        .alert(isPresented: $appState.explorerDeleteAlertPresented) {
            Alert(
                title: Text("Delete Item?"),
                message: Text("Are you sure you want to delete '\(appState.explorerTargetItemURL?.lastPathComponent ?? "")'? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let itemURL = appState.explorerTargetItemURL {
                        _ = try? ProjectExplorerService.delete(at: itemURL)
                        appState.refreshProject()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Recursive Project Item Row
public struct ProjectItemRow: View {
    @ObservedObject var item: ProjectItem
    let depth: Int
    @ObservedObject var appState: AppStateManager

    let onNewFile: (URL) -> Void
    let onNewFolder: (URL) -> Void
    let onRename: (URL) -> Void
    let onDelete: (URL) -> Void

    private var isSelected: Bool {
        if let activeDoc = appState.activeDocument, let fileURL = activeDoc.fileURL {
            return fileURL.standardizedFileURL == item.url.standardizedFileURL
        }
        return appState.selectedProjectItemURL?.standardizedFileURL == item.url.standardizedFileURL
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                // Indentation
                if depth > 0 {
                    Spacer().frame(width: CGFloat(depth * 14))
                }

                // Disclosure Chevron for Directories
                if item.isDirectory {
                    Button(action: {
                        item.isExpanded.toggle()
                    }) {
                        Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer().frame(width: 12)
                }

                // Item Icon
                Image(systemName: item.systemIcon)
                    .font(.system(size: 11))
                    .foregroundColor(item.iconColor)
                    .frame(width: 14)

                // Item Name
                Text(item.name)
                    .font(.system(size: 11.5))
                    .foregroundColor(isSelected ? .accentColor : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()
            }
            .padding(.vertical, 2.5)
            .padding(.horizontal, 6)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .onTapGesture {
                if item.isDirectory {
                    item.isExpanded.toggle()
                } else {
                    appState.openFileFromProject(url: item.url)
                }
            }
            .onDrag {
                if item.isDirectory {
                    return NSItemProvider()
                } else {
                    return NSItemProvider(object: item.url as NSURL)
                }
            }
            .contextMenu {
                if item.isDirectory {
                    Button("New File Here...") { onNewFile(item.url) }
                    Button("New Folder Here...") { onNewFolder(item.url) }
                    Divider()
                    Button("Refresh Directory") { appState.refreshProject() }
                    Divider()
                    Button("Reveal in Finder") { ProjectExplorerService.revealInFinder(at: item.url) }
                    Button("Open Terminal Here") { _ = appState.changeTerminalDirectory(to: item.url.path) }
                    Divider()
                    Button("Rename...") { onRename(item.url) }
                    Button("Delete Folder...") { onDelete(item.url) }
                    Divider()
                    Button("Close Folder") { appState.closeFolder() }
                } else {
                    Button("Open in Active Editor") { appState.openFileFromProject(url: item.url) }
                    if appState.isSplitViewActive {
                        Button("Open in Left Pane") { appState.openFileFromProject(url: item.url, inPane: .left) }
                        Button("Open in Right Pane") { appState.openFileFromProject(url: item.url, inPane: .right) }
                    }
                    Divider()
                    Button("Reveal in Finder") { ProjectExplorerService.revealInFinder(at: item.url) }
                    Button("Open Terminal Here") { _ = appState.changeTerminalDirectory(to: item.url.deletingLastPathComponent().path) }
                    Divider()
                    Button("Rename...") { onRename(item.url) }
                    Button("Delete File...") { onDelete(item.url) }
                }
            }

            // Recursive Children
            if item.isDirectory && item.isExpanded, let children = item.children {
                ForEach(children) { child in
                    ProjectItemRow(
                        item: child,
                        depth: depth + 1,
                        appState: appState,
                        onNewFile: onNewFile,
                        onNewFolder: onNewFolder,
                        onRename: onRename,
                        onDelete: onDelete
                    )
                }
            }
        }
    }
}
