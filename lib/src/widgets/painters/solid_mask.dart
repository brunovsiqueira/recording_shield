import 'package:flutter/material.dart';

/// A widget that displays a solid color as a mask.
class SolidMask extends StatelessWidget {
  /// The color of the solid mask.
  final Color color;

  /// Optional border radius for rounded corners.
  final BorderRadius? borderRadius;

  const SolidMask({
    super.key,
    this.color = const Color(0xDD000000),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
    );
  }
}
