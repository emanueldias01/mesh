# Mesh
Mesh is a real-time video meeting platform built with Flutter, WebRTC, and Go. It allows users to create meeting rooms, join existing rooms, and communicate through peer-to-peer audio and video calls.
## Features
- Create meeting rooms
- Join meetings using a room code
- Real-time audio and video communication
- Local persistence of signaling server addresses (Floor/SQLite)
- Cross-platform support
- WebRTC peer-to-peer connections
## Supported Platforms
- Android
- iOS
- Windows
- macOS
- Linux
## Requirements
Before running the application, make sure you have:
- Flutter SDK installed
- A running Mesh backend/signaling server
## Running the Application
### Development
```bash
flutter pub get
flutter run
```
### Android
```bash
flutter run -d android
```
### iOS
```bash
flutter run -d ios
```
### Windows
```bash
flutter run -d windows
```
### macOS
```bash
flutter run -d macos
```
### Linux
```bash
flutter run -d linux
```
## Building Releases
### Android APK
```bash
flutter build apk --release
```
### Windows
```bash
flutter build windows --release
```
### macOS
```bash
flutter build macos --release
```
### Linux
```bash
flutter build linux --release
```
## Build
### Android APK
```bash
flutter build apk --release
```
Output:
```text
build/app/outputs/flutter-apk/app-release.apk
```
---
### Android App Bundle
```bash
flutter build appbundle --release
```
Output:
```text
build/app/outputs/bundle/release/app-release.aab
```
---
### Windows
```bash
flutter build windows --release
```
Output:
```text
build/windows/x64/runner/Release/
```
Run:
```bash
Mesh.exe
```
---
### macOS
```bash
flutter build macos --release
```
Output:
```text
build/macos/Build/Products/Release/
```
Run:
```bash
Mesh.app
```
---
### Linux
```bash
flutter build linux --release
```
Output:
```text
build/linux/x64/release/bundle/
```
Run:
```bash
./mesh
```
---
### Verify Supported Platforms
```bash
flutter devices
```
### Enable Desktop Platforms
```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```
### Check Flutter Configuration
```bash
flutter doctor
```
## License
This project is available for educational and personal use.