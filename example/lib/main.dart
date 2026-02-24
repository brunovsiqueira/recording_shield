import 'package:flutter/material.dart';
import 'package:recording_shield/recording_shield.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RecordingShieldController.instance.setup(
    const RecordingShieldConfig(
      autoShowOverlay: true,
      defaultMaskStyle: RecordingShieldMaskStyle.stripes,
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
        home: Scaffold(
          appBar: AppBar(title: const Text('Recording Shield')),
          body: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Public content - always visible
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('This content is always visible.'),
                  ),
                ),
                SizedBox(height: 16),
                // Sensitive content - masked when recording
                RecordingShieldMask(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.credit_card, size: 48),
                          SizedBox(height: 8),
                          Text('**** **** **** 1234'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
