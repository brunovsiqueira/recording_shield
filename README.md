# Recording Shield

A Flutter plugin that detects screen recording in real-time and protects sensitive content from being captured.

## Features

- **Invisible Protection**: User sees normal content, recordings capture blank/black screen
- **Real-time Detection**: Detects when screen recording starts and stops
- **Screenshot Detection**: Detect when screenshots are taken
- **Widget Marking**: Mark specific widgets as sensitive for protection
- **Optional Overlay Mode**: Visual overlays (stripes, blur, solid) as an alternative

## How It Works

By default, Recording Shield uses **secure mode** which provides invisible protection:

| Platform | Protection Method | User Sees | Recording Captures |
|----------|------------------|-----------|-------------------|
| **iOS** | `isSecureTextEntry` hack | Normal content | Blank/black area |
| **Android** | `FLAG_SECURE` | Normal content | Black screen |

The user experiences no visual change, but recordings cannot capture the protected content.

## Platform Support Matrix

### Recording Detection

| Platform | Supported | API/Method |
|----------|-----------|------------|
| iOS 11+ | ✅ | `UIScreen.isCaptured` + `capturedDidChangeNotification` |
| Android 35+ (API 35) | ✅ | `WindowManager.addScreenRecordingCallback` |
| Android < 35 | ❌ | Not supported by OS |
| Web | ❌ | Not supported by browsers |

### Screenshot Detection

| Platform | Supported | API/Method |
|----------|-----------|------------|
| iOS 11+ | ✅ | `UIApplication.userDidTakeScreenshotNotification` |
| Android 34+ (API 34) | ✅ | `Activity.ScreenCaptureCallback` |
| Android < 34 | ❌ | Not supported |
| Web | ❌ | Not supported |

### Protection Methods

| Platform | Secure Mode | Overlay Mode |
|----------|-------------|--------------|
| iOS | ✅ Blank in recordings | ✅ Stripes/blur/solid |
| Android | ✅ Black screen (entire window) | ✅ Stripes/blur/solid |
| Web | ❌ | ❌ |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  recording_shield:
    git:
      url: https://github.com/brunovsiqueira/recording_shield.git
```

### Android Requirements

- **Minimum SDK**: 21
- **Recording Detection**: Requires Android 35+ (API 35)
- **Screenshot Detection**: Requires Android 34+ (API 34)
- **Permission**: `DETECT_SCREEN_RECORDING` (automatically included by plugin)

### iOS Requirements

- **Minimum iOS**: 11.0
- **Recording Detection**: Works on iOS 11+
- **Screenshot Detection**: Works on iOS 11+
- **No special permissions required**

## Quick Start

```dart
import 'package:recording_shield/recording_shield.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize with default config
  await RecordingShieldController.instance.setup(
    const RecordingShieldConfig(),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RecordingShieldOverlay(
      child: MaterialApp(
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('This content is always visible'),

          // This widget is protected
          RecordingShieldMask(
            child: CreditCardWidget(),
          ),
        ],
      ),
    );
  }
}
```

## Configuration Reference

### RecordingShieldConfig

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `useSecureModeOnIOS` | `bool` | `true` | **iOS only.** When `true`, uses the `isSecureTextEntry` hack to make content appear blank in recordings. User sees normal content. When `false`, falls back to overlay mode. |
| `useSecureModeOnAndroid` | `bool` | `true` | **Android only.** When `true`, uses `FLAG_SECURE` to make the entire screen black in recordings. User sees normal content. When `false`, falls back to overlay mode. **Note:** FLAG_SECURE affects the entire window, not individual widgets. |
| `autoShowOverlay` | `bool` | `true` | When secure mode is disabled, automatically shows overlay masks when recording is detected. |
| `defaultMaskStyle` | `RecordingShieldMaskStyle` | `stripes` | Default overlay style for `RecordingShieldMask` widgets. Options: `stripes`, `blur`, `solid`. Only used when secure mode is disabled. |
| `maskColor` | `Color` | `Color(0xDD000000)` | Color for stripe and solid overlays. |
| `blurSigma` | `double` | `10.0` | Blur intensity for blur overlay. |
| `detectScreenshots` | `bool` | `false` | Whether to emit events when screenshots are taken. Does not prevent screenshots. |
| `checkOnLaunch` | `bool` | `true` | Check recording state immediately on setup. |
| `disableLogging` | `bool` | `false` | Suppress debug logs even in debug mode. |

### RecordingShieldMaskStyle

| Style | Description |
|-------|-------------|
| `stripes` | Diagonal stripe pattern overlay |
| `blur` | Gaussian blur effect |
| `solid` | Solid color overlay |

## API Reference

### RecordingShieldController

```dart
// Singleton instance
RecordingShieldController.instance

