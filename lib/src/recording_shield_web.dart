import 'dart:async';

import 'recording_shield_config.dart';
import 'recording_shield_platform_interface.dart';
import 'recording_shield_state.dart';

/// Web stub implementation of [RecordingShieldPlatformInterface].
///
/// Screen recording detection is not supported on web platforms.
class RecordingShieldWeb extends RecordingShieldPlatformInterface {
  @override
  Future<void> setup(RecordingShieldConfig config) async {
    // No-op on web
  }

  @override
  Future<ScreenRecordingState> checkRecordingState() async {
    return ScreenRecordingState.unsupported;
  }

  @override
  Stream<RecordingShieldEvent> get recordingStateStream {
    return const Stream.empty();
  }

  @override
  Stream<ScreenshotEvent> get screenshotStream {
    return const Stream.empty();
  }

  @override
  Future<void> dispose() async {
    // No-op on web
  }
}
