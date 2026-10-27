import SwiftUI
import AppKit

// View state lives in an ObservableObject: this package builds with the command-line toolchain, which has no @State macro plugin.
final class PluginManagerUIState: ObservableObject {
    @Published var tab: PluginManagerTab? = .installed
    @Published var selectedID: String?
    @Published var searchText = ""
    @Published var category: PluginCategory = .all
    @Published var pendingUninstall: PluginInfo?
}

// MARK: - Plugin Manager (standard macOS window: sidebar, list, inspector)
public struct PluginManagerView: View {
    @ObservedObject var appState: AppStateManager
    @ObservedObject var registry = PluginRegistry.shared
    @StateObject private var ui = PluginManagerUIState()

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    private var currentTab: PluginManagerTab { ui.tab ?? .installed }

    private func plugins(in tab: PluginManagerTab) -> [PluginInfo] {
        registry.plugins.filter { plugin in
            switch tab {
            case .installed: return plugin.isInstalled && plugin.isEnabled
            case .available: return !plugin.isInstalled
            case .updates: return plugin.isInstalled && plugin.availableVersion != nil
            case .disabled: return plugin.isInstalled && !plugin.isEnabled
            }
        }
    }

    private var visiblePlugins: [PluginInfo] {
        plugins(in: currentTab).filter { plugin in
            if ui.category != .all && plugin.category != ui.category { return false }
            let q = ui.searchText.trimmingCharacters(in: .whitespaces)
            if q.isEmpty { return true }
            return plugin.name.localizedCaseInsensitiveContains(q)
                || plugin.summary.localizedCaseInsensitiveContains(q)
                || plugin.author.localizedCaseInsensitiveContains(q)
        }
    }

    private var selectedPlugin: PluginInfo? {
        guard let id = ui.selectedID else { return nil }
        return registry.plugins.first { $0.id == id }
    }

    public var body: some View {
        NavigationSplitView {
            List(PluginManagerTab.allCases, selection: $ui.tab) { section in
                Label(section.rawValue, systemImage: section.iconName)
                    .badge(plugins(in: section).count)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 170, max: 220)
        } content: {
            pluginList
                .navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 480)
        } detail: {
            if let plugin = selectedPlugin {
                PluginInspector(plugin: plugin, registry: registry, onUninstall: { ui.pendingUninstall = plugin })
            } else {
                ContentUnavailableView("No Plugin Selected", systemImage: "puzzlepiece.extension",
                                       description: Text("Select a plugin to see its details."))
            }
        }
        .navigationTitle("Plugin Manager")
        .searchable(text: $ui.searchText, placement: .toolbar, prompt: "Search Plugins")
        .toolbar {
            ToolbarItem {
                Picker("Category", selection: $ui.category) {
                    ForEach(PluginCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.iconName).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .help("Filter by category")
            }
            ToolbarItem {
                Button {
                    Task { await registry.refreshCatalog() }
                } label: {
                    Label("Refresh Catalog", systemImage: "arrow.clockwise")
                }
                .disabled(registry.isLoadingCatalog)
                .help("Check the online catalog for new plugins and updates")
            }
        }
        .task {
            if !registry.hasLoadedCatalog { await registry.refreshCatalog() }
        }
        .onChange(of: ui.tab) { _, _ in ui.selectedID = visiblePlugins.first?.id }
        .alert("Plugin Manager", isPresented: Binding(
            get: { registry.lastError != nil },
            set: { if !$0 { registry.lastError = nil } }
        )) {
            Button("OK", role: .cancel) { registry.lastError = nil }
        } message: {
            Text(registry.lastError ?? "")
        }
        .confirmationDialog(
            "Remove \(ui.pendingUninstall?.name ?? "plugin")?",
            isPresented: Binding(get: { ui.pendingUninstall != nil }, set: { if !$0 { ui.pendingUninstall = nil } }),
            titleVisibility: .visible
        ) {
            Button("Uninstall", role: .destructive) {
                if let plugin = ui.pendingUninstall { registry.uninstallPlugin(plugin.id) }
                ui.pendingUninstall = nil
            }
            Button("Cancel", role: .cancel) { ui.pendingUninstall = nil }
        } message: {
            Text("You can install it again from the Available section.")
        }
    }

