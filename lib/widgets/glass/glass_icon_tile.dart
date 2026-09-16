import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class GlassIconTile extends StatelessWidget {
  final IconData icon;
  final double size;

  const GlassIconTile({
    super.key,
    required this.icon,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: GlassColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassColors.accent.withOpacity(0.4), width: 1),
      ),
      child: Icon(
        icon,
        color: GlassColors.accentLight,
        size: size * 0.5,
      ),
    );
  }
}