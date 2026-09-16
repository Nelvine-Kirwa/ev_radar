import 'package:flutter/material.dart';
import '../widgets/radar_loader.dart';

class RadarPreviewScreen extends StatelessWidget {
  const RadarPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Radar Preview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;

              // Compass takes 82% of available width — leaves ~28px
              // margin on each side of a ~360px phone. Radar is
              // compass / 1.3636.
              final compassWidth = availableWidth * 0.82;
              final radarSize = compassWidth / 1.3636;

              return Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'E V   R A D A R',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 5,
                    ),
                  ),
              const Spacer(),
              Center(
              child: RadarLoader(
              size: radarSize,
              statusText: 'SCANNING NEARBY STATIONS...',
              ),
              ),
              const Spacer(),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}