import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class LauncherStore {
    private(set) var launchers: [Launcher] = []
    var errorMessage: String?

    private let fileManager: FileManager
    private let storageURL: URL

    init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        self.fileManager = fileManager
        self.storageURL = storageURL ?? Self.defaultStorageURL(fileManager: fileManager)
        load()
        discover()
    }

    static func defaultStorageURL(fileManager: FileManager) -> URL {
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LauncherLauncher", isDirectory: true)
        return directory.appendingPathComponent("launchers.json")
    }

    func discover() {
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
        ]

        var discovered: [Launcher] = []
        for root in roots where fileManager.fileExists(atPath: root.path) {
            let keys: [URLResourceKey] = [.isDirectoryKey, .isApplicationKey, .nameKey]
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let url as URL in enumerator {
                guard url.pathExtension.lowercased() == "app" else { continue }
                let name = url.deletingPathExtension().lastPathComponent
                let bundleID = Bundle(url: url)?.bundleIdentifier
                guard LauncherCatalog.looksLikeLauncher(name: name, bundleIdentifier: bundleID) else { continue }
                discovered.append(Launcher(name: name, path: url.path))
            }
        }

        merge(discovered)
    }

    func add(urls: [URL]) {
        let apps = urls.compactMap { url -> Launcher? in
            guard url.pathExtension.lowercased() == "app" else { return nil }
            return Launcher(
                name: url.deletingPathExtension().lastPathComponent,
                path: url.path,
                isManuallyAdded: true
            )
        }
        merge(apps)
    }

    func remove(_ launcher: Launcher) {
        launchers.removeAll { $0.id == launcher.id }
        save()
    }

    func toggleFavorite(_ launcher: Launcher) {
        guard let index = launchers.firstIndex(where: { $0.id == launcher.id }) else { return }
        launchers[index].isFavorite.toggle()
        save()
    }

    func launch(_ launcher: Launcher) {
        guard fileManager.fileExists(atPath: launcher.path) else {
            errorMessage = "\(launcher.name) has moved or is no longer installed."
            return
        }

        NSWorkspace.shared.openApplication(at: launcher.url, configuration: .init()) { _, error in
            Task { @MainActor in
                if let error { self.errorMessage = "Couldn’t launch \(launcher.name): \(error.localizedDescription)" }
            }
        }
    }

    private func merge(_ candidates: [Launcher]) {
        var byPath = Dictionary(uniqueKeysWithValues: launchers.map { ($0.path, $0) })
        for candidate in candidates where byPath[candidate.path] == nil {
            byPath[candidate.path] = candidate
        }
        launchers = byPath.values.sorted {
            if $0.isFavorite != $1.isFavorite { return $0.isFavorite }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        do {
            launchers = try JSONDecoder().decode([Launcher].self, from: data)
        } catch {
            errorMessage = "Your saved launcher list couldn’t be read. Discovery can rebuild it."
        }
    }

    private func save() {
        do {
            try fileManager.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(launchers)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            errorMessage = "Couldn’t save your launcher list: \(error.localizedDescription)"
        }
    }
}
