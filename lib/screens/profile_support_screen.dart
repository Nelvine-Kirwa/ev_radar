import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/glass_button.dart';
import '../widgets/glass/glass_list_item.dart';

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
    return GlassScaffold(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: GlassColors.cardFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GlassColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: GlassColors.online,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'EV RADAR KENYA',
                    style: TextStyle(
                      color: GlassColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                color: GlassColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: GlassColors.textPrimary),
            onPressed: () {},
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
              'Manage your driver identity and get assistance',
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
                    child: const Text(
                      'NK',
                      style: TextStyle(
                        color: GlassColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nelvin Kipchirchir',
                          style: TextStyle(
                            color: GlassColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Nairobi Metro  -  EV Fleet Member',
                          style: TextStyle(
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
                    value: 'Nelvin Kipchirchir',
                  ),
                  _divider(),
                  _InfoRow(
                    icon: Icons.mail_outline,
                    label: 'EMAIL ADDRESS',
                    value: SupportDetails.email,
                  ),
                  _divider(),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'PHONE NUMBER',
                    value: SupportDetails.phoneNumber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GlassButton(
              label: 'Update Profile',
              icon: Icons.edit_outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile editing coming soon')),
                );
              },
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