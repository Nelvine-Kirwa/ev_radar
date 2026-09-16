import 'package:flutter/material.dart';
import 'radar_loader.dart';

class RadarOverlay extends StatelessWidget {
  final String statusText;

  const RadarOverlay({
    super.key,
    this.statusText = 'Scanning nearby stations...',
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xE60A0E1A),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'EV RADAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 40),
              RadarLoader(
                size: 220,
                statusText: statusText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}