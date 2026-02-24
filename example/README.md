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

### iOS
1. Run the app on an iOS device or simulator
2. Open Control Center and start screen recording
3. Observe the mask appearing over sensitive widgets

### Android (API 35+)
1. Run the app on an Android device with API 35+
2. Start the built-in screen recorder
3. Observe the mask appearing over sensitive widgets

> **Note:** On Android < 35, recording detection is not supported and the masks will not appear.
