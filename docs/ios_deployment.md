# iOS Deployment

## Prerequisites
- A macOS machine with Xcode installed
- Apple Developer account (for device install, Ad Hoc, or TestFlight)
- CocoaPods installed on macOS (`sudo gem install cocoapods`)

## Project Settings To Confirm
- Bundle Identifier: `ios/Runner.xcodeproj` → Runner target → Signing & Capabilities
- Team: select your Apple Developer team
- Version and build: comes from `pubspec.yaml` (`version:`) via Flutter build settings
- Camera usage string: `NSCameraUsageDescription` in `ios/Runner/Info.plist`
- Local network usage string: `NSLocalNetworkUsageDescription` in `ios/Runner/Info.plist`
- HTTP hosts: `NSAppTransportSecurity` is configured to allow HTTP because HOST_URL is user-configurable

## Build Steps (macOS)
1. Fetch packages:
   - `flutter pub get`
2. Install iOS pods:
   - `cd ios && pod install && cd ..`
3. Build on device or archive:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select a real device
   - Product → Build (or Archive for TestFlight)

## Release Notes
- For App Store/TestFlight, review App Transport Security policies. Allowing arbitrary HTTP loads may require justification or a stricter per-domain exception strategy.
- Ensure the barcode scanning flow and local network access are clearly described in App Store privacy disclosures.

