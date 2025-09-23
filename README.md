# child_safety_monitor

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environment Variables

Create a `.env` file in the project root with:

```env
# Firebase
FIREBASE_API_KEY=
FIREBASE_AUTH_DOMAIN=
FIREBASE_PROJECT_ID=
FIREBASE_STORAGE_BUCKET=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_APP_ID=
FIREBASE_MEASUREMENT_ID=
FIREBASE_DATABASE_URL=

# Google Sign-In (Web)
GOOGLE_SIGN_IN_CLIENT_ID=

# ESP32 Camera Stream
# Replace with the IP of your ESP32 after it joins campus Wi‑Fi
ESP32_BASE_URL=http://192.168.x.x
ESP32_STREAM_PATH=/stream
ESP32_SNAPSHOT_PATH=/capture
ESP32_API_PATH=/update
```

## ESP32 Camera (WPA2-Enterprise)

The sketch at `CameraWebServer/CameraWebServer.ino` is configured for WPA2‑Enterprise (PEAP/MSCHAPv2). Update:

```c
const char *ssid = "YOUR_CLG_SSID";
const char *eap_identity = "YOUR_USERNAME";
const char *eap_username = "YOUR_USERNAME";
const char *eap_password = "YOUR_PASSWORD";
```

Flash the board, then check Serial Monitor for the assigned IP. Put that IP in `ESP32_BASE_URL`.

On Flutter, the camera stream shows on `HomeScreen` after sign‑in.
