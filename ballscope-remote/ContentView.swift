import SwiftUI

struct ContentView: View {
    @StateObject private var appModel = AppModel()

    private var isFullscreenWebMode: Bool {
        appModel.selectedDestination != .home && (appModel.isAppFullscreen || appModel.nativeStreamFullscreenSession != nil)
    }

    var body: some View {
        ZStack {
            LiquidBackground()

            VStack(spacing: 0) {
                if !isFullscreenWebMode {
                    topBar
                }

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !isFullscreenWebMode {
                    LiquidTabBar(selectedDestination: $appModel.selectedDestination) { destination in
                        appModel.onTabSelected(destination)
                    }
                }
            }
            .padding(.top, isFullscreenWebMode ? 0 : 8)

            if isFullscreenWebMode {
                if appModel.nativeStreamFullscreenSession == nil {
                    fullscreenControls
                }
            }

            if let streamSession = appModel.nativeStreamFullscreenSession {
                NativeStreamFullscreenView(session: streamSession) {
                    appModel.closeNativeStreamFullscreen()
                }
            }
        }
        .sheet(isPresented: $appModel.showSettings) {
            SettingsSheet(
                initialSettings: appModel.settings,
                onSave: { updatedSettings in
                    appModel.saveSettings(updatedSettings)
                },
                onResetAppCache: {
                    appModel.resetAppCache()
                }
            )
        }
        .fullScreenCover(isPresented: $appModel.showOnboarding) {
            OnboardingView(
                onContinue: {
                    appModel.completeOnboarding()
                }
            )
        }
        .preferredColorScheme(appModel.preferredColorScheme)
        .task {
            appModel.start()
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(appModel.selectedDestination.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(appModel.isJetsonReachable ? "BallScope System Online" : "BallScope System Offline")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                appModel.reloadCurrentScreen()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            if appModel.selectedDestination != .home {
                Button {
                    appModel.toggleFullscreen()
                } label: {
                    Image(systemName: appModel.isAppFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Button {
                appModel.showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var content: some View {
        if appModel.selectedDestination == .home {
            HomeDashboardView(
                isJetsonReachable: appModel.isJetsonReachable,
                lastConnectionCheck: appModel.lastConnectionCheck,
                currentPath: appModel.webRouter.currentPath,
                pendingSystemAction: appModel.pendingSystemAction,
                systemPowerFeedback: appModel.systemPowerFeedback,
                onOpenDestination: { destination in
                    appModel.onTabSelected(destination)
                },
                onSystemPowerAction: { action in
                    appModel.triggerSystemPowerAction(action)
                },
                onOpenSettings: { appModel.showSettings = true }
            )
        } else {
            ZStack {
                JetsonWebView(webView: appModel.webRouter.webView)
                    .clipShape(RoundedRectangle(cornerRadius: isFullscreenWebMode ? 0 : 24, style: .continuous))
                    .overlay {
                        if !isFullscreenWebMode {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        }
                    }
                    .padding(.horizontal, isFullscreenWebMode ? 0 : 10)
                    .padding(.top, isFullscreenWebMode ? 0 : 8)
                    .padding(.bottom, isFullscreenWebMode ? 0 : 4)

                if !appModel.isJetsonReachable {
                    connectionOverlay
                }
            }
        }
    }

    private var fullscreenControls: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    appModel.exitFullscreen()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .padding(.trailing, 12)
            }
            Spacer()
        }
    }

    private var connectionOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 26, weight: .semibold))

            Text("Connect to BallScope Wi-Fi")
                .font(.system(size: 18, weight: .bold))

            Text("No device found for \(appModel.settings.activeSystem.displayName) at \(appModel.settings.host):\(appModel.settings.port).")
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button {
                Task { await appModel.checkConnectionAndLoadIfNeeded(forceLoad: true) }
            } label: {
                Text(appModel.isCheckingConnection ? "Checking..." : "Check Again")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.16))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(appModel.isCheckingConnection)

            Button {
                appModel.showOnboarding = true
            } label: {
                Text("Open Setup Guide")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.14))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                appModel.reloadCurrentScreen()
            } label: {
                Text("Reload Current View")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.10))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.primary)
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.14), lineWidth: 1)
        }
        .padding(24)
    }
}

#Preview {
    ContentView()
}
