import 'package:flutter/material.dart';

class TermsDialog extends StatelessWidget {
  const TermsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const TermsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111827),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        color: Color(0xFF8892B0), size: 20),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1F2937), height: 1),
            const Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Text(
                  _termsText,
                  style: TextStyle(
                    color: Color(0xFFB8C7DA),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFF1F2937), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Close',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String _termsText = '''
EV RADAR — TERMS & CONDITIONS (Development Preview)

This application is currently under active development. The terms below describe the intended final experience. Some features listed here are not yet available.

FEATURES CURRENTLY AVAILABLE
- User registration and sign-in
- Discovery of EV charging stations across Nairobi
- Charging station details with price, power, and ports
- Profile management and support contact

FEATURES STILL IN DEVELOPMENT
- Google Maps integration for live station view
- GPS-based distance calculation and range tracking
- Trip planning with battery projection
- Charging station installation booking
- Technician and operator dashboards
- Push notifications for low battery and bookings
- Photo uploads for station operators
- Admin verification workflows
- Booking history and analytics

OPERATOR AND TECHNICIAN ROLES
Operators can register their charging stations once verified. Technicians can register to receive installation jobs once their EPRA license is verified. Both flows are currently accepting applications for the upcoming release.

DATA AND PRIVACY
Your account data (name, email, phone number) is stored securely. We do not share your information with third parties. Coordinates submitted by operators are used only to display their station location to other users.

SUPPORT
For questions, please use the support channels listed in the Profile & Support section.

This document will be replaced with the complete legal terms upon official release.

Last updated: Development Preview
''';