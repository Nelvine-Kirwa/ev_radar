import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00C853);
  static const Color primaryDark = Color(0xFF009624);
  static const Color secondary = Color(0xFF1A1A2E);
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color warning = Color(0xFFFFA000);
  static const Color danger = Color(0xFFD32F2F);
  static const Color success = Color(0xFF00C853);
}

class AppStrings {
  static const String appName = 'EV Radar';
  static const String tagline = 'Smart EV Tracking & Charging';
}

class VehicleDefaults {
  static const double batteryCapacityKwh = 64.0;
  static const double consumptionKwhPer100km = 17.0;
  static const double maxRangeKm = 376.0;
}

const double criticalBatteryThreshold = 0.15;
const double lowBatteryThreshold = 0.25;
