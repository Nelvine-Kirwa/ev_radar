import 'package:flutter/material.dart';
import '../data/equipment_data.dart';
import '../models/equipment.dart';
import 'equipment_detail_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  bool _hasInstallation = true;

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
                if (_hasInstallation) ...[
                  const SizedBox(height: 16),
                  _buildYourInstallation(),
                ],

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
                  color: const Color(0x1A00C853),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x6600C853)),
                ),
                child: const Text('COMPLETED',
                    style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Assigned Pro', 'David Mwangi', showCheck: true),
          _infoRow('License', 'EPRA/EM/2024/0472'),
          _infoRow('Scheduled Date',
              'Thursday, 24 Oct - 10:00 AM to 1:00 PM'),
          _infoRow('Site Location',
              'Kilimani, Nairobi - Residential'),
          _infoRow('Scope', 'Standard 11 kW 3-Phase - KPLC Isolator'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Request Follow-Up Visit - Available after installation completion',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF4A5568),
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
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
