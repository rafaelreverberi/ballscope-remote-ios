# BallScope Remote Architecture

## Scope
BallScope Remote is a native iOS shell around the BallScope Jetson web UI.

It combines:
- native app-level navigation, settings, and status
- embedded web control screens for Jetson features

## Core Modules
- `ballscope-remote/App/AppModel.swift`
  - source of truth for current tab, multi-system settings, and reachability state
- `ballscope-remote/App/JetsonWebRouter.swift`
  - owns and controls a single `WKWebView`
  - keeps URL path and app destination synchronized
- `ballscope-remote/App/AppSettingsStore.swift`
  - persists saved BallScope systems, active system, and appearance mode via `UserDefaults`
- `ballscope-remote/UI/ContentView.swift`
  - orchestrates native home vs web scene, fullscreen mode, and connection overlay
- `ballscope-remote/UI/HomeDashboardView.swift`
  - native dashboard for status, stats, and settings access
- `ballscope-remote/UI/LiquidTabBar.swift`
  - app-level bottom navigation (`Home`, `Record`, `Analysis`, `Live`)

## Navigation Strategy
1. User taps an app tab (`Record`, `Analysis`, `Live`).
2. App maps destination to slug and loads Jetson URL.
3. If website navigation changes slug internally, `WKNavigationDelegate` reads path.
4. Path is mapped back to app destination and updates selected tab.
5. The Jetson root route (`/`) is redirected to native `Home` instead of showing the Jetson menu inside the web shell.

Result: app tab state stays consistent even when website changes route on its own.

## Connectivity Strategy
- The app probes the active BallScope system endpoint every 4 seconds.
- On unreachable endpoint, web screens show a native “connect to Jetson Wi-Fi” overlay.
- On successful probe, selected web route is loaded/refreshed.

## Security / Transport
- Local HTTP is enabled for web content in `Info.plist` via `NSAppTransportSecurity` keys.
- Intended use is private local hotspot/LAN only.

## Data Boundaries
- Persisted locally:
  - saved BallScope systems (name, host, port)
  - active system selection
- Not persisted:
  - Jetson web session data beyond what `WKWebView` holds

## Future Extension Points
- optional mDNS discovery and multi-device auto-suggestion
- richer Jetson stats API surface on Home dashboard
- offline diagnostics and retry backoff strategies


## Fullscreen Behavior
- Web fullscreen requests are mirrored into an app-native fullscreen presentation (top bar and tab bar hidden).
- Users can also toggle fullscreen from the app chrome when on a web route.
- Web media fullscreen / picture-in-picture style states (e.g. camera stream viewers) are also mirrored when exposed via browser media/fullscreen APIs.

## Power Controls
- Home screen can call Jetson power endpoints (`/api/system/reboot`, `/api/system/shutdown`).
- Buttons provide in-app loading and result feedback.
