import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_dropdown.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/glass_button.dart';
import '../widgets/glass/glass_list_item.dart';
import 'become_operator_screen.dart';
import 'become_technician_screen.dart';
import 'terms_dialog.dart';
import 'auth/login_screen.dart';

class ProfileSupportScreen extends StatelessWidget {
  const ProfileSupportScreen({super.key});

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $url')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.displayName;
    final email = auth.displayEmail;
    final phone = auth.displayPhone;
    final roleLabel = auth.roleLabel;
    final initials = _initials(name);

    return GlassScaffold(
      backgroundOverride: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GlassColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: GlassColors.cardFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GlassColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: GlassColors.online,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Profile & Support',
                      style: TextStyle(
                        color: GlassColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: GlassColors.textPrimary),
              onPressed: () {
                final box = ctx.findRenderObject() as RenderBox?;
                final pos =
                    box?.localToGlobal(Offset.zero) ?? Offset.zero;
                GlassDropdown.show(
                  context: ctx,
                  position:
                      Offset(pos.dx, pos.dy + (box?.size.height ?? 40)),
                  items: [
                    GlassMenuItem(
                      icon: Icons.storefront_outlined,
                      label: 'Become Operator',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BecomeOperatorScreen(),
                          ),
                        );
                      },
                    ),
                    GlassMenuItem(
                      icon: Icons.handyman_outlined,
                      label: 'Become Technician',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BecomeTechnicianScreen(),
                          ),
                        );
                      },
                    ),
                    GlassMenuItem(
                      icon: Icons.description_outlined,
                      label: 'Terms & Conditions',
                      onTap: () => TermsDialog.show(context),
                    ),
                    GlassMenuItem(
                      icon: Icons.logout,
                      label: 'Sign Out',
                      isDestructive: true,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        await context.read<AuthProvider>().signOut();
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Profile & Support',
              style: TextStyle(
                color: GlassColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your account and get assistance',
              style: TextStyle(
                color: GlassColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GlassColors.bgTop,
                      border: Border.all(
                        color: GlassColors.accentLight,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: GlassColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: GlassColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          roleLabel,
                          style: const TextStyle(
                            color: GlassColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'PERSONAL DETAILS',
                style: TextStyle(
                  color: GlassColors.textHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'FULL NAME',
                    value: name,
                  ),
                  _divider(),
                  _InfoRow(
                    icon: Icons.mail_outline,
                    label: 'EMAIL ADDRESS',
                    value: email,
                  ),
                  _divider(),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'PHONE NUMBER',
                    value: phone.isEmpty ? '--' : phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GlassButton(
              label: 'Update Profile',
              icon: Icons.edit_outlined,
              onPressed: () => _showEditDialog(context, name, phone),
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'SUPPORT CHANNELS',
                style: TextStyle(
                  color: GlassColors.textHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  GlassListItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'WhatsApp Support',
                    subtitle: 'Fast response - Dedicated EV agent',
                    onTap: () =>
                        _launch(context, SupportDetails.whatsappUrl),
                  ),
                  _divider(),
                  GlassListItem(
                    icon: Icons.call_outlined,
                    title: 'Call Us',
                    subtitle: 'Toll-free customer hotline',
                    onTap: () => _launch(context, SupportDetails.phoneUrl),
                  ),
                  _divider(),
                  GlassListItem(
                    icon: Icons.alternate_email,
                    title: 'Email',
                    subtitle: SupportDetails.email,
                    onTap: () => _launch(context, SupportDetails.emailUrl),
                  ),
                  _divider(),
                  GlassListItem(
                    icon: Icons.public,
                    title: 'Facebook',
                    subtitle: 'Community updates & announcements',
                    onTap: () =>
                        _launch(context, SupportDetails.facebookUrl),
                  ),
                  _divider(),
                  GlassListItem(
                    icon: Icons.tag,
                    title: 'Twitter / X',
                    subtitle: '@EVRadarKenya status & alerts',
                    onTap: () => _launch(context, SupportDetails.twitterUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'EV RADAR KENYA  -  ${SupportDetails.appVersion}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GlassColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Secure Telemetry Gateway - Nairobi, Kenya',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GlassColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, String currentName, String currentPhone) {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Update Profile',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _dialogInputDecoration('Full Name', Icons.person_outline),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: _dialogInputDecoration('Phone Number', Icons.phone_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8892B0))),
          ),
          TextButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final nav = Navigator.of(dialogCtx);
              final messenger = ScaffoldMessenger.of(context);
              final ok = await auth.updateProfile(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              nav.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? 'Profile updated'
                      : (auth.error ?? 'Update failed')),
                ),
              );
            },
            child: const Text('Save',
                style: TextStyle(color: Color(0xFF00C853))),
          ),
        ],
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF8892B0)),
      prefixIcon: Icon(icon, color: const Color(0xFF8892B0), size: 20),
      filled: true,
      fillColor: const Color(0xFF0A0E1A),
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
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return 'EV';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) +
            parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        color: GlassColors.cardBorder,
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: GlassColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: GlassColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: GlassColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: GlassColors.accent.withOpacity(0.4),
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: GlassColors.accentLight,
            ),
          ),
        ],
      ),
    );
  }
}