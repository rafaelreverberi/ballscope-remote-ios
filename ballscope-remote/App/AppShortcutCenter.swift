import SwiftUI
import UIKit
import Combine

@MainActor
final class AppShortcutCenter: ObservableObject {
    static let shared = AppShortcutCenter()

    @Published private(set) var requestedDestination: AppDestination?

    private init() {}

    func configureShortcutItems() {
        UIApplication.shared.shortcutItems = AppDestination.shortcutDestinations.map { destination in
            UIApplicationShortcutItem(
                type: destination.shortcutType,
                localizedTitle: destination.title,
                localizedSubtitle: destination.shortcutSubtitle,
                icon: UIApplicationShortcutIcon(systemImageName: destination.iconName)
            )
        }
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
        Task { @MainActor in
            AppShortcutCenter.shared.requestShortcut(type: shortcutItem.type)
            completionHandler(true)
        }
    }
}