    private var pluginList: some View {
        List(visiblePlugins, selection: $ui.selectedID) { plugin in
            PluginRow(plugin: plugin, isBusy: registry.busyPluginIDs.contains(plugin.id)) {
                Task {
                    if plugin.isInstalled { await registry.updatePlugin(plugin.id) } else { await registry.installPlugin(plugin.id) }
                }
            }
            .tag(plugin.id)
        }
        .overlay {
            if visiblePlugins.isEmpty {
                if registry.isLoadingCatalog && currentTab == .available {
                    ProgressView("Loading catalog…")
                } else if ui.searchText.isEmpty && ui.category == .all {
                    ContentUnavailableView("Nothing Here", systemImage: currentTab.iconName,
                                           description: Text(emptyMessage))
                } else {
                    ContentUnavailableView.search(text: ui.searchText)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let error = registry.catalogError {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark").foregroundStyle(.orange)
                    Text(error).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    Spacer(minLength: 0)
                    Button("Retry") { Task { await registry.refreshCatalog() } }.controlSize(.small)
                }
                .padding(8)
                .background(.bar)
            }
        }
    }

    private var emptyMessage: String {
        switch currentTab {
        case .installed: return "No plugins are installed and enabled."
        case .available: return "Every plugin in the catalog is already installed."
        case .updates: return "All your plugins are up to date."
        case .disabled: return "You haven't turned off any plugins."
        }
    }
}

// MARK: - List row
private struct PluginRow: View {
    let plugin: PluginInfo
    let isBusy: Bool
    let onPrimaryAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: plugin.icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.name).font(.headline).lineLimit(1)
                Text(plugin.summary).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                Text("\(plugin.author) · v\(plugin.version)")
                    .font(.caption).foregroundStyle(.tertiary)
            }

            Spacer(minLength: 8)

            if isBusy {
                ProgressView().controlSize(.small)
            } else if !plugin.isInstalled {
                Button("Get", action: onPrimaryAction)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            } else if plugin.availableVersion != nil {
                Button("Update", action: onPrimaryAction)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Inspector
private struct PluginInspector: View {
    let plugin: PluginInfo
    @ObservedObject var registry: PluginRegistry
    let onUninstall: () -> Void

    private var isBusy: Bool { registry.busyPluginIDs.contains(plugin.id) }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: plugin.icon)
                        .font(.system(size: 34))
                        .foregroundStyle(.tint)
                        .frame(width: 56, height: 56)
                        .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plugin.name).font(.title2.bold())
                        Text("\(plugin.author) · Version \(plugin.version)").foregroundStyle(.secondary)
                    }
                    Spacer()
                    actionButtons
                }
                .padding(.vertical, 4)
            }

            if plugin.isInstalled {
                Section {
                    Toggle("Enabled", isOn: Binding(get: { plugin.isEnabled }, set: { _ in registry.togglePlugin(plugin.id) }))
                }
            }

            Section("About") {
                Text(plugin.documentation).foregroundStyle(.secondary)
            }

            if !plugin.commands.isEmpty {
                Section("Commands") {
                    ForEach(plugin.commands) { command in
                        Text(command.title)
                    }
                    Text("Find them under the Plugins menu while the plugin is installed and enabled.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }

            Section("Details") {
                LabeledContent("Category", value: plugin.category.rawValue)
                LabeledContent("License", value: plugin.license)
                LabeledContent("Source", value: plugin.source == .builtIn ? "Built in" : "Open-source community plugin")
                if let latest = plugin.availableVersion {
                    LabeledContent("Update available", value: "v\(latest)")
                }
                if let homepage = plugin.homepage {
                    LabeledContent("Website") { Link(homepage.host ?? "Open", destination: homepage) }
                }
                if let sha = plugin.sha256 {
                    LabeledContent("SHA-256") {
                        Text(sha).font(.caption.monospaced()).textSelection(.enabled).lineLimit(2)
                    }
                }
            }

            if plugin.source == .community {
                Section {
                    Label("Runs in a sandbox with no access to your files, network or other apps. It only sees the text you run it on, and every download is checked against a published checksum.",
                          systemImage: "lock.shield")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder private var actionButtons: some View {
        if isBusy {
            ProgressView().controlSize(.small)
        } else if !plugin.isInstalled {
            Button("Install") { Task { await registry.installPlugin(plugin.id) } }
                .buttonStyle(.borderedProminent)
        } else {
            if plugin.availableVersion != nil {
                Button("Update") { Task { await registry.updatePlugin(plugin.id) } }
                    .buttonStyle(.borderedProminent)
            }
            Button("Uninstall", role: .destructive, action: onUninstall)
        }
    }
}
