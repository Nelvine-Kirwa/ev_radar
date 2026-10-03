import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/installation_provider.dart';
import '../providers/notification_provider.dart';
import '../models/user_vehicle.dart';
import 'app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNext();
  }

  Future<void> _decideNext() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null && mounted) {
      final auth = context.read<AuthProvider>();
      final vp = context.read<VehicleProvider>();
      try {
        // Parallel load: catalog + user vehicles + index + bookings
        final results = await Future.wait([
          vp.loadAvailableCars(),
          auth.loadVehicles(),
          auth.loadCurrentVehicleIndex(),
        ]);
        final vehicles = results[1] as List<UserVehicle>;
        final idx = results[2] as int;
        if (vehicles.isNotEmpty) {
          vp.setUserVehicles(vehicles, index: idx);
        }
      } catch (_) {
        // Silent — user can still use the app
      }

      try {
        if (user.uid.isNotEmpty) {
          await context.read<InstallationProvider>().loadForUser(user.uid);
          context.read<NotificationProvider>().listenForUser(user.uid);
        }
      } catch (_) {}
    }

    if (!mounted) return;

    final destination = user != null
        ? const AppShell()
        : const LoginScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0E1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.electric_car, size: 100, color: AppColors.primary),
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
            SizedBox(height: 40),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}