# AGENTS

## Scope
These instructions apply to the entire `ballscope-remote` repository.

## Project Purpose
Build and maintain a native iOS companion app for BallScope Jetson (`jetson.local:8000`) with:
- polished native UI
- embedded web control routes (`/record`, `/analysis`, `/live`)
- robust local-network behavior

## Tech Stack
- Swift
- SwiftUI
- WebKit (`WKWebView`)
- Xcode project without external package dependencies

## Engineering Rules
- Keep app navigation native-first; do not expose browser chrome.
- Maintain route synchronization between app tab state and current web slug.
- Preserve a single shared `WKWebView` session for Jetson control pages.
- Keep endpoint settings configurable (host + port) and persisted.
- Favor small, composable SwiftUI views and explicit state ownership.

## UI/UX Rules
- Follow iOS visual quality bar with material/translucency styling.
- Prioritize readability and touch targets over decorative effects.
- Home screen should stay fully native and include settings access.

## Networking Rules
- App is optimized for local Jetson hotspot/LAN scenarios.
- Validate connectivity before showing control web pages.
- On failure, show clear recovery guidance in English.

## Documentation Rules
When behavior changes, update:
- `README.md`
- `docs/architecture.md`
- `docs/setup.md`
- `docs/jetson-integration.md`

## Non-goals
- No cloud backend integration in this repo.
- No account/auth system in this repo.
- No cross-platform UI toolkit migration.
