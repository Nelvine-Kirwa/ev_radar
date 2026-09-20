import 'dart:math' as math;
import 'package:flutter/material.dart';

class BatteryGauge extends StatelessWidget {
  final double percent; // 0.0 to 1.0
  final double size;
  final Color accent;

  const BatteryGauge({
    super.key,
    required this.percent,
    this.size = 180,
    this.accent = const Color(0xFF00C853),
  });

  Color get _color {
    if (percent <= 0.15) return const Color(0xFFD32F2F);
    if (percent <= 0.40) return const Color(0xFFFFA000);
    return accent;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(percent: percent, color: _color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percent;
  final Color color;

  _GaugePainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 14.0;

    // Background track (dark ring)
    final trackPaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Colored progress arc (starts at top, goes clockwise)
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // top
    final sweepAngle = 2 * math.pi * percent.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.color != color;
  }
}