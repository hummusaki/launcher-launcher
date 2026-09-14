import AppKit
import Foundation

struct Launcher: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var path: String
    var isFavorite: Bool
    var isManuallyAdded: Bool

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        isFavorite: Bool = false,
        isManuallyAdded: Bool = false
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.isFavorite = isFavorite
        self.isManuallyAdded = isManuallyAdded
    }

    var url: URL { URL(fileURLWithPath: path) }
}

enum LauncherCatalog {
    static let knownBundleNames: Set<String> = [
        "aether", "battle.net", "bottles", "claude's whisky", "crossover",
        "epic games launcher", "game porting toolkit", "heroic", "itch",
        "kaon", "legendary", "mythic", "nostalgiapp", "parallels desktop",
        "phoenix", "playcover", "porting kit", "prism launcher", "ryujinx",
        "steam", "swiftlauncher", "utm", "whisky", "wine", "wine crossover"
    ]

    static let matchingTerms = [
        "launcher", "gaming", "games", "steam", "wine", "whisky", "crossover",
        "heroic", "mythic", "playcover", "porting kit", "bottle", "emulator"
    ]

    static func looksLikeLauncher(name: String, bundleIdentifier: String?) -> Bool {
        let normalized = name.lowercased()
        if knownBundleNames.contains(normalized) { return true }

        let searchable = normalized + " " + (bundleIdentifier ?? "").lowercased()
        return matchingTerms.contains { searchable.contains($0) }
    }
}
