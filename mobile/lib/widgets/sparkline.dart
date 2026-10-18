import 'package:flutter/material.dart';

// Swiss Minimalist Financial Terminal - Sparkline Chart Widget
// Invariant: ZERO half-space characters (\\u200c) allowed.

class SparklineGraph extends StatelessWidget {
  final List<double> points;
  final Color lineColor;
  final double height;
  final bool showArea;

  const SparklineGraph({
    super.key,
    required this.points,
    required this.lineColor,
    this.height = 36,
    this.showArea = true,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _SparklinePainter(
          points: points,
          lineColor: lineColor,
          showArea: showArea,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final bool showArea;

  _SparklinePainter({
    required this.points,
    required this.lineColor,
    required this.showArea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    double minVal = points.first;
    double maxVal = points.first;
    for (final p in points) {
      if (p < minVal) minVal = p;
      if (p > maxVal) maxVal = p;
    }

    final double range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);
    final double stepX = size.width / (points.length - 1);

    final linePath = Path();
    final areaPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      // Invert Y so highest value is at top
      final normalizedY = (points[i] - minVal) / range;
      final y = size.height - (normalizedY * (size.height - 4) + 2);

      if (i == 0) {
        linePath.moveTo(x, y);
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }

    if (showArea) {
      areaPath.lineTo(size.width, size.height);
      areaPath.close();

      final areaPaint = Paint()
        ..color = lineColor.withOpacity(0.08)
        ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, areaPaint);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}
