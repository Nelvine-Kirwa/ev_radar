import 'package:flutter/material.dart';
import '../models/trip_plan.dart';

class ElevationChart extends StatelessWidget {
  final List<ElevationPoint> points;
  final String waypointLeft;
  final String waypointMid;
  final String waypointRight;

  const ElevationChart({
    super.key,
    required this.points,
    required this.waypointLeft,
    required this.waypointMid,
    required this.waypointRight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 140,
          child: CustomPaint(
            painter: _ElevationPainter(points: points),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(waypointLeft,
                style: const TextStyle(
                    color: Color(0xFF8892B0), fontSize: 10)),
            Text(waypointMid,
                style: const TextStyle(
                    color: Color(0xFF8892B0), fontSize: 10)),
            Text(waypointRight,
                style: const TextStyle(
                    color: Color(0xFF8892B0), fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _ElevationPainter extends CustomPainter {
  final List<ElevationPoint> points;

  _ElevationPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxElevation = 2000.0;
    final leftPad = 4.0;
    final rightPad = 4.0;
    final topPad = 8.0;
    final bottomPad = 4.0;
    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    // Horizontal gridlines
    final gridPaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..strokeWidth = 0.6;
    for (int i = 0; i <= 2; i++) {
      final y = topPad + (chartHeight / 2) * i;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y),
          gridPaint);
    }

    // Elevation curve
    final elevationPath = Path();
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = leftPad + chartWidth * p.progress;
      final y = topPad + chartHeight * (1 - p.elevationM / maxElevation);
      if (i == 0) {
        elevationPath.moveTo(x, y);
      } else {
        elevationPath.lineTo(x, y);
      }
    }

    final elevationFillPath = Path.from(elevationPath)
      ..lineTo(size.width - rightPad, size.height - bottomPad)
      ..lineTo(leftPad, size.height - bottomPad)
      ..close();

    // Fill gradient under the curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00C853).withOpacity(0.25),
          const Color(0xFF00C853).withOpacity(0.02),
        ],
      ).createShader(
          Rect.fromLTWH(0, topPad, size.width, chartHeight));

    canvas.drawPath(elevationFillPath, fillPaint);

    // Solid elevation line
    canvas.drawPath(
      elevationPath,
      Paint()
        ..color = const Color(0xFF00C853)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );

    // Dashed battery line
    final batteryPaint = Paint()
      ..color = const Color(0xFF8892B0)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    Offset? prev;
    for (final p in points) {
      final x = leftPad + chartWidth * p.progress;
      final y = topPad + chartHeight * (1 - p.batteryPercent / 100);
      final current = Offset(x, y);
      if (prev != null) {
        _drawDashedLine(canvas, prev, current, batteryPaint);
      }
      prev = current;
    }
  }

  void _drawDashedLine(
      Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashLength = 4.0;
    const gapLength = 4.0;
    final totalDistance = (to - from).distance;
    if (totalDistance == 0) return;
    final direction = (to - from) / totalDistance;
    double distance = 0;
    while (distance < totalDistance) {
      final start = from + direction * distance;
      final end = from +
          direction * (distance + dashLength).clamp(0, totalDistance);
      canvas.drawLine(start, end, paint);
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _ElevationPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}