import 'package:flutter/material.dart';

import 'recording_shield_state.dart';

/// Configuration for the Recording Shield plugin.
class RecordingShieldConfig {
  /// Whether to automatically show overlay masks when recording is detected.
  /// Defaults to `true`.
  final bool autoShowOverlay;

  /// The default mask style to use when no specific style is set on a widget.
  /// Defaults to [RecordingShieldMaskStyle.stripes].
  final RecordingShieldMaskStyle defaultMaskStyle;

  /// The color to use for mask overlays.
  /// Defaults to `Colors.black87`.
  final Color maskColor;

  /// The blur sigma value for blur masks.
  /// Defaults to `10.0`.
  final double blurSigma;

  /// Whether to detect and emit screenshot events.
  /// Defaults to `false`.
  final bool detectScreenshots;

  /// Whether to check recording state on launch.
  /// Defaults to `true`.
  final bool checkOnLaunch;

  /// Whether to disable logging even in debug mode.
  /// By default, logging is enabled in debug mode (kDebugMode).
  /// Set to `true` to suppress all logs.
  /// Defaults to `false`.
  final bool disableLogging;

  const RecordingShieldConfig({
    this.autoShowOverlay = true,
    this.defaultMaskStyle = RecordingShieldMaskStyle.stripes,
    this.maskColor = const Color(0xDD000000),
    this.blurSigma = 10.0,
    this.detectScreenshots = false,
    this.checkOnLaunch = true,
    this.disableLogging = false,
  });

  /// Converts the config to a map for platform channel communication.
  Map<String, dynamic> toMap() {
    return {
      'autoShowOverlay': autoShowOverlay,
      'defaultMaskStyle': defaultMaskStyle.name,
      'maskColor': maskColor.toARGB32(),
      'blurSigma': blurSigma,
      'detectScreenshots': detectScreenshots,
      'checkOnLaunch': checkOnLaunch,
    };
  }

  @override
  String toString() => 'RecordingShieldConfig('
      'autoShowOverlay: $autoShowOverlay, '
      'defaultMaskStyle: $defaultMaskStyle, '
      'detectScreenshots: $detectScreenshots'
      ')';
}
