import 'dart:async';

import 'package:flutter/material.dart';
import 'package:recording_shield/recording_shield.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Recording Shield
  await RecordingShieldController.instance.setup(
    const RecordingShieldConfig(
      autoShowOverlay: true,
      defaultMaskStyle: RecordingShieldMaskStyle.stripes,
      detectScreenshots: true,
      checkOnLaunch: true,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RecordingShieldOverlay(
      child: MaterialApp(
        title: 'Recording Shield Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const DemoPage(),
      ),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  StreamSubscription<RecordingShieldEvent>? _recordingSubscription;
  StreamSubscription<ScreenshotEvent>? _screenshotSubscription;

  @override
  void initState() {
    super.initState();

    // Listen to recording state changes
    _recordingSubscription =
        RecordingShieldController.instance.recordingStateStream.listen((event) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording state: ${event.state.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    });

    // Listen to screenshot events
    _screenshotSubscription =
        RecordingShieldController.instance.screenshotStream.listen((event) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Screenshot detected!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    });
  }

  @override
  void dispose() {
    _recordingSubscription?.cancel();
    _screenshotSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording Shield Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RecordingStatusCard(),
            const SizedBox(height: 24),
            const PublicContentSection(),
            const SizedBox(height: 24),
            const SensitiveStripesSection(),
            const SizedBox(height: 24),
            const SensitiveBlurSection(),
            const SizedBox(height: 24),
            const SensitiveSolidSection(),
            const SizedBox(height: 24),
            const CheckStateButton(),
          ],
        ),
      ),
    );
  }
}

/// Card showing the current recording status.
class RecordingStatusCard extends StatelessWidget {
  const RecordingStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ScreenRecordingState>(
      valueListenable: RecordingShieldController.instance.recordingState,
      builder: (context, state, child) {
        final isRecording = state == ScreenRecordingState.recording;
        return Card(
          color: isRecording ? Colors.red.shade100 : Colors.green.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  isRecording ? Icons.videocam : Icons.videocam_off,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Text(
                  'Status: ${state.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Section showing public content that is always visible.
class PublicContentSection extends StatelessWidget {
  const PublicContentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Public Content',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'This content is always visible, even during recording.',
            ),
          ),
        ),
      ],
    );
  }
}

/// Section showing sensitive content with stripes mask.
class SensitiveStripesSection extends StatelessWidget {
  const SensitiveStripesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sensitive Content (Stripes)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        RecordingShieldMask(
          style: RecordingShieldMaskStyle.stripes,
          child: Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.credit_card, size: 48),
                  SizedBox(height: 8),
                  Text('**** **** **** 1234'),
                  Text('JOHN DOE'),
                  Text('12/25'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Section showing sensitive content with blur mask.
class SensitiveBlurSection extends StatelessWidget {
  const SensitiveBlurSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sensitive Content (Blur)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        RecordingShieldMask(
          style: RecordingShieldMaskStyle.blur,
          child: Card(
            color: Colors.purple.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.lock, size: 48),
                  SizedBox(height: 8),
                  Text('Secret PIN: 1234'),
                  Text('This will be blurred when recording'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Section showing sensitive content with solid mask.
class SensitiveSolidSection extends StatelessWidget {
  const SensitiveSolidSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sensitive Content (Solid)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        RecordingShieldMask(
          style: RecordingShieldMaskStyle.solid,
          child: Card(
            color: Colors.orange.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.key, size: 48),
                  SizedBox(height: 8),
                  Text('API Key: sk_live_xxx'),
                  Text('This will be fully covered'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Button to manually check the recording state.
class CheckStateButton extends StatelessWidget {
  const CheckStateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final state =
            await RecordingShieldController.instance.checkRecordingState();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Current state: ${state.name}')),
          );
        }
      },
      child: const Text('Check Recording State'),
    );
  }
}
