import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadarLoader extends StatefulWidget {
  final double size;
  final String statusText;
  final Color accentColor;

  const RadarLoader({
    super.key,
    this.size = 220,
    this.statusText = 'SCANNING NEARBY STATIONS...',
    this.accentColor = const Color(0xFF00C853),
  });

  @override
  State<RadarLoader> createState() => _RadarLoaderState();
}

class _RadarLoaderState extends State<RadarLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radarSize = widget.size;
    final compassSize = widget.size * 1.3636;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: compassSize,
          height: compassSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(compassSize, compassSize),
                  painter: _CompassPainter(accent: widget.accentColor),
                ),
              ),
              RepaintBoundary(
                child: SizedBox(
                  width: radarSize,
                  height: radarSize,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _RadarPainter(
                          progress: _controller.value,
                          accent: widget.accentColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          widget.statusText,
          style: TextStyle(
            color: widget.accentColor,
            fontSize: 11,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------
// COMPASS RING — static, painted once
// ----------------------------------------------------------------
class _CompassPainter extends CustomPainter {
  final Color accent;

  _CompassPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2 - 2;

    // Radii as fractions of R
    final numbersRadius = R * 0.87;
    final tickOuterR = R * 0.80;
    final tickInnerR = R * 0.68;
    final letterRadius = R * 0.58;
    final triangleRadius = R * 0.52;
    final scannerR = R * 0.48;

    // ---- Ring strokes ----
    final ringStroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Outer ring
    canvas.drawCircle(center, R, ringStroke);

    // Ring between numbers and ticks
    canvas.drawCircle(
        center,
        tickOuterR,
        Paint()
          ..color = accent.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    // Ring between ticks and letters
    canvas.drawCircle(
        center,
        tickInnerR,
        Paint()
          ..color = accent.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    // Scanner boundary ring
    canvas.drawCircle(
        center,
        scannerR,
        Paint()
          ..color = accent.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    // ---- Degree numbers (every 15°) in the outer band ----
    for (int deg = 0; deg < 360; deg += 15) {
      final label = deg.toString().padLeft(3, '0');
      _drawText(
        canvas,
        label,
        center,
        numbersRadius,
        deg.toDouble() - 90,
        accent.withOpacity(0.85),
        7,
        FontWeight.w500,
      );
    }

    // ---- Ticks between tickOuterR and tickInnerR ----
    final longTick = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final mediumTick = Paint()
      ..color = accent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final shortTick = Paint()
      ..color = accent.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int deg = 0; deg < 360; deg += 5) {
      double tickLen;
      Paint paint;
      if (deg % 30 == 0) {
        tickLen = tickOuterR - tickInnerR; // full band
        paint = longTick;
      } else if (deg % 10 == 0) {
        tickLen = (tickOuterR - tickInnerR) * 0.6;
        paint = mediumTick;
      } else {
        tickLen = (tickOuterR - tickInnerR) * 0.35;
        paint = shortTick;
      }

      final angle = (deg - 90) * math.pi / 180;
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);

      // Ticks grow inward from the tickOuterR
      final p1 = Offset(
        center.dx + tickOuterR * cosA,
        center.dy + tickOuterR * sinA,
      );
      final p2 = Offset(
        center.dx + (tickOuterR - tickLen) * cosA,
        center.dy + (tickOuterR - tickLen) * sinA,
      );
      canvas.drawLine(p1, p2, paint);
    }

    // ---- Cardinal letters N, E, S, W (big, bold) ----
    _drawText(canvas, 'N', center, letterRadius, -90, accent, 13,
        FontWeight.w800);
    _drawText(canvas, 'E', center, letterRadius, 0, accent, 13,
        FontWeight.w800);
    _drawText(canvas, 'S', center, letterRadius, 90, accent, 13,
        FontWeight.w800);
    _drawText(canvas, 'W', center, letterRadius, 180, accent, 13,
        FontWeight.w800);

    // ---- Intercardinal letters (medium) ----
    _drawText(canvas, 'NE', center, letterRadius, -45,
        accent.withOpacity(0.9), 9, FontWeight.w600);
    _drawText(canvas, 'SE', center, letterRadius, 45,
        accent.withOpacity(0.9), 9, FontWeight.w600);
    _drawText(canvas, 'SW', center, letterRadius, 135,
        accent.withOpacity(0.9), 9, FontWeight.w600);
    _drawText(canvas, 'NW', center, letterRadius, 225,
        accent.withOpacity(0.9), 9, FontWeight.w600);

    // ---- Minor compass letters (small, faint) ----
    final minorLabels = {
      'NNE': -67.5,
      'ENE': -22.5,
      'ESE': 22.5,
      'SSE': 67.5,
      'SSW': 112.5,
      'WSW': 157.5,
      'WNW': 202.5,
      'NNW': 247.5,
    };
    minorLabels.forEach((label, deg) {
      _drawText(canvas, label, center, letterRadius, deg,
          accent.withOpacity(0.55), 6.5, FontWeight.w500);
    });

    // ---- Directional triangles at 8 primary directions ----
    // Small solid triangles pointing outward, sitting between the
    // letters and the tick inner ring.
    final primaryAngles = [-90.0, -45.0, 0.0, 45.0, 90.0, 135.0, 180.0, 225.0];
    for (final a in primaryAngles) {
      _drawDirectionTriangle(canvas, center, triangleRadius, a, accent);
    }
  }

  void _drawDirectionTriangle(
      Canvas canvas,
      Offset center,
      double radius,
      double angleDeg,
      Color color,
      ) {
    final angle = angleDeg * math.pi / 180;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    // Triangle apex points outward at 'radius'
    final apex = Offset(
      center.dx + radius * cosA,
      center.dy + radius * sinA,
    );
    // Base sits slightly inward
    final baseRadius = radius - 6;
    final baseCenter = Offset(
      center.dx + baseRadius * cosA,
      center.dy + baseRadius * sinA,
    );
    // Perpendicular vector for the base width
    final perpX = -sinA;
    final perpY = cosA;
    const halfWidth = 4.0;
    final baseLeft = Offset(
      baseCenter.dx - perpX * halfWidth,
      baseCenter.dy - perpY * halfWidth,
    );
    final baseRight = Offset(
      baseCenter.dx + perpX * halfWidth,
      baseCenter.dy + perpY * halfWidth,
    );

    final path = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawText(
      Canvas canvas,
      String text,
      Offset center,
      double radius,
      double angleDeg,
      Color color,
      double fontSize,
      FontWeight weight,
      ) {
    final angle = angleDeg * math.pi / 180;
    final pos = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

// ----------------------------------------------------------------
// RADAR — animated sweep + animated blips
// ----------------------------------------------------------------
class _RadarPainter extends CustomPainter {
  final double progress;
  final Color accent;

  static final List<_Blip> _blips = List.generate(4, (i) => _Blip.random(i));

  _RadarPainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Outer radar circle — slightly fainter than compass rings
    final outerRing = Paint()
      ..color = accent.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, outerRing);

    // Inner grid circles
    final gridRing = Paint()
      ..color = accent.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, radius * 0.66, gridRing);
    canvas.drawCircle(center, radius * 0.33, gridRing);

    // Crosshair lines (faint)
    final crosshair = Paint()
      ..color = accent.withOpacity(0.1)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      crosshair,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      crosshair,
    );

    // Sweep — thin wedge, ends just inside the outer ring
    final sweepAngle = progress * 2 * math.pi;
    final sweepRadius = radius - 6;
    const sweepArc = 0.35; // radians ~20°

    final wedgePath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: sweepRadius),
        sweepAngle - sweepArc - math.pi / 2,
        sweepArc,
        false,
      )
      ..close();

    final sweepGradient = SweepGradient(
      startAngle: sweepAngle - sweepArc - math.pi / 2,
      endAngle: sweepAngle - math.pi / 2,
      colors: [
        accent.withOpacity(0.0),
        accent.withOpacity(0.3),
      ],
      stops: const [0.0, 1.0],
    );

    canvas.drawPath(
      wedgePath,
      Paint()
        ..shader = sweepGradient.createShader(
          Rect.fromCircle(center: center, radius: sweepRadius),
        ),
    );

    // Bright leading edge
    final edgeAngle = sweepAngle - math.pi / 2;
    final edgeTip = Offset(
      center.dx + sweepRadius * math.cos(edgeAngle),
      center.dy + sweepRadius * math.sin(edgeAngle),
    );
    canvas.drawLine(
      center,
      edgeTip,
      Paint()
        ..color = accent
        ..strokeWidth = 1.6,
    );

    // Blips
    for (final blip in _blips) {
      blip.update(progress);
      final pos = Offset(
        center.dx + blip.rx * radius * 0.65,
        center.dy + blip.ry * radius * 0.65,
      );
      canvas.drawCircle(
          pos, 6, Paint()..color = accent.withOpacity(0.22 * blip.opacity));
      canvas.drawCircle(pos, 2.4,
          Paint()..color = accent.withOpacity(blip.opacity));
    }

    // Center dot
    canvas.drawCircle(center, 3, Paint()..color = accent);
    canvas.drawCircle(center, 7, Paint()..color = accent.withOpacity(0.3));
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accent != accent;
  }
}

// ----------------------------------------------------------------
// BLIP
// ----------------------------------------------------------------
class _Blip {
  double rx;
  double ry;
  double opacity = 0.0;
  double phase;
  final double speed;
  final int seed;

  _Blip._({
    required this.rx,
    required this.ry,
    required this.phase,
    required this.speed,
    required this.seed,
  });

  factory _Blip.random(int seed) {
    final rand = math.Random(
        seed * 1000 + DateTime.now().microsecondsSinceEpoch % 1000);
    return _Blip._(
      rx: rand.nextDouble() * 2 - 1,
      ry: rand.nextDouble() * 2 - 1,
      phase: rand.nextDouble(),
      speed: 0.3 + rand.nextDouble() * 0.4,
      seed: seed,
    );
  }

  void update(double globalProgress) {
    phase += 0.008 * speed;

    if (phase >= 1.0) {
      final rand =
      math.Random(DateTime.now().microsecondsSinceEpoch + seed);
      rx = rand.nextDouble() * 2 - 1;
      ry = rand.nextDouble() * 2 - 1;
      phase = 0.0;
    }

    if (phase < 0.5) {
      opacity = phase * 2;
    } else {
      opacity = (1.0 - phase) * 2;
    }
  }
}