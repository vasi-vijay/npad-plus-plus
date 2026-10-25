import SwiftUI
import AppKit

// MARK: - Documentation and Support View (Macro-free)
public struct DocumentationAndSupportView: View {
    @ObservedObject var appState: AppStateManager

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 14) {
                if let icon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 44, height: 44)
                } else {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("NPad++ Documentation & Support")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Fast, native Apple Silicon code and text editor")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    appState.showDocumentationSheet = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Documentation")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(Divider(), alignment: .bottom)

            // Category Segmented Control
            Picker("", selection: $appState.documentationSelectedTab) {
                Text("Shortcuts").tag("Shortcuts")
                Text("Features").tag("Features")
                Text("Plugins").tag("Plugins")
                Text("Community & Support").tag("Support")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            Divider()

            // Content Area
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    if appState.documentationSelectedTab == "Shortcuts" {
                        shortcutsSection
                    } else if appState.documentationSelectedTab == "Features" {
                        featuresSection
                    } else if appState.documentationSelectedTab == "Plugins" {
                        pluginsSection
                    } else {
                        communitySupportSection
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Footer with GitHub and Action Buttons
            HStack {
                Button(action: {
                    if let url = URL(string: AppStateManager.githubRepositoryURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("GitHub Repository", systemImage: "link")
                }

                Button(action: {
                    if let url = URL(string: AppStateManager.githubIssuesURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("Report Issue", systemImage: "exclamationmark.bubble")
                }

                Spacer()

                Button("Done") {
                    appState.showDocumentationSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.regular)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        }
        .frame(width: 650, height: 520)
    }

    // MARK: - Shortcuts Tab
    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            shortcutCategory(
                title: "File Operations",
                items: [
                    ("⌘N", "New Document"),
                    ("⌘O", "Open File..."),
                    ("⌘S", "Save Document"),
                    ("⇧⌘S", "Save As..."),
                    ("⌘W", "Close Active Document")
                ]
            )

            shortcutCategory(
                title: "Editing & Cursor",
                items: [
                    ("⌘Z", "Undo Edit"),
                    ("⌘Y", "Redo Edit"),
                    ("⌘D", "Duplicate Current Line"),
                    ("⇧⌘K", "Delete Current Line"),
                    ("⌘J", "Join Lines"),
                    ("⌘/", "Toggle Line Comment"),
                    ("⌘M", "Mark Selected Text"),
                    ("⇧⌘M", "Clear Marks in Document")
                ]
            )

            shortcutCategory(
                title: "Search & Navigation",
                items: [
                    ("⌘F", "Find in File"),
                    ("⌘H", "Find and Replace"),
                    ("⇧⌘F", "Find in Files (Project Search)"),
                    ("⌘G", "Find Next Match"),
                    ("⇧⌘G", "Find Previous Match"),
                    ("⌘L", "Go to Line Number"),
                    ("⌘F2", "Toggle Bookmark on Current Line"),
                    ("F2", "Jump to Next Bookmark"),
                    ("⇧F2", "Jump to Previous Bookmark")
                ]
            )

            shortcutCategory(
                title: "View, Split & Compare",
                items: [
                    ("⌘B", "Toggle Project Sidebar"),
                    ("⌃`", "Toggle Developer Terminal"),
                    ("⌥Z", "Toggle Word Wrap"),
                    ("⌥⌘S", "Split Editor Vertically"),
                    ("⇧⌥⌘S", "Close Split View"),
                    ("⌥⌘W", "Swap Left and Right Editor Panes"),
                    ("⌥]", "Next Comparison Difference"),
                    ("⌥[", "Previous Comparison Difference"),
                    ("⌥1", "First Comparison Difference"),
                    ("⌥9", "Last Comparison Difference"),
                    ("⌥R", "Recompare / Refresh Comparison"),
                    ("⌥X", "Clear Comparison Mode")
                ]
            )

            shortcutCategory(
                title: "Run & Developer Tools",
                items: [
                    ("F5", "Run Current File in Terminal"),
                    ("⇧⌘B", "View in Default Browser (HTML / Web)"),
                    ("⇧⌘P", "Open Plugin Manager")
                ]
            )
        }
    }

    private func shortcutCategory(title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.accentColor)

            VStack(spacing: 4) {
                ForEach(items, id: \.0) { item in
                    HStack {
                        Text(item.0)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(NSColor.selectedControlTextColor).opacity(0.1))
                            .cornerRadius(4)
                            .frame(width: 80, alignment: .leading)

                        Text(item.1)
                            .font(.system(size: 11.5))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
        }
    }

    // MARK: - Features Tab
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureCard(
                icon: "folder.fill",
                title: "Hierarchical Project Explorer",
                description: "Open full project folders and navigate directories at any depth. Create files, folders, rename, delete with confirmation, and reveal in Finder directly from the sidebar."
            )

            featureCard(
                icon: "rectangle.split.2x1",
                title: "Side-by-Side Split View & File Comparison",
                description: "Work on two files simultaneously with independent scrolling, cursor position, undo/redo stacks, and syntax highlighting. Compare files with Eugene Myers diff algorithm, synchronized scrolling, and character-level difference highlighting."
            )

            featureCard(
                icon: "paintbrush.fill",
                title: "Editor Themes & Appearance",
                description: "Switch seamlessly between Auto, Light, and Dark macOS modes. Choose from 6 rich editor themes: NPad++ Classic, Dark Modern, Monokai, GitHub, Solarized Light, and Solarized Dark."
            )

            featureCard(
                icon: "terminal.fill",
                title: "Developer Terminal & Direct Execution",
                description: "Integrated zsh/bash terminal with working directory synchronization, quick command presets, Java runtime compilation, and F5 one-key execution."
            )
        }
    }

    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }

    // MARK: - Plugins Tab
    private var pluginsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Built-in Developer Plugins")
                .font(.system(size: 13, weight: .bold))

            Text("NPad++ includes high-utility developer plugins accessible from the Plugins menu or via the Plugin Manager (⇧⌘P):")
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                pluginItemRow(title: "JSON Formatter & Validator", desc: "Format, minify, and validate JSON payloads with syntax error reporting.")
                pluginItemRow(title: "XML Prettifier & Tools", desc: "Format and indent XML/HTML documents with hierarchical tag formatting.")
                pluginItemRow(title: "Markdown Live Viewer", desc: "Live preview and rendered HTML inspection for Markdown documents.")
                pluginItemRow(title: "Git Integration & SCM", desc: "Real-time branch detection and git status inspection.")
                pluginItemRow(title: "TODO & Task Tracker", desc: "Instant scanning for TODO, FIXME, NOTE, and BUG markers.")
                pluginItemRow(title: "Base64 & Line Utilities", desc: "Encode/decode Base64 strings, sort lines ascending/descending, and deduplicate lines.")
            }
        }
    }

    private func pluginItemRow(title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 12))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(6)
    }

    // MARK: - Community & Support Tab
    private var communitySupportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Open Source & Community")
                .font(.system(size: 13, weight: .bold))

            Text("NPad++ is developed openly. You can report bugs, submit feature requests, inspect the source code, and track future releases directly on GitHub:")
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                linkBox(
                    title: "Official GitHub Repository",
                    subtitle: AppStateManager.githubRepositoryURL,
                    icon: "arrow.triangle.branch",
                    url: AppStateManager.githubRepositoryURL
                )

                linkBox(
                    title: "Issue Tracker & Bug Reports",
                    subtitle: AppStateManager.githubIssuesURL,
                    icon: "exclamationmark.bubble.fill",
                    url: AppStateManager.githubIssuesURL
                )

                linkBox(
                    title: "Releases & Updates",
                    subtitle: "\(AppStateManager.githubRepositoryURL)/releases",
                    icon: "sparkles",
                    url: "\(AppStateManager.githubRepositoryURL)/releases"
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Version Information")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)

                Text("NPad++ v1.0.0 (Apple Silicon native arm64)\nBuilt with native Swift and AppKit/SwiftUI on macOS.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)
        }
    }

    private func linkBox(title: String, subtitle: String, icon: String, url: String) -> some View {
        Button(action: {
            if let targetURL = URL(string: url) {
                NSWorkspace.shared.open(targetURL)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
