# Setup Guide

## 1) Open Project
```bash
cd /Users/rafael/Dev/Apps/ballscope-remote
open ballscope-remote.xcodeproj
```

## 2) Build Requirements
- Xcode 26 or newer
- iOS 26 SDK

## 3) Run on Simulator or Device
- Choose target device in Xcode
- Press Run

## 4) Connect to Jetson
Default endpoint is:
- `http://jetson.local:8000`

If your Jetson uses another address:
1. Open app
2. Go to `Home`
3. Open `Settings`
4. Add or edit a BallScope system
5. Set the correct `Host` and `Port`
6. Select it as the active system

## 5) Jetson Side
Ensure the BallScope service is running on the Jetson:
```bash
source .venv/bin/activate
python main.py
```

Then open in browser for sanity check:
- `http://jetson.local:8000`

## Troubleshooting
- If app shows “Connect to Jetson Wi-Fi”, ensure iPhone is on Jetson hotspot network.
- If slug pages do not load, verify backend routes exist:
  - `/record`
  - `/analysis`
  - `/live`
- The app intentionally opens native Home (not embedded web menu) when Jetson navigates to `/`.
- If endpoint changed, update the active BallScope system in app settings and retry.
