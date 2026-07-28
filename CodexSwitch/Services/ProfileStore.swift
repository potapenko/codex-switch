import Foundation

struct ProfileStore {
    private let fileManager: FileManager
    private let applicationSupportURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CodexSwitch", isDirectory: true)
    }

    func load() -> [AccountProfile] {
        guard let data = try? Data(contentsOf: profilesURL) else {
            return []
        }
        return (try? JSONDecoder().decode([AccountProfile].self, from: data)) ?? []
    }

    func save(_ profiles: [AccountProfile]) throws {
        try fileManager.createDirectory(at: applicationSupportURL, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(profiles)
        try data.write(to: profilesURL, options: .atomic)
    }

    func codexHome(for profile: AccountProfile) throws -> URL {
        let directory = applicationSupportURL
            .appendingPathComponent("Profiles", isDirectory: true)
            .appendingPathComponent(profile.id.uuidString, isDirectory: true)
            .appendingPathComponent("Codex", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private var profilesURL: URL {
        applicationSupportURL.appendingPathComponent("profiles.json")
    }
}
