import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var store: LauncherStore
    @State private var query = ""
    @State private var filter: Filter? = .all
    @State private var isDropTargeted = false

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All Launchers"
        case favorites = "Favorites"
        var id: Self { self }
        var symbol: String { self == .all ? "square.grid.2x2" : "star.fill" }
    }

    private var activeFilter: Filter { filter ?? .all }

    private var visibleLaunchers: [Launcher] {
        store.launchers.filter { launcher in
            let matchesFilter = activeFilter == .all || launcher.isFavorite
            let matchesQuery = query.isEmpty || launcher.name.localizedCaseInsensitiveContains(query)
            return matchesFilter && matchesQuery
        }
    }

    var body: some View {
        NavigationSplitView {
            List(Filter.allCases, selection: $filter) { item in
                Label(item.rawValue, systemImage: item.symbol).tag(item)
            }
            .navigationTitle("Launcher Launcher")
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("LAUNCHER LEVEL")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("Recursive")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        } detail: {
            VStack(spacing: 0) {
                header
                Divider()
                if visibleLaunchers.isEmpty { emptyState } else { launcherGrid }
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .searchable(text: $query, placement: .toolbar, prompt: "Search launchers")
            .toolbar { toolbar }
            .navigationTitle(activeFilter.rawValue)
        }
        .frame(minWidth: 780, minHeight: 520)
        .alert("Launcher malfunction", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "Unknown error")
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.purple.gradient)
                Image(systemName: "rocket.fill")
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 3) {
                Text("One launcher to launch them all.")
                    .font(.title2.weight(.bold))
                Text("Because apparently your game launchers needed adult supervision.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(visibleLaunchers.count) found")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }

    private var launcherGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
                ForEach(visibleLaunchers) { launcher in
                    LauncherCard(
                        launcher: launcher,
                        onLaunch: { store.launch(launcher) },
                        onFavorite: { store.toggleFavorite(launcher) },
                        onRemove: { store.remove(launcher) }
                    )
                }
            }
            .padding(20)
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.purple, style: StrokeStyle(lineWidth: 3, dash: [8]))
                    .background(.purple.opacity(0.08))
                    .padding(10)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(query.isEmpty ? "No launchers yet" : "No launchers found", systemImage: "gamecontroller")
        } description: {
            Text(query.isEmpty ? "Scan your Applications folders or add an app manually." : "Try a different search.")
        } actions: {
            if query.isEmpty {
                Button("Add Launcher…", action: chooseApplications)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup {
            Button(action: store.discover) { Label("Scan Again", systemImage: "arrow.clockwise") }
                .help("Scan /Applications and ~/Applications")
            Button(action: chooseApplications) { Label("Add Launcher", systemImage: "plus") }
                .help("Add an application manually")
        }
    }

    private func chooseApplications() {
        let panel = NSOpenPanel()
        panel.title = "Choose launchers"
        panel.prompt = "Add"
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.application]
        if panel.runModal() == .OK { store.add(urls: panel.urls) }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers where provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                Task { @MainActor in store.add(urls: [url]) }
            }
        }
        return !providers.isEmpty
    }
}

private struct LauncherCard: View {
    let launcher: Launcher
    let onLaunch: () -> Void
    let onFavorite: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                AppIconView(launcher: launcher)
                Spacer()
                Button(action: onFavorite) {
                    Image(systemName: launcher.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(launcher.isFavorite ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .help(launcher.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(launcher.name).font(.headline).lineLimit(1)
                Text(launcher.url.deletingLastPathComponent().path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            HStack {
                Button("Launch", action: onLaunch)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Spacer()
                Menu {
                    Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([launcher.url]) }
                    Divider()
                    Button("Remove", role: .destructive, action: onRemove)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor).opacity(0.35))
        )
        .contextMenu {
            Button("Launch", action: onLaunch)
            Button(launcher.isFavorite ? "Unfavorite" : "Favorite", action: onFavorite)
            Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([launcher.url]) }
            Divider()
            Button("Remove", role: .destructive, action: onRemove)
        }
    }
}
