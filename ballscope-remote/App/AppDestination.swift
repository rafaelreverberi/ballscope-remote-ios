import Foundation

enum AppDestination: String, CaseIterable, Identifiable {
    case home
    case record
    case analysis
    case live
    case cameraSettings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .record: return "Record"
        case .analysis: return "Analysis"
        case .live: return "Live"
        case .cameraSettings: return "Camera Settings"
        }
    }

    var tabTitle: String {
        switch self {
        case .cameraSettings:
            return "Settings"
        default:
            return title
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .record: return "video.fill"
        case .analysis: return "chart.line.uptrend.xyaxis"
        case .live: return "dot.radiowaves.left.and.right"
        case .cameraSettings: return "gearshape.fill"
        }
    }

    var webPath: String? {
        switch self {
        case .home: return nil
        case .record: return "/record"
        case .analysis: return "/analysis"
        case .live: return "/live"
        case .cameraSettings: return "/camera-settings"
        }
    }

    var shortcutType: String {
        "com.ballscope.remote.\(rawValue)"
    }

    var shortcutSubtitle: String? {
        switch self {
        case .record:
            return "Open Jetson recording controls"
        case .analysis:
            return "Open Jetson analysis controls"
        case .live:
            return "Open Jetson live controls"
        case .cameraSettings:
            return "Open Jetson camera settings"
        case .home:
            return nil
        }
    }

    static var shortcutDestinations: [AppDestination] {
        [.record, .analysis, .live, .cameraSettings]
    }

    static func from(path: String?) -> AppDestination? {
        guard let path else { return nil }
        if path == "/" || path.isEmpty {
            return nil
        }

        let normalized = path.hasPrefix("/") ? path : "/\(path)"
        if normalized.hasPrefix("/record") {
            return .record
        }
        if normalized.hasPrefix("/analysis") {
            return .analysis
        }
        if normalized.hasPrefix("/live") {
            return .live
        }
        if normalized.hasPrefix("/camera-settings") {
            return .cameraSettings
        }
        return nil
    }

    init?(shortcutType: String) {
        guard let destination = Self.shortcutDestinations.first(where: { $0.shortcutType == shortcutType }) else {
            return nil
        }
        self = destination
    }
}
