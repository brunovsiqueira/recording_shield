import 'dart:ui';

import 'package:flutter/material.dart';

/// A widget that displays a blur effect as a mask.
class BlurMask extends StatelessWidget {
  /// The blur sigma value (higher = more blur).
  final double sigma;

  /// Optional overlay color to tint the blur.
  final Color? overlayColor;

  const BlurMask({
    super.key,
    this.sigma = 10.0,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
        ),
        child: Container(
          color: overlayColor ?? Colors.black.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}
