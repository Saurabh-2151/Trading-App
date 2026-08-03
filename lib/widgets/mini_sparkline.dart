import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Mini Sparkline widget - displays a simple line chart placeholder
/// This is a placeholder implementation showing a random trend
class MiniSparkline extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final bool showPositiveTrend;

  const MiniSparkline({
    super.key,
    required this.color,
    this.width = 60,
    this.height = 24,
    this.showPositiveTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          color: color,
          showPositiveTrend: showPositiveTrend,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  final bool showPositiveTrend;

  _SparklinePainter({
    required this.color,
    required this.showPositiveTrend,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Generate 8 points for a simple sparkline
    const points = 8;
    final random = math.Random(42); // Fixed seed for consistent appearance
    
    // Start from middle-ish
    double startY = showPositiveTrend ? size.height * 0.7 : size.height * 0.3;
    path.moveTo(0, startY);

    for (int i = 1; i < points; i++) {
      final x = (size.width / (points - 1)) * i;
      
      // Create a general trend with some variance
      double baseY;
      if (showPositiveTrend) {
        // Upward trend: start high, end low
        baseY = size.height * (0.7 - (i / points) * 0.5);
      } else {
        // Downward trend: start low, end high
        baseY = size.height * (0.3 + (i / points) * 0.5);
      }
      
      // Add some random variance
      final variance = (random.nextDouble() - 0.5) * size.height * 0.2;
      final y = (baseY + variance).clamp(0.0, size.height);
      
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
