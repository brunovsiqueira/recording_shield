# Recording Shield Example

This folder contains example apps demonstrating the Recording Shield plugin.

## Examples

### Basic Example (`lib/main.dart`)

A minimal example showing core functionality:
- Initialize the plugin
- Wrap the app with `RecordingShieldOverlay`
- Mark sensitive content with `RecordingShieldMask`

```bash
flutter run
```

### Advanced Example (`lib/advanced_example.dart`)

A comprehensive demo showcasing all features:
- All three mask styles (stripes, blur, solid)
- Recording state indicator
- Screenshot detection with snackbar notifications
- Manual state checking
- Proper stream subscription management

```bash
flutter run -t lib/advanced_example.dart
```

## Testing Recording Detection

> **Important:** Recording detection requires a **physical device**. Simulators and emulators do NOT work.

### iOS (Physical Device Required)
1. Run the app on a **real iPhone/iPad**
2. Open **Control Center** (swipe down from top-right)
3. Tap the **Screen Recording** button
4. Observe the mask appearing over sensitive widgets

The iOS Simulator's record button captures externally and won't trigger detection.

### Android (Physical Device Required, API 35+)
1. Run the app on a **real Android device** with API 35+
2. Start the built-in screen recorder
3. Observe the mask appearing over sensitive widgets

The Android Emulator's record button is external and won't trigger detection.
