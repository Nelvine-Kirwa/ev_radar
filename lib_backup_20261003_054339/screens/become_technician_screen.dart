import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class BecomeTechnicianScreen extends StatefulWidget {
  const BecomeTechnicianScreen({super.key});

  @override
  State<BecomeTechnicianScreen> createState() =>
      _BecomeTechnicianScreenState();
}

class _BecomeTechnicianScreenState extends State<BecomeTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _idNumber = TextEditingController();
  final _epra = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _idNumber.dispose();
    _epra.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.submitTechnician(
      fullName: _fullName.text.trim(),
      idNumber: _idNumber.text.trim(),
      epraLicense: _epra.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text('Application Submitted',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Your technician application is pending EPRA verification. '
            'We will review it within 24-48 hours.',
            style: TextStyle(color: Color(0xFF8892B0)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK',
                  style: TextStyle(color: Color(0xFF00C853))),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Submission failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        title: const Text('Become a Technician',
            style: TextStyle(color: Colors.white, fontSize: 16)),
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
                  'Register as an installation technician',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your EPRA license will be verified before you can accept jobs.',
                  style: TextStyle(color: Color(0xFF8892B0), fontSize: 12),
                ),
                const SizedBox(height: 24),
                _field(_fullName, 'Full Name', Icons.person_outline),
                const SizedBox(height: 14),
                _field(_idNumber, 'ID Number', Icons.badge_outlined),
                const SizedBox(height: 14),
                _field(_epra, 'EPRA License Number', Icons.verified_outlined),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text('Submit Application',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
          borderSide: const BorderSide(color: Color(0xFF00C853), width: 1.5),
        ),
      ),
    );
  }
}