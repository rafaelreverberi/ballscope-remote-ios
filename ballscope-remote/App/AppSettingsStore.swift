import Foundation

enum AppAppearance: String, CaseIterable, Codable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

struct BallScopeSystem: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var host: String
    var port: Int

    init(id: UUID = UUID(), name: String, host: String, port: Int) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedHost: String {
        host.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayName: String {
        trimmedName.isEmpty ? trimmedHost : trimmedName
    }

    var addressLabel: String {
        "\(trimmedHost):\(port)"
    }

    static let `default` = BallScopeSystem(name: "BallScope Jetson", host: "jetson.local", port: 8000)
}

struct AppSettings: Codable, Equatable {
    var systems: [BallScopeSystem]
    var activeSystemID: UUID
    var appearance: AppAppearance

    static let `default`: AppSettings = {
        let system = BallScopeSystem.default
        return AppSettings(systems: [system], activeSystemID: system.id, appearance: .system)
    }()

    var activeSystem: BallScopeSystem {
        if let exact = systems.first(where: { $0.id == activeSystemID }) {
            return exact
        }
        if let first = systems.first {
            return first
        }
        return BallScopeSystem.default
    }

    var host: String { activeSystem.trimmedHost }
    var port: Int { activeSystem.port }

    var baseURL: URL {
        URL(string: "http://\(host):\(port)")!
    }

    enum CodingKeys: String, CodingKey {
        case systems
        case activeSystemID
        case appearance
        case host
        case port
    }

    init(systems: [BallScopeSystem], activeSystemID: UUID, appearance: AppAppearance) {
        let normalizedSystems = systems.filter { !$0.trimmedHost.isEmpty }
        let fallback = normalizedSystems.isEmpty ? [BallScopeSystem.default] : normalizedSystems
        self.systems = fallback
        self.activeSystemID = fallback.contains(where: { $0.id == activeSystemID }) ? activeSystemID : fallback[0].id
        self.appearance = appearance
    }

    init(host: String, port: Int, appearance: AppAppearance) {
        let migrated = BallScopeSystem(name: "BallScope Jetson", host: host, port: port)
        self.init(systems: [migrated], activeSystemID: migrated.id, appearance: appearance)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appearance = try container.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system

        if let systems = try container.decodeIfPresent([BallScopeSystem].self, forKey: .systems),
           !systems.isEmpty {
            let storedActiveID = try container.decodeIfPresent(UUID.self, forKey: .activeSystemID) ?? systems[0].id
            let normalizedSystems = systems.filter { !$0.trimmedHost.isEmpty }
            self.systems = normalizedSystems.isEmpty ? [BallScopeSystem.default] : normalizedSystems
            self.activeSystemID = self.systems.contains(where: { $0.id == storedActiveID }) ? storedActiveID : self.systems[0].id
            return
        }

        let host = try container.decode(String.self, forKey: .host)
        let port = try container.decode(Int.self, forKey: .port)
        let migrated = BallScopeSystem(name: "BallScope Jetson", host: host, port: port)
        systems = [migrated]
        activeSystemID = migrated.id
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(systems, forKey: .systems)
        try container.encode(activeSystemID, forKey: .activeSystemID)
        try container.encode(appearance, forKey: .appearance)
    }

    func updatingSystems(_ systems: [BallScopeSystem], activeSystemID: UUID) -> AppSettings {
        AppSettings(systems: systems, activeSystemID: activeSystemID, appearance: appearance)
    }

    func updatingAppearance(_ appearance: AppAppearance) -> AppSettings {
        AppSettings(systems: systems, activeSystemID: activeSystemID, appearance: appearance)
    }
}

final class AppSettingsStore {
    private let defaults = UserDefaults.standard
    private let key = "ballscope.remote.settings"
    private let onboardingKey = "ballscope.remote.onboarding.completed"

    func load() -> AppSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }

    func hasCompletedOnboarding() -> Bool {
        defaults.bool(forKey: onboardingKey)
    }

    func setCompletedOnboarding(_ completed: Bool) {
        defaults.set(completed, forKey: onboardingKey)
    }
}
