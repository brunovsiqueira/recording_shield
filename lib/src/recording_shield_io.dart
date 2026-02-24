import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'recording_shield_config.dart';
import 'recording_shield_platform_interface.dart';
import 'recording_shield_state.dart';

/// Checks if the current platform is supported.
bool isSupportedPlatform() {
  try {
    return Platform.isIOS || Platform.isAndroid;
  } catch (_) {
    return false;
  }
}

/// Mobile implementation of [RecordingShieldPlatformInterface].
class RecordingShieldIO extends RecordingShieldPlatformInterface {
  /// The method channel used to interact with the native platform.
  final _methodChannel = const MethodChannel('recording_shield');

  /// Event channel for recording state changes.
  final _recordingStateEventChannel =
      const EventChannel('recording_shield/recording_state');

  /// Event channel for screenshot events.
  final _screenshotEventChannel =
      const EventChannel('recording_shield/screenshots');

  /// Stream controller for recording state events.
  StreamController<RecordingShieldEvent>? _recordingStateController;

  /// Stream controller for screenshot events.
  StreamController<ScreenshotEvent>? _screenshotController;

  /// Subscription to native recording state events.
  StreamSubscription<dynamic>? _recordingStateSubscription;

  /// Subscription to native screenshot events.
  StreamSubscription<dynamic>? _screenshotSubscription;

  /// Whether logging is disabled.
  bool _disableLogging = false;

  @override
  Future<void> setup(RecordingShieldConfig config) async {
    if (!isSupportedPlatform()) {
      _printDebug('Platform not supported');
      return;
    }

    _disableLogging = config.disableLogging;

    try {
      await _methodChannel.invokeMethod('setup', config.toMap());
      _setupEventStreams();
      _printDebug('Setup completed successfully');
    } on PlatformException catch (e) {
      _printDebug('Setup failed: $e');
    }
  }

  void _setupEventStreams() {
    // Setup recording state stream
    _recordingStateController = StreamController<RecordingShieldEvent>.broadcast();
    _recordingStateSubscription = _recordingStateEventChannel
        .receiveBroadcastStream()
        .listen(_handleRecordingStateEvent, onError: _handleRecordingStateError);

    // Setup screenshot stream
    _screenshotController = StreamController<ScreenshotEvent>.broadcast();
    _screenshotSubscription = _screenshotEventChannel
        .receiveBroadcastStream()
        .listen(_handleScreenshotEvent, onError: _handleScreenshotError);
  }

  void _handleRecordingStateEvent(dynamic event) {
    if (event is Map) {
      final stateString = event['state'] as String?;
      final state = _parseRecordingState(stateString);
      final recordingEvent = RecordingShieldEvent(
        state: state,
        timestamp: DateTime.now(),
      );
      _recordingStateController?.add(recordingEvent);
      _printDebug('Recording state changed: $state');
    }
  }

  void _handleRecordingStateError(dynamic error) {
    _printDebug('Recording state stream error: $error');
  }

  void _handleScreenshotEvent(dynamic event) {
    final screenshotEvent = ScreenshotEvent(
      timestamp: DateTime.now(),
    );
    _screenshotController?.add(screenshotEvent);
    _printDebug('Screenshot detected');
  }

  void _handleScreenshotError(dynamic error) {
    _printDebug('Screenshot stream error: $error');
  }

  ScreenRecordingState _parseRecordingState(String? state) {
    switch (state) {
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

  @override
  Future<ScreenRecordingState> checkRecordingState() async {
    if (!isSupportedPlatform()) {
      return ScreenRecordingState.unsupported;
    }

    try {
      final result = await _methodChannel.invokeMethod<String>('checkRecordingState');
      return _parseRecordingState(result);
    } on PlatformException catch (e) {
      _printDebug('Check recording state failed: $e');
      return ScreenRecordingState.unknown;
    }
  }

  @override
  Stream<RecordingShieldEvent> get recordingStateStream {
    if (_recordingStateController == null) {
      // Return empty stream if not initialized
      return const Stream.empty();
    }
    return _recordingStateController!.stream;
  }

  @override
  Stream<ScreenshotEvent> get screenshotStream {
    if (_screenshotController == null) {
      return const Stream.empty();
    }
    return _screenshotController!.stream;
  }

  @override
  Future<void> dispose() async {
    if (!isSupportedPlatform()) {
      return;
    }

    try {
      await _recordingStateSubscription?.cancel();
      await _screenshotSubscription?.cancel();
      await _recordingStateController?.close();
      await _screenshotController?.close();
      await _methodChannel.invokeMethod('dispose');
      _printDebug('Disposed successfully');
    } on PlatformException catch (e) {
      _printDebug('Dispose failed: $e');
    }
  }

  void _printDebug(String message) {
    if (kDebugMode && !_disableLogging) {
      // ignore: avoid_print
      print('[RecordingShield] $message');
    }
  }
}
