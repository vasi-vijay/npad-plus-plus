import SwiftUI
import AppKit

// MARK: - Native Welcome Window Controller
public class NativeWelcomeWindowController: NSObject, NSWindowDelegate {
    public static let shared = NativeWelcomeWindowController()

    private var window: NSWindow?
    private weak var appState: AppStateManager?

    private override init() {
        super.init()
    }

    public func show(appState: AppStateManager, showFeatures: Bool = false) {
        self.appState = appState
        appState.welcomeExploreFeaturesActive = showFeatures

        if window == nil {
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 480),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            win.center()
            win.title = showFeatures ? "NPad++ Features" : "Welcome to NPad++"
            win.titleVisibility = .hidden
            win.titlebarAppearsTransparent = true
            win.isReleasedWhenClosed = false
            win.isMovableByWindowBackground = true
            win.delegate = self
            self.window = win
        }

        let hostView = NativeWelcomeHostView(appState: appState) { [weak self] in
            self?.close()
        }
        window?.contentViewController = NSHostingController(rootView: hostView)
        window?.title = showFeatures ? "NPad++ Features" : "Welcome to NPad++"
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func close() {
        window?.orderOut(nil)
        appState?.showWelcomeSheet = false
    }

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        close()
        return false
    }
}

// MARK: - Native Welcome Host View (Macro-free)
public struct NativeWelcomeHostView: View {
    @ObservedObject var appState: AppStateManager
    let onClose: () -> Void

    public init(appState: AppStateManager, onClose: @escaping () -> Void) {
        self.appState = appState
        self.onClose = onClose
    }

    public var body: some View {
        Group {
            if appState.welcomeExploreFeaturesActive {
                NativeFeaturesContentView(appState: appState, onClose: onClose)
            } else {
                NativeWelcomeContentView(appState: appState, onClose: onClose)
            }
        }
        .frame(width: 560, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Native Welcome Content View (Macro-free)
public struct NativeWelcomeContentView: View {
    @ObservedObject var appState: AppStateManager
    let onClose: () -> Void

    public init(appState: AppStateManager, onClose: @escaping () -> Void) {
        self.appState = appState
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Native Title & Top Space for Traffic Lights
            VStack(spacing: 6) {
                if let icon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 60, height: 60)
                } else {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 44))
                        .foregroundColor(.accentColor)
                }

                Text("Welcome to NPad++")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text("A fast, native code editor for macOS Apple Silicon.")
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)
            .padding(.bottom, 16)

            // Quick Actions List
            VStack(spacing: 6) {
                NativeWelcomeActionRow(
                    icon: "doc.badge.plus",
                    iconColor: .blue,
                    title: "New File",
                    subtitle: "Create a new document and start typing immediately."
                ) {
                    appState.createNewDocument()
                    appState.markWelcomeCompleted()
                    onClose()
                }

                NativeWelcomeActionRow(
                    icon: "doc",
                    iconColor: .orange,
                    title: "Open File...",
                    subtitle: "Open an existing file from disk with syntax highlighting."
                ) {
                    onClose()
                    appState.openDocument()
                }

                NativeWelcomeActionRow(
                    icon: "folder",
                    iconColor: .teal,
                    title: "Open Folder...",
                    subtitle: "Browse and manage files in the project tree explorer."
                ) {
                    onClose()
                    appState.openFolder()
                }

                NativeWelcomeActionRow(
                    icon: "sparkles",
                    iconColor: .purple,
                    title: "Explore Features",
                    subtitle: "Learn about dual-pane editing, diffs, terminal runner, and plugins."
                ) {
                    appState.welcomeExploreFeaturesActive = true
                }

                NativeWelcomeActionRow(
                    icon: "camera.fill",
                    iconColor: .pink,
                    title: "Made By Vijay",
                    subtitle: "Follow @made.by.vijay on Instagram."
                ) {
                    if let url = URL(string: AppStateManager.authorInstagramURL) {
                        NSWorkspace.shared.open(url)
                    }
                }

                NativeWelcomeActionRow(
                    icon: "arrow.up.right.square",
                    iconColor: .gray,
                    title: "GitHub Repository",
                    subtitle: "View source code, report issues, and star the project."
                ) {
                    if let url = URL(string: AppStateManager.githubRepositoryURL) {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            Divider()

            // Bottom Bar: Dismissal Checkbox and Get Started
            HStack {
                Toggle("Don't show this again on startup", isOn: Binding(
                    get: { appState.hasCompletedWelcome },
                    set: { val in appState.hasCompletedWelcome = val }
                ))
                .font(.system(size: 11.5))
                .foregroundColor(.secondary)

                Spacer()

                Button("Get Started") {
                    appState.markWelcomeCompleted()
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        }
    }
}

// MARK: - Native Welcome Action Row
public struct NativeWelcomeActionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    public init(icon: String, iconColor: Color, title: String, subtitle: String, action: @escaping () -> Void) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(iconColor.opacity(0.12))
                    .cornerRadius(6)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.45))
        .cornerRadius(6)
    }
}

