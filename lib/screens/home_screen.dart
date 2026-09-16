import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/constants.dart';
import 'profile_support_screen.dart';
import 'station_detail_screen.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Temporary test station ID — for development
  static const String _testStationId = 'B3Tuxc8ZD50Mxd5GNoSb';

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        title: const Text(
          'EV RADAR',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            tooltip: 'Profile & Support',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileSupportScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1F2937)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.electric_car,
                        size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      '${(vehicle.batteryLevel * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Range: ${vehicle.rangeKm.toStringAsFixed(0)} km',
                      style: const TextStyle(
                        color: Color(0xFF8892B0),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to EV Radar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Map, charging stations, and trip planning coming soon.',
                style: TextStyle(color: Color(0xFF8892B0), fontSize: 13),
              ),
              const SizedBox(height: 24),
              // TEST TILE — remove before final submission
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF00C853).withOpacity(0.4)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.science_outlined,
                      color: Color(0xFF00C853)),
                  title: const Text(
                    'TEST: Open Station Detail',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Loads the seeded station from Firestore',
                    style: TextStyle(
                        color: Color(0xFF8892B0), fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Color(0xFF8892B0), size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StationDetailScreen(
                          stationId: _testStationId,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  final navigator = Navigator.of(context);
                  await auth.signOut();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}