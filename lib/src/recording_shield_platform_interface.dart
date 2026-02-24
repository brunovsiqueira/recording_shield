import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'recording_shield_config.dart';
import 'recording_shield_io.dart';
import 'recording_shield_state.dart';

/// The platform interface for Recording Shield.
abstract class RecordingShieldPlatformInterface extends PlatformInterface {
  /// Constructs a RecordingShieldPlatformInterface.
  RecordingShieldPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static RecordingShieldPlatformInterface _instance = RecordingShieldIO();

  /// The default instance of [RecordingShieldPlatformInterface] to use.
  static RecordingShieldPlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RecordingShieldPlatformInterface].
  static set instance(RecordingShieldPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize the plugin with the given configuration.
  Future<void> setup(RecordingShieldConfig config) {
    throw UnimplementedError('setup() has not been implemented.');
  }

  /// Check the current recording state.
  Future<ScreenRecordingState> checkRecordingState() {
    throw UnimplementedError('checkRecordingState() has not been implemented.');
  }

  /// Stream of recording state change events.
  Stream<RecordingShieldEvent> get recordingStateStream {
    throw UnimplementedError(
        'recordingStateStream has not been implemented.');
  }

  /// Stream of screenshot events.
  Stream<ScreenshotEvent> get screenshotStream {
    throw UnimplementedError('screenshotStream has not been implemented.');
  }

  /// Dispose the plugin and clean up resources.
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
