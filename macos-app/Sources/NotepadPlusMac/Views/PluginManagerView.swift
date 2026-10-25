import SwiftUI
import AppKit

// MARK: - Plugin Manager Main Sheet View (Macro-free)
public struct PluginManagerView: View {
    @ObservedObject var appState: AppStateManager
    @ObservedObject var registry = PluginRegistry.shared

    public init(appState: AppStateManager) {
        self.appState = appState
    }

    private var filteredPlugins: [PluginInfo] {
        registry.plugins.filter { plugin in
            // Filter by Tab
            switch registry.selectedTab {
            case .installed:
                if !plugin.isInstalled || !plugin.isEnabled { return false }
            case .available:
                if plugin.isInstalled { return false }
            case .updates:
                if !plugin.isInstalled || plugin.availableVersion == nil { return false }
            case .disabled:
                if !plugin.isInstalled || plugin.isEnabled { return false }
            }

            // Filter by Category
            if registry.selectedCategory != .all && plugin.category != registry.selectedCategory {
                return false
            }

            // Filter by Search Query
            if !registry.searchText.isEmpty {
                let q = registry.searchText.lowercased()
                let matchesName = plugin.name.lowercased().contains(q)
                let matchesDesc = plugin.summary.lowercased().contains(q)
                if !matchesName && !matchesDesc { return false }
            }

            return true
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("NPad++ Plugin Manager")
                        .font(.system(size: 15, weight: .bold))
                    Text("Extend NPad++ with native formatters, tools, and developer utilities.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Done") {
                    appState.showPluginManagerSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Main Split Workspace
            HStack(spacing: 0) {
                // Left Navigation Bar (Tabs & Categories)
                VStack(alignment: .leading, spacing: 14) {
                    // Status Tabs
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SECTIONS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 2)

                        ForEach(PluginManagerTab.allCases) { tab in
                            Button(action: { registry.selectedTab = tab }) {
                                HStack(spacing: 8) {
                                    Image(systemName: tab.iconName)
                                        .font(.system(size: 12))
                                        .foregroundColor(registry.selectedTab == tab ? .white : .accentColor)
                                        .frame(width: 16)

                                    Text(tab.rawValue)
                                        .font(.system(size: 12, weight: registry.selectedTab == tab ? .semibold : .regular))
                                        .foregroundColor(registry.selectedTab == tab ? .white : .primary)

                                    Spacer()

                                    // Badge count
                                    let count = countForTab(tab)
                                    Text("\(count)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(registry.selectedTab == tab ? Color.white.opacity(0.25) : Color.secondary.opacity(0.15))
                                        .foregroundColor(registry.selectedTab == tab ? .white : .secondary)
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(registry.selectedTab == tab ? Color.accentColor : Color.clear)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Divider()

                    // Category Filter
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CATEGORIES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 2)

                        ForEach(PluginCategory.allCases) { cat in
                            Button(action: { registry.selectedCategory = cat }) {
                                HStack(spacing: 8) {
                                    Image(systemName: cat.iconName)
                                        .font(.system(size: 11))
                                        .foregroundColor(registry.selectedCategory == cat ? .accentColor : .secondary)
                                        .frame(width: 16)

                                    Text(cat.rawValue)
                                        .font(.system(size: 11.5, weight: registry.selectedCategory == cat ? .semibold : .regular))
                                        .foregroundColor(registry.selectedCategory == cat ? .primary : .secondary)

                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(registry.selectedCategory == cat ? Color.accentColor.opacity(0.1) : Color.clear)
                                .cornerRadius(5)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()
                }
                .padding(10)
                .frame(width: 190)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.6))

                Divider()

                // Right Content Area (Search Bar + Plugin Cards List)
                VStack(spacing: 0) {
                    // Search Filter
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        TextField("Search plugins by name, tag, or description...", text: $registry.searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))

                        if !registry.searchText.isEmpty {
                            Button(action: { registry.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .overlay(Divider(), alignment: .bottom)

                    // Plugin Cards ScrollView
                    if filteredPlugins.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "puzzlepiece")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary.opacity(0.5))

                            Text("No Plugins Found")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)

                            Text("No plugins matched your current filter or search criteria.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary.opacity(0.8))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(.vertical, showsIndicators: true) {
                            LazyVStack(spacing: 10) {
                                ForEach(filteredPlugins) { plugin in
                                    PluginCardRow(
                                        plugin: plugin,
                                        onToggle: { registry.togglePlugin(plugin.id) },
                                        onInstall: { registry.installPlugin(plugin.id) },
                                        onUninstall: { registry.uninstallPlugin(plugin.id) },
                                        onUpdate: { registry.updatePlugin(plugin.id) },
                                        onInspect: { registry.selectedPlugin = plugin }
                                    )
                                }
                            }
                            .padding(12)
                        }
                    }
                }
            }
        }
        .frame(width: 720, height: 520)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(item: $registry.selectedPlugin) { plugin in
            PluginDetailView(plugin: plugin) {
                registry.selectedPlugin = nil
            }
        }
    }

    private func countForTab(_ tab: PluginManagerTab) -> Int {
        switch tab {
        case .installed: return registry.plugins.filter { $0.isInstalled && $0.isEnabled }.count
        case .available: return registry.plugins.filter { !$0.isInstalled }.count
        case .updates: return registry.plugins.filter { $0.isInstalled && $0.availableVersion != nil }.count
        case .disabled: return registry.plugins.filter { $0.isInstalled && !$0.isEnabled }.count
        }
    }
}

// MARK: - Plugin Card Row Component
public struct PluginCardRow: View {
    let plugin: PluginInfo
    let onToggle: () -> Void
    let onInstall: () -> Void
    let onUninstall: () -> Void
    let onUpdate: () -> Void
    let onInspect: () -> Void

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: plugin.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(plugin.name)
                        .font(.system(size: 13, weight: .bold))

                    Text("v\(plugin.version)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text(plugin.category.rawValue)
                        .font(.system(size: 9.5, weight: .medium))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(3)
                }

                Text(plugin.summary)
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Text("By \(plugin.author)")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary.opacity(0.8))

                    Button("Details & Docs") {
                        onInspect()
                    }
                    .font(.system(size: 10.5))
                    .buttonStyle(.link)
                }
                .padding(.top, 2)
            }

            Spacer()

            // Actions
            VStack(alignment: .trailing, spacing: 6) {
                if plugin.isInstalled {
                    Toggle("", isOn: Binding(
                        get: { plugin.isEnabled },
                        set: { _ in onToggle() }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .help(plugin.isEnabled ? "Disable Plugin" : "Enable Plugin")

                    if let update = plugin.availableVersion {
                        Button("Update v\(update)") {
                            onUpdate()
                        }
                        .font(.system(size: 10))
                        .controlSize(.mini)
                    }
                } else {
                    Button("Install") {
                        onInstall()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Plugin Detail Inspector View
public struct PluginDetailView: View {
    let plugin: PluginInfo
    let onClose: () -> Void

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: plugin.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plugin.name)
                            .font(.system(size: 15, weight: .bold))
                        Text("Version \(plugin.version) • \(plugin.category.rawValue) • \(plugin.author)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button("Close") {
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Overview")
                        .font(.system(size: 13, weight: .bold))
                    Text(plugin.summary)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Usage & Documentation")
                        .font(.system(size: 13, weight: .bold))
                    Text(plugin.documentation)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(18)
            }
        }
        .frame(width: 480, height: 340)
    }
}
