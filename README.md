# Recording Shield

A Flutter plugin that detects screen recording in real-time and dynamically overlays visual masks on sensitive widgets.

## Features

- **iOS 11+**: Real-time screen recording detection using `UIScreen.isCaptured`
- **Android 35+**: Real-time screen recording detection using `WindowManager.addScreenRecordingCallback`
- **Screenshot Detection**: Detect when screenshots are taken (iOS and Android 34+)
- **Widget Masking**: Mark sensitive widgets to be masked during recording
- **Multiple Mask Styles**: Stripes, blur, and solid color masks

## Platform Support

| Platform | Recording Detection | Screenshot Detection |
|----------|--------------------|--------------------|
| iOS 11+ | ✅ Real-time | ✅ After capture |
| Android 35+ | ✅ Real-time | ✅ After capture |
| Android 34 | ❌ | ✅ After capture |
| Android <34 | ❌ | ⚠️ Limited |
| Web | ❌ | ❌ |

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  recording_shield:
    git:
      url: https://github.com/brunovsiqueira/recording_shield.git
```

## Usage

### 1. Initialize the plugin

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RecordingShieldController.instance.setup(
    RecordingShieldConfig(
      autoShowOverlay: true,
      defaultMaskStyle: RecordingShieldMaskStyle.stripes,
    ),
  );

  runApp(MyApp());
}
```

### 2. Wrap your app with RecordingShieldOverlay

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RecordingShieldOverlay(
      child: MaterialApp(
        home: HomePage(),
      ),
    );
  }
}
```

### 3. Mark sensitive widgets

```dart
RecordingShieldMask(
  style: RecordingShieldMaskStyle.blur,
  child: CreditCardWidget(),
)
```

### 4. Listen to events (optional)

```dart
// Listen to recording state changes
RecordingShieldController.instance.recordingStateStream.listen((event) {
  print('Recording state: ${event.state}');
});

// Listen to screenshot events
RecordingShieldController.instance.screenshotStream.listen((event) {
  print('Screenshot detected at ${event.timestamp}');
});
```

## Configuration Options

```dart
RecordingShieldConfig(
  autoShowOverlay: true,              // Auto-show mask on recording
  defaultMaskStyle: RecordingShieldMaskStyle.stripes,
  maskColor: Colors.black87,
  blurSigma: 10.0,
  detectScreenshots: false,           // Set to true to detect screenshots
  checkOnLaunch: true,                // Check state on app launch
  disableLogging: false,              // Set to true to suppress debug logs
)
```

## Mask Styles

- `RecordingShieldMaskStyle.stripes` - Diagonal stripe pattern
- `RecordingShieldMaskStyle.blur` - Gaussian blur effect
- `RecordingShieldMaskStyle.solid` - Solid color overlay

## Running the Example

```bash
cd example
flutter run
```

Or open the project root in VS Code and use the "Example App" launch configuration.

## Important Notes

- **Screenshots cannot be intercepted or modified** - detection happens AFTER capture
- On unsupported platforms, the plugin gracefully degrades (no errors, no masking)
- The overlay only appears in the recording, not on the user's screen

## License

MIT License - see LICENSE file for details.
