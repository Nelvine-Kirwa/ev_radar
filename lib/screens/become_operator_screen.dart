import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Simple operator-application form.
///
/// Writes to `operator_applications` with `status: 'pending'` and notifies
/// every admin (users with role == 'admin') that a new application is in.
///
/// After an admin approves, the applicant's `users/{uid}.role` becomes
/// 'operator' and they gain access to the Operator Dashboard from the
/// gear menu on Profile.
class BecomeOperatorScreen extends StatefulWidget {
  const BecomeOperatorScreen({super.key});

  @override
  State<BecomeOperatorScreen> createState() => _BecomeOperatorScreenState();
}

class _BecomeOperatorScreenState extends State<BecomeOperatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _idNumber = TextEditingController();
  final _permitNumber = TextEditingController();
  final _phone = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _fullName.dispose();
    _idNumber.dispose();
    _permitNumber.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text(
          'Confirm Submission',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Do you want to submit your operator application?',
          style: TextStyle(color: Color(0xFFB8C7DA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8892B0)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes',
              style: TextStyle(color: Color(0xFF00C853)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in required')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final appRef =
          await FirebaseFirestore.instance.collection('operator_applications').add({
        'uid': user.uid,
        'email': user.email ?? '',
        'fullName': _fullName.text.trim(),
        'idNumber': _idNumber.text.trim(),
        'businessPermitNumber': _permitNumber.text.trim(),
        'phone': _phone.text.trim(),
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Notify every admin. Best-effort, non-fatal.
      try {
        final admins = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();
        for (final admin in admins.docs) {
          final adminUid = admin.id;
          if (adminUid == user.uid) continue; // don't notify self
          await NotificationService().createNotification(
            recipientId: adminUid,
            type: 'NEW_OPERATOR_APPLICATION',
            title: 'New Operator Application',
            body: _fullName.text.trim() +
                ' applied to become an operator. Open the Admin Dashboard to review.',
          );
        }
      } catch (_) {
        // Silent — the application itself succeeded.
      }

      // Confirm to the applicant: their application was received.
      try {
        await NotificationService().createNotification(
          recipientId: user.uid,
          type: 'OPERATOR_APPLICATION_SUBMITTED',
          title: 'Application Received',
          body:
              'Your operator application has been submitted. An admin will review it shortly.',
        );
      } catch (_) {
        // Silent — the application itself succeeded.
      }

      // Confirm to the applicant: their application was received.
      try {
        await NotificationService().createNotification(
          recipientId: user.uid,
          type: 'OPERATOR_APPLICATION_SUBMITTED',
          title: 'Application Received',
          body:
              'Your operator application has been submitted. An admin will review it shortly.',
        );
      } catch (_) {
        // Silent — the application itself succeeded.
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text(
            'Application Submitted',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Your application is received, we will review it within 24-72 hours. '
            'You will be notified once it''s reviewed.',
            style: TextStyle(color: Color(0xFF8892B0)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to Profile
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF00C853)),
              ),
            ),
          ],
        ),
      );

      // Use appRef so it's not flagged unused.
      debugPrint('Operator application id: ${appRef.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        title: const Text(
          'Become an Operator',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Register as a station operator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your details will be verified by an admin before you can '
                  'register charging stations.',
                  style: TextStyle(color: Color(0xFF8892B0), fontSize: 12),
                ),
                const SizedBox(height: 24),

                _field(_fullName, 'Full Name', Icons.person),
                const SizedBox(height: 14),
                _field(_idNumber, 'ID Number', Icons.badge_outlined),
                const SizedBox(height: 14),
                _field(_permitNumber, 'Business Permit Number',
                    Icons.assignment_outlined),
                const SizedBox(height: 14),
                _field(_phone, 'Phone Number', Icons.phone,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 28),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Submit Application',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8892B0)),
        prefixIcon: Icon(icon, color: const Color(0xFF8892B0), size: 20),
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2937)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF00C853), width: 1.5),
        ),
      ),
    );
  }
}