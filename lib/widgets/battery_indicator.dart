import 'package:flutter/material.dart';

class BatteryIndicator extends StatelessWidget {
  final double percent; // 0.0 - 1.0
  final Color color;
  final double width;
  final double height;

  const BatteryIndicator({
    super.key,
    required this.percent,
    required this.color,
    this.width = 92,
    this.height = 34,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0);
    final textColor = clamped > 0.55 ? Colors.black : Colors.white;
    final pctText = '${(clamped * 100).toStringAsFixed(0)}%';

    // Outer dimensions: nub on right, so body width = width - nubWidth
    const nubWidth = 5.0;
    const nubHeight = 12.0;
    final bodyWidth = width - nubWidth;

    return SizedBox(
      width: width,
      height: height,
      child: Row(
        children: [
          // Body
          SizedBox(
            width: bodyWidth,
            height: height,
            child: Stack(
              children: [
                // Background (dark track)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0xFF4A5568), width: 1.5),
                  ),
                ),
                // Colored fill — proportion of percent
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: clamped,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                // Percentage text centered
                Center(
                  child: Text(
                    pctText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Nub (positive terminal)
          Container(
            width: nubWidth,
            height: nubHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF4A5568),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}