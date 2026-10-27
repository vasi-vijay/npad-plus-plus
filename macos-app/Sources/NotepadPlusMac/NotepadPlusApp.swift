import SwiftUI
import AppKit

/// Receives files opened from Finder ("Open With", double-click, `open -a`) and hands them to the app state.
/// URLs that arrive before the window has appeared (cold launch) are queued and flushed once a handler exists.
final class FileOpenCoordinator: NSObject, NSApplicationDelegate {
    private var pendingURLs: [URL] = []
    var handler: (([URL]) -> Void)? {
        didSet { flushPending() }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        pendingURLs.append(contentsOf: urls)
        flushPending()
    }

    private func flushPending() {
        guard let handler = handler, !pendingURLs.isEmpty else { return }
        let urls = pendingURLs
        pendingURLs.removeAll()
        DispatchQueue.main.async { handler(urls) }
    }
}

@main
struct NotepadPlusApp: App {
    @NSApplicationDelegateAdaptor(FileOpenCoordinator.self) private var fileOpenCoordinator
    @StateObject private var appState = AppStateManager()

    init() {
        // Show tooltips after ~0.3s instead of the long macOS default, so toolbar icons explain themselves quickly.
        UserDefaults.standard.set(300, forKey: "NSInitialToolTipDelay")
    }

    var body: some Scene {
        WindowGroup("NPad++") {
            MainWindowView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    fileOpenCoordinator.handler = { urls in
                        appState.openFilesInteractively(urls)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    appState.saveSessionToDisk()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                    appState.saveSessionToDisk()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About NPad++") {
                    let alert = NSAlert()
                    alert.messageText = "NPad++"
                    alert.informativeText = "Version 1.0.0 (Apple Silicon arm64)\n\nA powerful, high-performance source code and text editor for macOS.\n\nGitHub: \(AppStateManager.githubRepositoryURL)\n\nCopyright © 2026 NPad++. All rights reserved."
                    alert.alertStyle = .informational
                    alert.runModal()
                }
            }
            FileCommands(appState: appState)
            EditCommands(appState: appState)
            SearchCommands(appState: appState)
            ViewCommands(appState: appState)
            CompareCommands(appState: appState)
            EncodingCommands(appState: appState)
            LanguageCommands(appState: appState)
            RunCommands(appState: appState)
            PluginCommands(appState: appState)
            HelpCommands(appState: appState)
        }

        Window("Plugin Manager", id: PluginManagerWindow.id) {
            PluginManagerView(appState: appState)
                .frame(minWidth: 860, minHeight: 500)
        }
        .defaultSize(width: 980, height: 620)
    }
}
