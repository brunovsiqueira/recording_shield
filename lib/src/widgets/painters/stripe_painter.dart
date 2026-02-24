import 'package:flutter/material.dart';

/// A widget that displays diagonal stripes as a mask.
class StripeMask extends StatelessWidget {
  /// The color of the stripes.
  final Color color;

  /// The width of each stripe.
  final double stripeWidth;

  /// The gap between stripes.
  final double gapWidth;

  const StripeMask({
    super.key,
    this.color = const Color(0xDD000000),
    this.stripeWidth = 8.0,
    this.gapWidth = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: StripePainter(
          color: color,
          stripeWidth: stripeWidth,
          gapWidth: gapWidth,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Custom painter that draws diagonal stripes.
class StripePainter extends CustomPainter {
  /// The color of the stripes.
  final Color color;

  /// The width of each stripe.
  final double stripeWidth;

  /// The gap between stripes.
  final double gapWidth;

  StripePainter({
    required this.color,
    this.stripeWidth = 8.0,
    this.gapWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Fill background with a lighter version of the color
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw diagonal stripes
    final stripeSpacing = stripeWidth + gapWidth;
    final diagonal = size.width + size.height;

    for (double i = -diagonal; i < diagonal; i += stripeSpacing) {
      final path = Path();
      path.moveTo(i, 0);
      path.lineTo(i + stripeWidth, 0);
      path.lineTo(i + stripeWidth + size.height, size.height);
      path.lineTo(i + size.height, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(StripePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.stripeWidth != stripeWidth ||
        oldDelegate.gapWidth != gapWidth;
  }
}
