import 'package:flutter/widgets.dart';

import '../recording_shield_controller.dart';
import '../recording_shield_state.dart';

/// Widget that marks a child as sensitive and should be masked during recording.
///
/// When screen recording is detected, the area covered by this widget will be
/// masked with the specified style (or the default style from config).
///
/// Example:
/// ```dart
/// RecordingShieldMask(
///   style: RecordingShieldMaskStyle.blur,
///   child: CreditCardWidget(),
/// )
/// ```
class RecordingShieldMask extends StatefulWidget {
  /// The child widget to mark as sensitive.
  final Widget child;

  /// The mask style to use for this widget.
  /// If null, uses the default style from [RecordingShieldConfig].
  final RecordingShieldMaskStyle? style;

  const RecordingShieldMask({
    super.key,
    required this.child,
    this.style,
  });

  @override
  State<RecordingShieldMask> createState() => _RecordingShieldMaskState();
}

class _RecordingShieldMaskState extends State<RecordingShieldMask> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _registerWidget();
  }

  @override
  void didUpdateWidget(RecordingShieldMask oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style) {
      _unregisterWidget();
      _registerWidget();
    }
  }

  @override
  void dispose() {
    _unregisterWidget();
    super.dispose();
  }

  void _registerWidget() {
    final style = widget.style ??
        RecordingShieldController.instance.config?.defaultMaskStyle ??
        RecordingShieldMaskStyle.stripes;
    RecordingShieldController.instance.registerMaskWidget(_key, style);
  }

  void _unregisterWidget() {
    RecordingShieldController.instance.unregisterMaskWidget(_key);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      child: widget.child,
    );
  }
}
