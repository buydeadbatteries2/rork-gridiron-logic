import Foundation

/// Everything that survives an app relaunch, encoded to local storage.
nonisolated struct SavedProgress: Codable, Sendable, Equatable {
    var currentLevelNumber: Int
    var playerLevel: Int
    var xp: Int
    var gameBalls: Int
    /// Best star count per cleared level.
    var starsByLevel: [Int: Int]
    /// Locker category raw value -> equipped cosmetic id.
    var equippedCosmetics: [String: String]
    /// Whether the five-screen Level 1 tutorial has been completed.
    /// Optional so progress saved before the tutorial existed still decodes.
    var tutorialSeen: Bool?
}

/// Local persistence for player progress. UserDefaults is enough at this scale —
/// the payload is a few hundred bytes and read once per launch.
nonisolated enum ProgressStore {
    static let storageKey = "gridiron.saved.progress.v1"

    static func load() -> SavedProgress? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        do {
            return try JSONDecoder().decode(SavedProgress.self, from: data)
        } catch {
            // Corrupt payloads are discarded; the player simply restarts their career.
            return nil
        }
    }

    static func save(_ value: SavedProgress) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
