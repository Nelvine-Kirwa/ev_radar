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


// ============================================================
// Glass theme palette (used on Profile, Support, History, etc.)
// ============================================================
class GlassColors {
  // Background gradient (dark navy -> teal -> deep blue)
  static const Color bgTop     = Color(0xFF07111F);  // deep navy
  static const Color bgMid     = Color(0xFF0E2A33);  // teal-navy
  static const Color bgBottom  = Color(0xFF16344F);  // deep blue

  // Card (frosted dark)
  static const Color cardFill   = Color(0x99131F2E);  // ~60% dark navy
  static const Color cardBorder = Color(0x26FFFFFF);  // 15% white

  // Text
  static const Color textPrimary   = Color(0xFFE6EEF7);  // near-white
  static const Color textSecondary = Color(0xFF8892B0);  // muted blue-gray
  static const Color textHeading   = Color(0xFFB8C7DA);  // section headers (higher contrast)

  // Accent
  static const Color accent        = Color(0xFF1E88E5);  // primary blue
  static const Color accentLight   = Color(0xFF4FA3E8);
  static const Color accentSoft    = Color(0x331E88E5);  // glow

  // Status
  static const Color online = Color(0xFF00C853);
}

// ============================================================
// Support contact details (hardcoded for Project A)
// ============================================================
class SupportDetails {
  static const String whatsappNumber = '+254725421941';
  static const String whatsappUrl    = 'https://wa.me/254725421941';
  static const String phoneNumber    = '+254725421941';
  static const String phoneUrl       = 'tel:+254725421941';
  static const String email          = 'i.am.nelvine@gmail.com';
  static const String emailUrl       = 'mailto:i.am.nelvine@gmail.com';
  static const String facebookUrl    = 'https://www.facebook.com/nelvine.kirwa';
  static const String twitterUrl     = 'https://x.com/Nelvine_Kirwa';
  static const String appVersion     = 'BUILD 2.4.0 (EPRA COMPLIANT)';
  static const String tagline        = 'Secure Telemetry Gateway • Nairobi, Kenya';
}