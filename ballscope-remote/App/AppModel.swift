import Foundation
import SwiftUI
import Combine
import WebKit

@MainActor
final class AppModel: ObservableObject {
    struct NativeStreamFullscreenSession: Identifiable, Equatable {
        let id = UUID()
        let url: URL
        let title: String?
        let fitContain: Bool
    }

    enum SystemPowerAction: String, Identifiable, CaseIterable {
        case reboot
        case shutdown

        var id: String { rawValue }

        var title: String {
            switch self {
            case .reboot: return "Reboot System"
            case .shutdown: return "Shutdown System"
            }
        }

        var endpointPath: String {
            switch self {
            case .reboot: return "/api/system/reboot"
            case .shutdown: return "/api/system/shutdown"
            }
        }

        var iconName: String {
            switch self {
            case .reboot: return "arrow.clockwise.circle.fill"
            case .shutdown: return "power.circle.fill"
            }
        }
    }

    struct SystemPowerFeedback {
        let message: String
        let isError: Bool
    }

    @Published var selectedDestination: AppDestination = .home
    @Published var settings: AppSettings
    @Published var isJetsonReachable = false
    @Published var isCheckingConnection = false
    @Published var lastConnectionCheck: Date?
    @Published var showSettings = false
    @Published var showOnboarding = false
    @Published var isAppFullscreen = false
    @Published var nativeStreamFullscreenSession: NativeStreamFullscreenSession?
    @Published var pendingSystemAction: SystemPowerAction?
    @Published var systemPowerFeedback: SystemPowerFeedback?

    let webRouter = JetsonWebRouter()

    private let settingsStore = AppSettingsStore()
    private var monitorTask: Task<Void, Never>?

    init() {
        let loadedSettings = settingsStore.load()
        settings = loadedSettings
        webRouter.updateSettings(loadedSettings)

        webRouter.onPathChange = { [weak self] path in
            guard let self else { return }
            let normalized = path.hasPrefix("/") ? path : "/\(path)"

            if normalized == "/" {
                if self.selectedDestination != .home {
                    self.selectedDestination = .home
                }
                self.isAppFullscreen = false
                return
            }

            guard let destination = AppDestination.from(path: normalized) else {
                return
            }

            if destination != self.selectedDestination {
                self.selectedDestination = destination
            }
        }

        webRouter.onFullscreenChange = { [weak self] active in
            Task { @MainActor [weak self] in
                self?.isAppFullscreen = active
            }
        }

        webRouter.onFullscreenToggleRequest = { [weak self] in
            Task { @MainActor [weak self] in
                self?.toggleFullscreen()
            }
        }

        webRouter.onNativeStreamFullscreenRequest = { [weak self] url, title, fit in
            Task { @MainActor [weak self] in
                self?.toggleNativeStreamFullscreen(url: url, title: title, fitContain: fit)
            }
        }
    }

    deinit {
        monitorTask?.cancel()
    }

    func start() {
        showOnboarding = !settingsStore.hasCompletedOnboarding()
        startConnectionMonitor()
        Task {
            await checkConnectionAndLoadIfNeeded()
        }
    }

    func onTabSelected(_ destination: AppDestination) {
        selectedDestination = destination
        if destination == .home {
            isAppFullscreen = false
            return
        }
        webRouter.navigate(to: destination)
    }

    func reloadCurrentScreen() {
        Task {
            await checkConnectionAndLoadIfNeeded(forceLoad: true)
            guard selectedDestination != .home else { return }
            webRouter.reloadOrNavigate(to: selectedDestination)
        }
    }

    func toggleFullscreen() {
        guard selectedDestination != .home else { return }
        isAppFullscreen.toggle()
    }

    func exitFullscreen() {
        if nativeStreamFullscreenSession != nil {
            closeNativeStreamFullscreen()
            return
        }
        guard isAppFullscreen else { return }
        isAppFullscreen = false
        webRouter.setDocumentFullscreen(false)
    }

    func closeNativeStreamFullscreen() {
        nativeStreamFullscreenSession = nil
    }

    func saveSettings(_ updated: AppSettings) {
        settings = updated
        settingsStore.save(updated)
        webRouter.updateSettings(updated)

        Task {
            await checkConnectionAndLoadIfNeeded(forceLoad: true)
        }
    }

    func updateAppearance(_ appearance: AppAppearance) {
        saveSettings(settings.updatingAppearance(appearance))
    }

    func completeOnboarding() {
        settingsStore.setCompletedOnboarding(true)
        showOnboarding = false
    }

    func resetAppCache() {
        settingsStore.setCompletedOnboarding(false)
        settings = .default
        settingsStore.save(settings)
        webRouter.updateSettings(settings)
        showOnboarding = true

        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: types) { records in
            dataStore.removeData(ofTypes: types, for: records) {}
        }
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
            webRouter.navigate(to: selectedDestination, force: forceLoad)
        }
    }

    func triggerSystemPowerAction(_ action: SystemPowerAction) {
        Task { await performSystemPowerAction(action) }
    }

    private func performSystemPowerAction(_ action: SystemPowerAction) async {
        pendingSystemAction = action
        systemPowerFeedback = nil
        defer { pendingSystemAction = nil }

        var url = settings.baseURL
        url.append(path: action.endpointPath)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 4
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if (200..<300).contains(status) {
                let apiMessage = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["note"] as? String
                let defaultMessage = action == .reboot ? "Reboot scheduled." : "Shutdown scheduled."
                systemPowerFeedback = .init(message: apiMessage ?? defaultMessage, isError: false)
            } else {
                systemPowerFeedback = .init(message: "Request failed (\(status)).", isError: true)
            }
        } catch {
            systemPowerFeedback = .init(message: "Power request failed. Check connection and try again.", isError: true)
        }
    }

    private func toggleNativeStreamFullscreen(url: URL, title: String?, fitContain: Bool) {
        if nativeStreamFullscreenSession != nil {
            closeNativeStreamFullscreen()
            return
        }
        nativeStreamFullscreenSession = NativeStreamFullscreenSession(url: url, title: title, fitContain: fitContain)
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
