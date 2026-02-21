# Jetson Integration Notes

## Expected Jetson Host Behavior
BallScope Jetson runs as local web server and is reachable at:
- `http://jetson.local:8000`

The iOS app assumes these routes:
- `/` (menu/home on Jetson web UI)
- `/record`
- `/analysis`
- `/live`

## App <-> Jetson Routing Contract
- Native tab selection maps to route slug and opens it in embedded `WKWebView`.
- If user navigates inside Jetson web UI, app watches URL updates and syncs selected tab.

## Connectivity Contract
- App checks Jetson availability by requesting base endpoint.
- If unavailable, app presents native connection hint overlay.

## Operational Recommendation
- Keep Jetson hotspot SSID and hostname stable.
- Prefer hostname `jetson.local` for simplified field setup.
- Keep backend port fixed at `8000` unless app settings are updated.
