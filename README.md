# BallScope Remote

BallScope Remote is a native iOS companion app for the BallScope Jetson system. It provides a high-end, iOS-style control surface around the local Jetson web interface so users can manage recording, analysis, and live mode from one app.

## Project Context
- School project (Grade 9, upper secondary / Sek II)
- Region: Wasseramt Ost
- Authors: Rafael Reverberi, Benjamin Flury

## What This App Does
- Checks whether a Jetson instance is reachable on the local hotspot network (`jetson.local:8000` by default).
- Shows a native Home dashboard with connection status and quick stats.
- Embeds the BallScope UI for:
  - `/record`
  - `/analysis`
  - `/live`
- Keeps app navigation in sync with slug changes coming from the website itself.
- Exposes host/port settings for alternate Jetson addresses.
- Includes appearance mode settings (`System`, `Light`, `Dark`).

## Design Goals
- Native-first iOS experience (not a plain browser shell).
- Liquid glass inspired visual styling with polished translucency.
- Stable local-network operation for field usage.

## Requirements
- Xcode 26+
- iOS 26+ deployment target
- A running BallScope Jetson instance reachable via local network

## Run (Xcode)
1. Open `ballscope-remote.xcodeproj`
2. Select an iOS Simulator or device
3. Build and run

Default endpoint:
- `http://jetson.local:8000`

Change endpoint in app:
- Home -> `Settings`

## App Architecture (Summary)
- `ballscope-remote/App/`
  - app state, endpoint settings persistence, navigation model, and connection checks
- `ballscope-remote/UI/`
  - native home screen, custom liquid tab bar, and embedded `WKWebView`
- `docs/`
  - setup details, architecture notes, and Jetson integration notes

## Related Repositories
- BallScope Jetson/Core repo:
  - `/Users/rafael/jetson-ballscope/ballscope`

## Documentation
- `docs/setup.md`
- `docs/architecture.md`
- `docs/jetson-integration.md`

## License
MIT License (`LICENSE`)
