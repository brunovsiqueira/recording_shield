import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recording_shield/recording_shield.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecordingShieldConfig', () {
    test('should have correct default values', () {
      const config = RecordingShieldConfig();

      expect(config.autoShowOverlay, true);
      expect(config.defaultMaskStyle, RecordingShieldMaskStyle.stripes);
      expect(config.blurSigma, 10.0);
      expect(config.detectScreenshots, false);
      expect(config.checkOnLaunch, true);
      expect(config.disableLogging, false);
    });

    test('should convert to map correctly', () {
      const config = RecordingShieldConfig(
        autoShowOverlay: false,
        defaultMaskStyle: RecordingShieldMaskStyle.blur,
        blurSigma: 15.0,
        detectScreenshots: true,
        checkOnLaunch: false,
        disableLogging: true,
      );

      final map = config.toMap();

      expect(map['autoShowOverlay'], false);
      expect(map['defaultMaskStyle'], 'blur');
      expect(map['blurSigma'], 15.0);
      expect(map['detectScreenshots'], true);
      expect(map['checkOnLaunch'], false);
      // disableLogging is not sent to native, only used in Dart
      expect(map.containsKey('disableLogging'), false);
    });
  });

  group('ScreenRecordingState', () {
    test('should have all expected values', () {
      expect(ScreenRecordingState.values, contains(ScreenRecordingState.unknown));
      expect(ScreenRecordingState.values, contains(ScreenRecordingState.notRecording));
      expect(ScreenRecordingState.values, contains(ScreenRecordingState.recording));
      expect(ScreenRecordingState.values, contains(ScreenRecordingState.unsupported));
    });
  });

  group('RecordingShieldMaskStyle', () {
    test('should have all expected values', () {
      expect(RecordingShieldMaskStyle.values, contains(RecordingShieldMaskStyle.stripes));
      expect(RecordingShieldMaskStyle.values, contains(RecordingShieldMaskStyle.blur));
      expect(RecordingShieldMaskStyle.values, contains(RecordingShieldMaskStyle.solid));
    });
  });

  group('RecordingShieldEvent', () {
    test('should store state and timestamp', () {
      final timestamp = DateTime.now();
      final event = RecordingShieldEvent(
        state: ScreenRecordingState.recording,
        timestamp: timestamp,
      );

      expect(event.state, ScreenRecordingState.recording);
      expect(event.timestamp, timestamp);
    });

    test('should have readable toString', () {
      final event = RecordingShieldEvent(
        state: ScreenRecordingState.recording,
        timestamp: DateTime(2024, 1, 1),
      );

      expect(event.toString(), contains('RecordingShieldEvent'));
      expect(event.toString(), contains('recording'));
    });
  });

  group('ScreenshotEvent', () {
    test('should store timestamp', () {
      final timestamp = DateTime.now();
      final event = ScreenshotEvent(timestamp: timestamp);

      expect(event.timestamp, timestamp);
    });
  });

  group('RecordingShieldController', () {
    test('should be a singleton', () {
      final instance1 = RecordingShieldController.instance;
      final instance2 = RecordingShieldController.instance;

      expect(identical(instance1, instance2), true);
    });

    test('should start with unknown state', () {
      final controller = RecordingShieldController.instance;

      expect(controller.recordingState.value, ScreenRecordingState.unknown);
    });

    test('should report isRecording correctly', () {
      final controller = RecordingShieldController.instance;

      // Default state is unknown, so isRecording should be false
      expect(controller.isRecording, false);
    });
  });

  group('RecordingShieldMask', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: RecordingShieldMask(
            child: Text('Sensitive'),
          ),
        ),
      );

      expect(find.text('Sensitive'), findsOneWidget);
    });

    testWidgets('should accept custom style', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: RecordingShieldMask(
            style: RecordingShieldMaskStyle.blur,
            child: Text('Blurred'),
          ),
        ),
      );

      expect(find.text('Blurred'), findsOneWidget);
    });
  });
}
