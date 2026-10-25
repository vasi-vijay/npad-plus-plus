import SwiftUI
import AppKit

@main
struct NotepadPlusApp: App {
    @StateObject private var appState = AppStateManager()

    var body: some Scene {
        WindowGroup("NPad++") {
            MainWindowView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
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
    }
}
