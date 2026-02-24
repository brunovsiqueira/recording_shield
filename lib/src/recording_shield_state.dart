import 'package:flutter/material.dart';

/// The current state of screen recording detection.
enum ScreenRecordingState {
  /// Recording detection is not initialized or not supported.
  unknown,

  /// Screen is not being recorded.
  notRecording,

  /// Screen is actively being recorded.
  recording,

  /// Recording detection is not supported on this platform.
  unsupported,
}

/// Extension to parse [ScreenRecordingState] from a string.
extension ScreenRecordingStateExtension on ScreenRecordingState {
  /// Parses a string value to [ScreenRecordingState].
  static ScreenRecordingState fromString(String? value) {
    switch (value) {
      case 'recording':
        return ScreenRecordingState.recording;
      case 'notRecording':
        return ScreenRecordingState.notRecording;
      case 'unsupported':
        return ScreenRecordingState.unsupported;
      default:
        return ScreenRecordingState.unknown;
    }
  }
}

/// Available mask styles for overlay rendering.
enum RecordingShieldMaskStyle {
  /// Diagonal stripe pattern.
  stripes,

  /// Gaussian blur effect.
  blur,

  /// Solid color overlay.
  solid,
}

/// Event emitted when recording state changes.
class RecordingShieldEvent {
  /// The new recording state.
  final ScreenRecordingState state;

  /// Timestamp when the event occurred.
  final DateTime timestamp;

  const RecordingShieldEvent({
    required this.state,
    required this.timestamp,
  });

  @override
  String toString() =>
      'RecordingShieldEvent(state: $state, timestamp: $timestamp)';
}

/// Event emitted when a screenshot is detected.
class ScreenshotEvent {
  /// Timestamp when the screenshot was detected.
  final DateTime timestamp;

  const ScreenshotEvent({
    required this.timestamp,
  });

  @override
  String toString() => 'ScreenshotEvent(timestamp: $timestamp)';
}

/// Information about a registered mask widget.
class MaskWidgetInfo {
  /// The global key for the widget.
  final GlobalKey key;

  /// The mask style to apply.
  final RecordingShieldMaskStyle style;

  const MaskWidgetInfo({
    required this.key,
    required this.style,
  });
}
