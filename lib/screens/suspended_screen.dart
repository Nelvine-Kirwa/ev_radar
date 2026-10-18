import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth/login_screen.dart';
import '../providers/notification_provider.dart';
import '../providers/saved_stations_provider.dart';
import '../providers/installation_provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

/// Full-screen wall shown to suspended users.
/// They can tap "Request Review" to notify the admin with their details.
class SuspendedScreen extends StatefulWidget {
  const SuspendedScreen({super.key});

  @override
  State<SuspendedScreen> createState() => _SuspendedScreenState();
}

class _SuspendedScreenState extends State<SuspendedScreen> {
  bool _sending = false;
  bool _sent = false;

  Future<void> _requestReview() async {
    if (_sending || _sent) return;
    setState(() => _sending = true);
    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.user?.uid ?? '';
      if (uid.isEmpty) return;

      // Load the user's current profile for full details.
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final ud = userDoc.data() ?? {};
      final role = (ud['role'] ?? '').toString();
      final name = (ud['name'] ?? 'Unknown').toString();
      final email = (ud['email'] ?? '').toString();
      final phone = (ud['phone'] ?? '').toString();
      final idNumber = (ud['idNumber'] ?? '').toString();
      final epra = (ud['epraLicense'] ?? '').toString();
      final permit = (ud['businessPermitNumber'] ?? '').toString();

      // Fetch admin uid.
      final adminSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      if (adminSnap.docs.isEmpty) {
        if (!mounted) return;
        setState(() => _sending = false);
        _snack('Could not reach admin');
        return;
      }
      final adminUid = adminSnap.docs.first.id;

      // Build review details.
      final details = <String>[
        'Name: ' + name,
        'Email: ' + email,
        'Phone: ' + phone,
        'Role: ' + role,
        if (idNumber.isNotEmpty) 'ID Number: ' + idNumber,
        if (role == 'operator' && permit.isNotEmpty) 'Business Permit: ' + permit,
        if (role == 'technician' && epra.isNotEmpty) 'EPRA License: ' + epra,
      ].join('\n');

      await NotificationService().createNotification(
        recipientId: adminUid,
        type: 'SUSPENSION_REVIEW_REQUEST',
        title: 'Suspension Review Request',
        body: name + ' (' + role + ') requested a review.\n\n' + details,
      );

      if (!mounted) return;
      setState(() {
        _sent = true;
        _sending = false;
      });
      _snack('Request sent to admin. They will contact you.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _snack('Failed: ' + e.toString());
    }
  }

  void _snack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, color: Color(0xFFD32F2F), size: 72),
                const SizedBox(height: 20),
                const Text(
                  'Account Suspended',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your account has been suspended and access to the app is restricted. Tap the button below to request a review.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF8892B0), fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _sent || _sending ? null : _requestReview,
                    icon: Icon(
                      _sent ? Icons.check_circle : Icons.send,
                      color: Colors.black,
                      size: 18,
                    ),
                    label: Text(
                      _sent
                          ? 'Review Request Sent'
                          : _sending
                              ? 'Sending...'
                              : 'Request Review',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        context.read<NotificationProvider>().stopListening();
                        context.read<SavedStationsProvider>().clear();
                        context.read<InstallationProvider>().clear();
                        await context.read<AuthProvider>().signOut();
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.login,
                          color: Color(0xFF00C853), size: 18),
                      label: const Text(
                        'Log In with Another Account',
                        style: TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 13,
                            fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x6600C853)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(23),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            ),
            ),

            // Top-left exit button
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 24),
                onPressed: () async {
                  await SystemNavigator.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}