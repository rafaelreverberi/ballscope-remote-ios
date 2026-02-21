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

struct AppSettings: Codable, Equatable {
    var host: String
    var port: Int
    var appearance: AppAppearance

    static let `default` = AppSettings(host: "jetson.local", port: 8000, appearance: .system)

    var baseURL: URL {
        URL(string: "http://\(host):\(port)")!
    }

    enum CodingKeys: String, CodingKey {
        case host
        case port
        case appearance
    }

    init(host: String, port: Int, appearance: AppAppearance) {
        self.host = host
        self.port = port
        self.appearance = appearance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        host = try container.decode(String.self, forKey: .host)
        port = try container.decode(Int.self, forKey: .port)
        appearance = try container.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system
    }
}

final class AppSettingsStore {
    private let defaults = UserDefaults.standard
    private let key = "ballscope.remote.settings"

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
}
