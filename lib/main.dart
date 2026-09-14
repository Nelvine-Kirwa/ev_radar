import 'package:flutter/material.dart';

void main() {
  runApp(const EVRadarApp());
}

class EVRadarApp extends StatelessWidget {
  const EVRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EV Radar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00C853)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        backgroundColor: Color(0xFF0A0E1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.electric_car, size: 100, color: Color(0xFF00C853)),
              SizedBox(height: 20),
              Text(
                'EV RADAR',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Smart EV Tracking & Charging',
                style: TextStyle(color: Color(0xFF8892B0), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
