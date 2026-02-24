import 'package:flutter/material.dart';

import '../recording_shield_controller.dart';
import '../recording_shield_state.dart';
import 'painters/blur_mask.dart';
import 'painters/solid_mask.dart';
import 'painters/stripe_painter.dart';

/// Callback signature for custom overlay builders.
typedef OverlayBuilder = Widget Function(
    BuildContext context, ScreenRecordingState state);

/// Root wrapper widget that renders mask overlays when recording is detected.
///
/// This widget must wrap your app (typically around MaterialApp) to enable
/// recording detection overlay functionality.
///
/// Example:
/// ```dart
/// RecordingShieldOverlay(
///   child: MaterialApp(...),
/// )
/// ```
class RecordingShieldOverlay extends StatefulWidget {
  /// The child widget to wrap.
  final Widget child;

  /// Optional custom overlay builder for complete control over the overlay.
  final OverlayBuilder? overlayBuilder;

  const RecordingShieldOverlay({
    super.key,
    required this.child,
    this.overlayBuilder,
  });

  @override
  State<RecordingShieldOverlay> createState() => _RecordingShieldOverlayState();
}

class _RecordingShieldOverlayState extends State<RecordingShieldOverlay> {
  final GlobalKey _appKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Listen to recording state changes
    RecordingShieldController.instance.recordingState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    RecordingShieldController.instance.recordingState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    // Trigger rebuild when recording state changes
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = RecordingShieldController.instance;
    final config = controller.config;
    final isRecording = controller.isRecording;
    final autoShowOverlay = config?.autoShowOverlay ?? true;

    return Stack(
      key: _appKey,
      children: [
        // Main app content
        widget.child,

        // Overlay when recording is detected
        if (isRecording && autoShowOverlay)
          Positioned.fill(
            child: IgnorePointer(
              child: widget.overlayBuilder != null
                  ? widget.overlayBuilder!(context, controller.recordingState.value)
                  : const _DefaultOverlay(),
            ),
          ),
      ],
    );
  }
}

/// Default overlay widget that renders masks over registered sensitive widgets.
class _DefaultOverlay extends StatelessWidget {
  const _DefaultOverlay();

  @override
  Widget build(BuildContext context) {
    final controller = RecordingShieldController.instance;
    final maskRects = controller.getMaskWidgetRects();
    final config = controller.config;
    final maskColor = config?.maskColor ?? const Color(0xDD000000);
    final blurSigma = config?.blurSigma ?? 10.0;

    if (maskRects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: maskRects.map((maskRect) {
        return Positioned(
          left: maskRect.rect.left,
          top: maskRect.rect.top,
          width: maskRect.rect.width,
          height: maskRect.rect.height,
          child: _MaskWidget(
            style: maskRect.style,
            maskColor: maskColor,
            blurSigma: blurSigma,
          ),
        );
      }).toList(),
    );
  }
}

/// Widget that renders the appropriate mask based on the style.
class _MaskWidget extends StatelessWidget {
  final RecordingShieldMaskStyle style;
  final Color maskColor;
  final double blurSigma;

  const _MaskWidget({
    required this.style,
    required this.maskColor,
    required this.blurSigma,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case RecordingShieldMaskStyle.blur:
        return BlurMask(sigma: blurSigma);
      case RecordingShieldMaskStyle.solid:
        return SolidMask(color: maskColor);
      case RecordingShieldMaskStyle.stripes:
        return StripeMask(color: maskColor);
    }
  }
}
