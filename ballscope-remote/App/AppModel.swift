import Foundation
import SwiftUI
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedDestination: AppDestination = .home
    @Published var settings: AppSettings
    @Published var isJetsonReachable = false
    @Published var isCheckingConnection = false
    @Published var lastConnectionCheck: Date?
    @Published var showSettings = false

    let webRouter = JetsonWebRouter()

    private let settingsStore = AppSettingsStore()
    private var monitorTask: Task<Void, Never>?

    init() {
        let loadedSettings = settingsStore.load()
        settings = loadedSettings
        webRouter.updateSettings(loadedSettings)

        webRouter.onPathChange = { [weak self] path in
            guard let self else { return }
            if let destination = AppDestination.from(path: path), destination != self.selectedDestination {
                self.selectedDestination = destination
            }
        }
    }

    deinit {
        monitorTask?.cancel()
    }

    func start() {
        startConnectionMonitor()
        Task {
            await checkConnectionAndLoadIfNeeded()
        }
    }

    func onTabSelected(_ destination: AppDestination) {
        selectedDestination = destination
        guard destination != .home else { return }
        webRouter.navigate(to: destination)
    }

    func saveSettings(host: String, port: Int) {
        let normalizedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedHost.isEmpty else { return }

        let updated = AppSettings(host: normalizedHost, port: port, appearance: settings.appearance)
        settings = updated
        settingsStore.save(updated)
        webRouter.updateSettings(updated)

        Task {
            await checkConnectionAndLoadIfNeeded(forceLoad: true)
        }
    }

    func updateAppearance(_ appearance: AppAppearance) {
        let updated = AppSettings(host: settings.host, port: settings.port, appearance: appearance)
        settings = updated
        settingsStore.save(updated)
        webRouter.updateSettings(updated)
    }

    var preferredColorScheme: ColorScheme? {
        switch settings.appearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func checkConnectionAndLoadIfNeeded(forceLoad: Bool = false) async {
        isCheckingConnection = true
        defer {
            isCheckingConnection = false
            lastConnectionCheck = Date()
        }

        isJetsonReachable = await probeJetson(baseURL: settings.baseURL)
        if isJetsonReachable, (selectedDestination != .home || forceLoad) {
            webRouter.navigate(to: selectedDestination)
        }
    }

    private func startConnectionMonitor() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await checkConnectionAndLoadIfNeeded()
                try? await Task.sleep(for: .seconds(4))
            }
        }
    }

    private func probeJetson(baseURL: URL) async -> Bool {
        var request = URLRequest(url: baseURL)
        request.timeoutInterval = 2
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (200..<500).contains(httpResponse.statusCode)
            }
            return true
        } catch {
            return false
        }
    }
}
