import 'dart:io';

import 'package:flutter/material.dart';
import 'package:recording_shield/recording_shield.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RecordingShieldController.instance.setup(
    const RecordingShieldConfig(
      autoShowOverlay: true,
      defaultMaskStyle: RecordingShieldMaskStyle.stripes,
      detectScreenshots: true,
      useSecureModeOnIOS: true,
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
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const RecordingShieldDemo(),
      ),
    );
  }
}

class RecordingShieldDemo extends StatefulWidget {
  const RecordingShieldDemo({super.key});

  @override
  State<RecordingShieldDemo> createState() => _RecordingShieldDemoState();
}

class _RecordingShieldDemoState extends State<RecordingShieldDemo> {
  bool _protectionEnabled = true;
  bool _isRecording = false;
  int _screenshotCount = 0;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to recording state changes
    RecordingShieldController.instance.recordingState.addListener(_onRecordingStateChanged);

    // Listen to screenshot events
    RecordingShieldController.instance.screenshotStream.listen((_) {
      setState(() {
        _screenshotCount++;
      });
      _showSnackBar('Screenshot detected!');
    });

    // Check initial state
    _isRecording = RecordingShieldController.instance.isRecording;
  }

  void _onRecordingStateChanged() {
    final isRecording = RecordingShieldController.instance.isRecording;
    if (isRecording != _isRecording) {
      setState(() {
        _isRecording = isRecording;
      });
      _showSnackBar(isRecording ? 'Recording started!' : 'Recording stopped');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleProtection() {
    setState(() {
      _protectionEnabled = !_protectionEnabled;
    });
  }

  @override
  void dispose() {
    RecordingShieldController.instance.recordingState.removeListener(_onRecordingStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = _protectionEnabled
        ? const Color(0xFF4CAF50)  // Green
        : const Color(0xFFE57373); // Red

    const protectionMode = 'Secure Mode';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            color: headerColor,
            child: Column(
              children: [
                const Text(
                  'Recording Shield Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  protectionMode,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Status indicators
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusIndicator(
                  icon: Icons.videocam,
                  label: 'Recording',
                  isActive: _isRecording,
                  activeColor: Colors.red,
                ),
                _StatusIndicator(
                  icon: Icons.screenshot,
                  label: 'Screenshots: $_screenshotCount',
                  isActive: _screenshotCount > 0,
                  activeColor: Colors.orange,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Lock icon
                  Icon(
                    _protectionEnabled ? Icons.lock : Icons.lock_open,
                    size: 80,
                    color: _protectionEnabled ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 16),

                  // Protection status
                  Text(
                    'Protection is ${_protectionEnabled ? "ON" : "OFF"}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _protectionEnabled ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Instructions
                  Text(
                    _getInstructionText(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sensitive data card
                  if (_protectionEnabled)
                    RecordingShieldMask(
                      child: _SensitiveDataCard(),
                    )
                  else
                    _SensitiveDataCard(),

                  const SizedBox(height: 24),

                  // Toggle button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _toggleProtection,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: _protectionEnabled ? Colors.red : Colors.green,
                        ),
                      ),
                      child: Text(
                        _protectionEnabled ? 'Disable Protection' : 'Enable Protection',
                        style: TextStyle(
                          color: _protectionEnabled ? Colors.red : Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Info section
                  _InfoSection(isIOS: Platform.isIOS),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInstructionText() {
    if (Platform.isIOS) {
      return 'Start a screen recording to test.\n'
          'Protected content will appear blank in the recording.';
    } else {
      return 'Start a screen recording to test.\n'
          'The entire screen will appear black in the recording.';
    }
  }
}

class _StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;

  const _StatusIndicator({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : Colors.grey;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _SensitiveDataCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Column(
        children: [
          Text(
            'SENSITIVE DATA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '4444 5555 6666 7777',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'John Doe • 12/28',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final bool isIOS;

  const _InfoSection({required this.isIOS});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'How it works',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isIOS) ...[
            const _InfoItem(
              icon: Icons.check_circle,
              text: 'iOS uses secure mode: content appears blank in recordings',
            ),
            const _InfoItem(
              icon: Icons.visibility,
              text: 'You see normal content on your screen',
            ),
            const _InfoItem(
              icon: Icons.videocam_off,
              text: 'Recording captures blank/black area',
            ),
          ] else ...[
            const _InfoItem(
              icon: Icons.check_circle,
              text: 'Android uses FLAG_SECURE: screen appears black in recordings',
            ),
            const _InfoItem(
              icon: Icons.visibility,
              text: 'You see normal content on your screen',
            ),
            const _InfoItem(
              icon: Icons.android,
              text: 'Works on all Android versions when recording detected',
            ),
            const _InfoItem(
              icon: Icons.info_outline,
              text: 'Recording detection requires Android 35+',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
