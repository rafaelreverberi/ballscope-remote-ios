import Foundation

enum AppDestination: String, CaseIterable, Identifiable {
    case home
    case record
    case analysis
    case live

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .record: return "Record"
        case .analysis: return "Analysis"
        case .live: return "Live"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .record: return "video.fill"
        case .analysis: return "chart.line.uptrend.xyaxis"
        case .live: return "dot.radiowaves.left.and.right"
        }
    }

    var webPath: String? {
        switch self {
        case .home: return nil
        case .record: return "/record"
        case .analysis: return "/analysis"
        case .live: return "/live"
        }
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
        return nil
    }
}
