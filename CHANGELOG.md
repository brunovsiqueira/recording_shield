## 0.1.0

- Initial release
- iOS screen recording detection using `UIScreen.isCaptured`
- iOS screenshot detection using `UIApplication.userDidTakeScreenshotNotification`
- Android API 35+ screen recording detection using `WindowManager.addScreenRecordingCallback`
- Android API 34+ screenshot detection using `Activity.ScreenCaptureCallback`
- Widget-based masking with stripes, blur, and solid styles
- `RecordingShieldOverlay` wrapper widget
- `RecordingShieldMask` marker widget for sensitive content
- `RecordingShieldController` for programmatic control
