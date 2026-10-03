import 'package:flutter/material.dart';
import '../data/equipment_data.dart';
import '../models/equipment.dart';
import 'package:provider/provider.dart';
import '../providers/installation_provider.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../providers/auth_provider.dart';
import 'equipment_detail_screen.dart';
import 'installation_history_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final provider = context.read<InstallationProvider>();
      final uid = auth.user?.uid;
      if (uid != null && uid.isNotEmpty && provider.active.isEmpty && provider.history.isEmpty) {
        provider.loadForUser(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(),
                const SizedBox(height: 16),
                _buildHardwareSection(),
                const SizedBox(height: 16),
                _buildInclusionsCard(),
                const SizedBox(height: 16),
                _buildInstallationSteps(),
                const SizedBox(height: 16),
                _buildYourInstallation(),
                const SizedBox(height: 16),
                _buildHistoryButton(),

              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: child,
    );
  }

  Widget _buildHero() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x1A00C853),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x6600C853)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_outlined,
                        color: Color(0xFF00C853), size: 12),
                    SizedBox(width: 5),
                    Text(
                      'Certified Installation Partner',
                      style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0x1A00C853),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt,
                    color: Color(0xFF00C853), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Free Site\nAssessment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Includes permit filing and safety inspection. Zero commitment guarantee.',
            style: TextStyle(
              color: Color(0xFF8892B0),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _heroFact('COST', 'KSh 0'),
                  const VerticalDivider(
                      color: Color(0xFF1F2937), width: 1),
                  _heroFact('DURATION', '45 MIN'),
                  const VerticalDivider(
                      color: Color(0xFF1F2937), width: 1),
                  _heroFact('APPROVAL', 'EPRA/KPLC'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFact(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8892B0),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildHardwareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Recommended Wallbox Hardware',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Text(
              '3 Options',
              style: TextStyle(
                color: Color(0xFF00C853),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 290,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kHardwareOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final eq = kHardwareOptions[i];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EquipmentDetailScreen(equipment: eq),
                    ),
                  );
                },
                child: _hardwareCardFromEquipment(eq),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _hardwareCardFromEquipment(Equipment eq) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 110,
              child: Image.asset(eq.imagePath, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eq.category,
                      style: const TextStyle(
                          color: Color(0xFF8892B0),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(eq.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...eq.features.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          children: [
                            const Icon(Icons.check,
                                color: Color(0xFF00C853), size: 12),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(f,
                                  style: const TextStyle(
                                      color: Color(0xFF8892B0),
                                      fontSize: 10)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 10),
                  Text(eq.priceLabel,
                      style: const TextStyle(
                          color: Color(0xFF8892B0),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  Text('KSh ${eq.priceKsh}',
                      style: const TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInclusionsCard() {
    const inclusions = [
      'County Government Permit & KPLC Grid Clearance Documentation',
      'Certified EPRA Class A/B Master Electrician Labor & Diagnostics',
      'Type 2 SPDs (Surge Protection Device) & Dedicated RCBO Breaker',
      'Up to 15m Heavy-Duty Armoured Cable Run (indoor/outdoor rated)',
      '1-Year Comprehensive Workmanship & Grid Compliance Warranty',
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Package Inclusions',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1A00C853),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('KSh 74,900 Base',
                    style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...inclusions.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_circle_outline,
                          color: Color(0xFF00C853), size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(t,
                          style: const TextStyle(
                              color: Color(0xFFB8C7DA),
                              fontSize: 12,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInstallationSteps() {
    const steps = [
      {
        'title': 'Equipment Selection',
        'subtitle': 'Choose your wallbox from recommended options'
      },
      {
        'title': 'Site Survey',
        'subtitle': 'Free assessment of your panel & location'
      },
      {
        'title': 'Certified Electrician',
        'subtitle': 'Select your preferred EPRA-licensed installer'
      },
      {
        'title': 'Installation & Handover',
        'subtitle': 'Testing, documentation, warranty activated'
      },
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('INSTALLATION STEPS',
              style: TextStyle(
                  color: Color(0xFF8892B0),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4)),
          const SizedBox(height: 4),
          const Text('How It Works',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isLast = i == steps.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0x1A00C853),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF00C853),
                              width: 1.2),
                        ),
                        alignment: Alignment.center,
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Color(0xFF00C853),
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step['title']!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(step['subtitle']!,
                              style: const TextStyle(
                                  color: Color(0xFF8892B0),
                                  fontSize: 11,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  Widget _buildYourInstallation() {
    final provider = context.watch<InstallationProvider>();
    final active = provider.active;

    if (active.isEmpty) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Your Installation',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'No active installation',
                style: TextStyle(
                    color: Color(0xFF8892B0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Book a hardware installation from the options above',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF4A5568), fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < active.length; i++) ...[
          _installationCard(active[i]),
          if (i < active.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _installationCard(Booking booking) {
    final isScheduled = booking.status == 'SCHEDULED';
    final isPending = booking.status == 'PENDING';
    final statusColor = isScheduled
        ? const Color(0xFF00C853)
        : (isPending
            ? const Color(0xFFFFA000)
            : const Color(0xFF4FA3E8));
    final statusBg = isScheduled
        ? const Color(0x1A00C853)
        : (isPending
            ? const Color(0x1AFFA000)
            : const Color(0x1A4FA3E8));
    final statusBorder = isScheduled
        ? const Color(0x6600C853)
        : (isPending
            ? const Color(0x66FFA000)
            : const Color(0x664FA3E8));

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Installation',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusBorder),
                ),
                child: Text(booking.status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Assigned Pro', booking.electricianName, showCheck: true),
          _infoRow('Equipment', booking.equipmentName),
          _infoRow('Category', booking.equipmentCategory),
          _infoRow('Site Location', booking.address),
          _infoRow('Booking Fee', 'KSh ${booking.bookingFeeKsh}'),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _confirmCancel(booking),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1AD32F2F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0x66D32F2F), width: 1),
                ),
                child: const Text(
                  'CANCEL BOOKING',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _notifyCancellation(Booking booking) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('electricians')
          .where('name', isEqualTo: booking.electricianName)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return;
      final recipientId = snap.docs.first.id;

      await NotificationService().createNotification(
        recipientId: recipientId,
        type: 'BOOKING_CANCELLED',
        title: 'Booking Cancelled',
        body:
            'A booking for ${booking.equipmentName} at ${booking.address} was cancelled. The booking fee will be refunded.',
        relatedBookingId: booking.id,
      );
    } catch (_) {
      // Silent â€” cancellation already succeeded
    }
  }
  Future<void> _confirmCancel(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text(
          'Do you want to cancel this booking?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: const Text(
          'Your installation will be cancelled. This cannot be undone. The booking fee will be refunded.',
          style: TextStyle(color: Color(0xFF8892B0), fontSize: 13),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF00C853), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Return',
                      style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFD32F2F), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Cancel Booking',
                      style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<InstallationProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    if (userId.isEmpty) return;

    // Show brief loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C853)),
      ),
    );

    final ok = await provider.cancelBooking(booking.id, userId);

    if (ok) {
      await _notifyCancellation(booking);
      // Notify client (self)
      await NotificationService().notifyBookingCancelled(
        userId: userId,
        equipmentName: booking.equipmentName,
        address: booking.address,
        bookingId: booking.id,
      );
    }

    if (!mounted) return;
    Navigator.pop(context); // close loading

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Booking cancelled'
            : 'Could not cancel. Please try again.'),
        backgroundColor:
            ok ? const Color(0xFF00C853) : const Color(0xFFD32F2F),
      ),
    );
  }
  Widget _buildHistoryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InstallationHistoryScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00C853)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, color: Color(0xFF00C853), size: 16),
                SizedBox(width: 8),
                Text(
                  'View Installation History',
                  style: TextStyle(
                    color: Color(0xFF00C853),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _infoRow(String label, String value, {bool showCheck = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF8892B0),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                if (showCheck)
                  const Icon(Icons.check_circle,
                      color: Color(0xFF00C853), size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
