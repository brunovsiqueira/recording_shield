import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'recording_shield_config.dart';
import 'recording_shield_platform_interface.dart';
import 'recording_shield_state.dart';

/// Singleton controller for Recording Shield functionality.
///
/// Use [RecordingShieldController.instance] to access the controller.
class RecordingShieldController {
  RecordingShieldController._();

  static final RecordingShieldController _instance =
      RecordingShieldController._();

  /// The singleton instance of the controller.
  static RecordingShieldController get instance => _instance;

  /// The current configuration.
  RecordingShieldConfig? _config;

  /// The current configuration.
  RecordingShieldConfig? get config => _config;

  /// Value notifier for the current recording state.
  final ValueNotifier<ScreenRecordingState> recordingState =
      ValueNotifier<ScreenRecordingState>(ScreenRecordingState.unknown);

  /// Registered mask widgets with their keys and styles.
  final Map<GlobalKey, RecordingShieldMaskStyle> _maskWidgets = {};

  /// Stream subscription for recording state events.
  StreamSubscription<RecordingShieldEvent>? _recordingStateSubscription;

  /// Stream subscription for screenshot events.
  StreamSubscription<ScreenshotEvent>? _screenshotSubscription;

  /// Stream controller for broadcasting recording events.
  final StreamController<RecordingShieldEvent> _recordingEventController =
      StreamController<RecordingShieldEvent>.broadcast();

  /// Stream controller for broadcasting screenshot events.
  final StreamController<ScreenshotEvent> _screenshotEventController =
      StreamController<ScreenshotEvent>.broadcast();

  /// Whether the controller has been initialized.
  bool _isInitialized = false;

  /// Whether the controller has been initialized.
  bool get isInitialized => _isInitialized;

  /// Whether secure mode is currently enabled.
  bool _isSecureModeEnabled = false;

  /// Whether secure mode is currently enabled.
  bool get isSecureModeEnabled => _isSecureModeEnabled;

  /// Whether secure mode is supported on this platform.
  bool get isSecureModeSupported =>
      RecordingShieldPlatformInterface.instance.isSecureModeSupported;

  /// Stream of recording state change events.
  Stream<RecordingShieldEvent> get recordingStateStream =>
      _recordingEventController.stream;

  /// Stream of screenshot events.
  Stream<ScreenshotEvent> get screenshotStream =>
      _screenshotEventController.stream;

  /// Whether the screen is currently being recorded.
  bool get isRecording =>
      recordingState.value == ScreenRecordingState.recording;

  /// Initialize the Recording Shield with the given configuration.
  ///
  /// This must be called before any other methods.
  Future<void> setup(RecordingShieldConfig config) async {
    if (_isInitialized) {
      _printDebug('Already initialized');
      return;
    }

    _config = config;

    // Setup the platform implementation
    await RecordingShieldPlatformInterface.instance.setup(config);

    // Subscribe to platform streams
    _recordingStateSubscription = RecordingShieldPlatformInterface
        .instance.recordingStateStream
        .listen(_handleRecordingStateEvent);

    _screenshotSubscription = RecordingShieldPlatformInterface
        .instance.screenshotStream
        .listen(_handleScreenshotEvent);

    // Check initial state if configured
    if (config.checkOnLaunch) {
      await checkRecordingState();
    }

    _isInitialized = true;
    _printDebug('Initialized successfully');
  }

  void _handleRecordingStateEvent(RecordingShieldEvent event) {
    recordingState.value = event.state;
    _recordingEventController.add(event);
    _printDebug('Recording state: ${event.state}');

    // Auto-enable/disable secure mode on iOS if configured
    _updateSecureModeForRecordingState(event.state);
  }

  void _updateSecureModeForRecordingState(ScreenRecordingState state) {
    if (!shouldUseSecureMode) {
      return;
    }

    if (state == ScreenRecordingState.recording && _maskWidgets.isNotEmpty) {
      enableSecureMode();
    } else if (state == ScreenRecordingState.notRecording) {
      disableSecureMode();
    }
  }

