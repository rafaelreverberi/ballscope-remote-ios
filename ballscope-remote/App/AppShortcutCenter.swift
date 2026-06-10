import SwiftUI
import UIKit
import Combine
import OSLog

@MainActor
final class AppShortcutCenter: ObservableObject {
    static let shared = AppShortcutCenter()

    @Published private(set) var requestedDestination: AppDestination?

    private init() {}

    func configureShortcutItems() {
        AppLogger.startup.notice("Configuring home screen quick actions")
        UIApplication.shared.shortcutItems = AppDestination.shortcutDestinations.map { destination in
            let icon = UIImage(systemName: destination.iconName).map { _ in
                UIApplicationShortcutIcon(systemImageName: destination.iconName)
            }

            return UIApplicationShortcutItem(
                type: destination.shortcutType,
                localizedTitle: destination.title,
                localizedSubtitle: destination.shortcutSubtitle,
                icon: icon,
                userInfo: nil
            )
        }
        AppLogger.startup.notice("Home screen quick actions configured")
    }

    func requestShortcut(type: String) {
        guard let destination = AppDestination(shortcutType: type) else { return }
        requestedDestination = destination
    }

    func consumeRequest() {
        requestedDestination = nil
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        AppLogger.startup.notice("AppDelegate configurationForConnecting")
        if let shortcutItem = options.shortcutItem {
            Task { @MainActor in
                AppShortcutCenter.shared.requestShortcut(type: shortcutItem.type)
            }
        }

        return UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        AppLogger.startup.notice("AppDelegate performActionFor shortcut")
        Task { @MainActor in
            AppShortcutCenter.shared.requestShortcut(type: shortcutItem.type)
            completionHandler(true)
        }
    }
}
