import SwiftUI
import Network
import OSLog

@main
struct BallScopeRemoteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        AppLogger.startup.notice("BallScopeRemoteApp init begin")
        _ = nw_tls_create_options()
        AppLogger.startup.notice("Network framework primed")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