  void _handleScreenshotEvent(ScreenshotEvent event) {
    _screenshotEventController.add(event);
    _printDebug('Screenshot detected');
  }

  /// Manually check the current recording state.
  Future<ScreenRecordingState> checkRecordingState() async {
    final state = await RecordingShieldPlatformInterface.instance
        .checkRecordingState();
    recordingState.value = state;
    _printDebug('Checked recording state: $state');
    return state;
  }

  /// Enable secure mode.
  ///
  /// When enabled, the app appears blank/black in recordings and screenshots
  /// while remaining visible to the user.
  ///
  /// - **iOS**: Uses the isSecureTextEntry hack
  /// - **Android**: Uses FLAG_SECURE on the window
  Future<void> enableSecureMode() async {
    if (_isSecureModeEnabled) {
      _printDebug('Secure mode already enabled');
      return;
    }

    await RecordingShieldPlatformInterface.instance.enableSecureMode();
    _isSecureModeEnabled = true;
    _printDebug('Secure mode enabled');
  }

  /// Disable secure mode.
  Future<void> disableSecureMode() async {
    if (!_isSecureModeEnabled) {
      _printDebug('Secure mode not enabled');
      return;
    }

    await RecordingShieldPlatformInterface.instance.disableSecureMode();
    _isSecureModeEnabled = false;
    _printDebug('Secure mode disabled');
  }

  /// Register a mask widget with its global key and style.
  void registerMaskWidget(GlobalKey key, RecordingShieldMaskStyle style) {
    _maskWidgets[key] = style;
    _printDebug('Registered mask widget: ${key.hashCode}');

    // If recording is active and this is the first mask widget, enable secure mode
    if (isRecording) {
      _updateSecureModeForRecordingState(recordingState.value);
    }
  }

  /// Unregister a mask widget.
  void unregisterMaskWidget(GlobalKey key) {
    _maskWidgets.remove(key);
    _printDebug('Unregistered mask widget: ${key.hashCode}');

    // If no more mask widgets and secure mode is enabled, disable it
    if (_maskWidgets.isEmpty && _isSecureModeEnabled) {
      disableSecureMode();
    }
  }

  /// Whether to use secure mode or overlay mode for protection.
  ///
  /// Returns true if secure mode is enabled for the current platform
  /// and the platform supports it.
  bool get shouldUseSecureMode {
    if (!isSecureModeSupported) {
      return false;
    }

    try {
      if (Platform.isIOS) {
        return _config?.useSecureModeOnIOS ?? true;
      } else if (Platform.isAndroid) {
        return _config?.useSecureModeOnAndroid ?? true;
      }
    } catch (_) {
      // Platform not available (e.g., web)
    }

    return false;
  }

  /// Get all registered mask widgets with their current rects.
  List<MaskWidgetRect> getMaskWidgetRects() {
    final List<MaskWidgetRect> rects = [];

    for (final entry in _maskWidgets.entries) {
      final key = entry.key;
      final style = entry.value;

      final renderBox =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        final rect = Rect.fromLTWH(
          position.dx,
          position.dy,
          renderBox.size.width,
          renderBox.size.height,
        );
        rects.add(MaskWidgetRect(rect: rect, style: style));
      }
    }

    return rects;
  }

  /// Dispose the controller and clean up resources.
  Future<void> dispose() async {
    await _recordingStateSubscription?.cancel();
    await _screenshotSubscription?.cancel();
    await _recordingEventController.close();
    await _screenshotEventController.close();
    await RecordingShieldPlatformInterface.instance.dispose();
    _maskWidgets.clear();
    _isInitialized = false;
    _printDebug('Disposed');
  }

  void _printDebug(String message) {
    if (kDebugMode && !(_config?.disableLogging ?? false)) {
      // ignore: avoid_print
      print('[RecordingShield] $message');
    }
  }
}

/// A rect with its associated mask style.
class MaskWidgetRect {
  /// The rect in global coordinates.
  final Rect rect;

  /// The mask style to apply.
  final RecordingShieldMaskStyle style;

  const MaskWidgetRect({
    required this.rect,
    required this.style,
  });
}
