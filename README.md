# QalqanDSM

**QalqanDSM** is a Flutter mobile app for encrypting/decrypting data and secure messaging over the **Matrix** protocol. It supports audio calls (WebRTC), push notifications (FCM), local notifications, and multilingual UI (kk/ru/en).

## Features

- **Encryption / Decryption**
    - Native Kotlin implementation invoked from Flutter via `MethodChannel("com.qalqan/app")`.
    - Key initialization flow creates a protected key file **`abc.bin`** in the app’s external files directory.
- **Media handling**
    - Encrypt/decrypt text and files; preview media; share files; record audio.
- **Matrix chat**
    - Sign in against a homeserver (default: `https://webqalqan.com`).
    - Direct/group rooms, messages, attachments.
    - Background sync and **FCM** push notifications.
- **Audio calls**
    - Incoming/outgoing calls using `flutter_webrtc` and `flutter_callkit_incoming`.
    - System call UIs (full-screen intent on Android).
- **Localization**
    - `kk`, `ru`, `en` (ARB files in `lib/l10n/`).
- **App flow**
    - Splash → Start → Init Key → Home → Encrypt/Decrypt → Login/Chat.

## Tech Stack

### Flutter / Dart
- Dart SDK: `>= 3.8.1`
- Core packages (selection):
    - `matrix`, `flutter_olm`
    - `flutter_webrtc`
    - `firebase_core`, `firebase_messaging`
    - `flutter_local_notifications`
    - `flutter_callkit_incoming`
    - `just_audio`, `video_player`, `record`
    - `file_picker`, `image_picker`, `file_selector`
    - `flutter_secure_storage`, `shared_preferences`
    - `permission_handler`, `url_launcher`, `intl`, `uuid`
- Dev:
    - `flutter_native_splash`, `flutter_launcher_icons`, `flutter_lints`

### Android (Kotlin)
- Package/namespace: `com.mycompany.qalqan_dsm`
- JDK 17, NDK in use, core library desugaring enabled.
- Native crypto / helpers in:
    - `android/app/src/main/kotlin/com/mycompany/qalqan_dsm/`
        - `Qalqan.kt`, `QKeys.kt`, `EncryptKeys.kt`, `Utils.kt`, `MainActivity.kt`
- Extra libs:
    - `org.matrix.android:olm-sdk`
    - `com.google.crypto.tink:tink`
- Release build:
    - `minifyEnabled true`, `shrinkResources true` (ProGuard/R8 rules included).

## Crypto & Keys

- Key initialization lets the user pick key type (`all` / `session`) and set a password.
- Keys are encrypted and stored as `*.bin` in the app’s external files directory (`getExternalFilesDir()`).
- Flutter ↔ Kotlin bridge via `MethodChannel("com.qalqan/app")`.

## Matrix & Push

- Default homeserver: `https://webqalqan.com`.
- Push registration and gateway integration live under chat services.
- Background FCM handler is registered in `main.dart`.
- Live sync handled by a Matrix sync service.
- Calls:
    - `flutter_webrtc` + service classes for incoming/outgoing call screens.
    - On Android, uses `flutter_callkit_incoming` with full-screen notifications.

## Android Permissions

Declared in `AndroidManifest.xml` (selection):
- `INTERNET`, `ACCESS_NETWORK_STATE`
- `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`
- `FOREGROUND_SERVICE` (and related foreground service types on newer Android)
- `POST_NOTIFICATIONS`
- `MANAGE_OWN_CALLS`, `USE_FULL_SCREEN_INTENT`, `WAKE_LOCK`, `SYSTEM_ALERT_WINDOW`

> On Android 13+ the app must request notification permission and microphone access at runtime. For call screens/overlays, “Display over other apps” may be required by the system.

## Getting Started

### Prerequisites
- Flutter SDK (stable), Android Studio with Android SDK/NDK
- JDK 17
- An Android device or emulator
- (Optional) Firebase CLI/tools for testing push notifications