// Initialize the plugin
await controller.setup(RecordingShieldConfig config)

// Check if currently recording
bool isRecording

// Current recording state
ValueNotifier<ScreenRecordingState> recordingState

// Stream of recording state changes
Stream<RecordingShieldEvent> recordingStateStream

// Stream of screenshot events (if detectScreenshots: true)
Stream<ScreenshotEvent> screenshotStream

// Manually check recording state
Future<ScreenRecordingState> checkRecordingState()

// Manually enable/disable secure mode
Future<void> enableSecureMode()
Future<void> disableSecureMode()

// Check if secure mode is supported on current platform
bool isSecureModeSupported

// Check if secure mode should be used based on config
bool shouldUseSecureMode

// Clean up resources
Future<void> dispose()
```

### ScreenRecordingState

| State | Description |
|-------|-------------|
| `recording` | Screen recording is active |
| `notRecording` | Screen recording is not active |
| `unsupported` | Platform doesn't support recording detection |
| `unknown` | State couldn't be determined |

## Usage Examples

### Basic Protection (Recommended)

```dart
// Default secure mode - user sees content, recordings see blank/black
RecordingShieldConfig()
```

### With Screenshot Detection

```dart
RecordingShieldConfig(
  detectScreenshots: true,
)

// Listen to screenshot events
controller.screenshotStream.listen((event) {
  print('Screenshot taken at ${event.timestamp}');
  // Show warning, log event, etc.
});
```

### Overlay Mode (Visible Protection)

```dart
// User AND recording both see the overlay
RecordingShieldConfig(
  useSecureModeOnIOS: false,
  useSecureModeOnAndroid: false,
  autoShowOverlay: true,
  defaultMaskStyle: RecordingShieldMaskStyle.blur,
)
```

### Custom Overlay Per Widget

```dart
RecordingShieldMask(
  style: RecordingShieldMaskStyle.blur,  // Override default
  child: SensitiveWidget(),
)
```

### Listen to Recording State

```dart
// Using ValueNotifier
controller.recordingState.addListener(() {
  if (controller.isRecording) {
    print('Recording started!');
  }
});

// Using Stream
controller.recordingStateStream.listen((event) {
  print('State: ${event.state}');
});
```

## Limitations

### iOS
- `isSecureTextEntry` hack is undocumented and may change in future iOS versions
- Screenshot detection is reactive only (happens after capture)

### Android
- Recording detection requires Android 35+ (API 35)
- `FLAG_SECURE` affects the **entire window**, not individual widgets
- Screenshot detection requires Android 34+ (API 34)
- Screenshots cannot be prevented, only detected after capture

### General
- **Simulators/Emulators do NOT work** - must test on physical devices
- Screenshots cannot be intercepted or modified
- No web support

## Testing

> **Important:** Recording detection requires a **physical device**.

### iOS Testing
1. Run on a physical iPhone/iPad
2. Open Control Center (swipe down from top-right)
3. Tap Screen Recording button
4. Verify protected content appears blank in the recording

### Android Testing
1. Run on a physical Android device with API 35+
2. Use the device's built-in screen recorder
3. Verify the screen appears black in the recording

## Troubleshooting

### Recording not detected on Android
- Ensure device is Android 35+ (API 35)
- Check logs for permission errors
- The `DETECT_SCREEN_RECORDING` permission is required

### Recording not detected on iOS Simulator
- Expected behavior - simulators don't support `UIScreen.isCaptured`
- Test on a physical device

### FLAG_SECURE not working on Android
- Ensure `useSecureModeOnAndroid: true` in config
- FLAG_SECURE only activates when recording is detected AND mask widgets exist

## License

MIT License - see LICENSE file for details.