// MARK: - Native Features Content View (Macro-free)
public struct NativeFeaturesContentView: View {
    @ObservedObject var appState: AppStateManager
    let onClose: () -> Void

    public init(appState: AppStateManager, onClose: @escaping () -> Void) {
        self.appState = appState
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar with Back Button
            HStack(spacing: 8) {
                Button(action: {
                    appState.welcomeExploreFeaturesActive = false
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 11, weight: .bold))
                        Text("Back")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("NPad++ Features")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                // Balance spacing
                Color.clear.frame(width: 44, height: 1)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            // Scrollable Verified Features
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 10) {
                    NativeFeatureRow(
                        icon: "rectangle.split.2x1",
                        iconColor: .blue,
                        title: "Dual-Pane Editing",
                        description: "Side-by-side editing, independent tabs, draggable split divider, and tab drag-and-drop between panes."
                    )

                    NativeFeatureRow(
                        icon: "arrow.left.and.right.square",
                        iconColor: .green,
                        title: "File Comparison",
                        description: "Notepad++-style visual diff, synchronized scrolling, character-level diff highlighting, and diff navigation."
                    )

                    NativeFeatureRow(
                        icon: "curlybraces",
                        iconColor: .purple,
                        title: "Syntax Highlighting",
                        description: "Fast, real-time syntax coloring for Swift, Python, Java, JavaScript, HTML, C++, XML, JSON, and Markdown."
                    )

                    NativeFeatureRow(
                        icon: "magnifyingglass",
                        iconColor: .orange,
                        title: "Search & Replace",
                        description: "High-performance search, regular expressions, whole word, match case, text marks, and find across project files."
                    )

                    NativeFeatureRow(
                        icon: "terminal",
                        iconColor: .pink,
                        title: "Developer Tools",
                        description: "Integrated developer terminal (^`), direct one-click code runner (F5), line operations, and Base64 encode/decode tools."
                    )

                    NativeFeatureRow(
                        icon: "slider.horizontal.3",
                        iconColor: .teal,
                        title: "Customization & Plugins",
                        description: "Classic Notepad++ theme, dark/light modes, customizable fonts, word wrap, tab sizing, and extensible plugins."
                    )
                }
                .padding(16)
            }

            Divider()

            // Bottom Bar: GitHub, Made By Vijay & Start Coding
            HStack(spacing: 12) {
                Button(action: {
                    if let url = URL(string: AppStateManager.authorInstagramURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.pink)
                        Text("Made By Vijay")
                    }
                    .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button(action: {
                    if let url = URL(string: AppStateManager.githubRepositoryURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("GitHub", systemImage: "link")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Button("Start Coding") {
                    appState.markWelcomeCompleted()
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        }
    }
}

// MARK: - Native Feature Row
public struct NativeFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    public init(icon: String, iconColor: Color, title: String, description: String) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.description = description
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(iconColor)
                .frame(width: 26, height: 26)
                .background(iconColor.opacity(0.12))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.45))
        .cornerRadius(6)
    }
}
