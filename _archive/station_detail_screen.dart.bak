import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/charging_station.dart';
import '../providers/charging_provider.dart';

class StationDetailScreen extends StatefulWidget {
  final String stationId;
  const StationDetailScreen({super.key, required this.stationId});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWithRetry();
    });
  }

  Future<void> _loadWithRetry() async {
    final provider = context.read<ChargingProvider>();
    await provider.loadStationById(widget.stationId);

    // If the first attempt failed (transient error or rules propagation),
    // retry once after a short delay.
    if (mounted &&
        provider.currentStation == null &&
        provider.error != null) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        await provider.loadStationById(widget.stationId);
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _launchNavigate(ChargingStation s) async {
    final uri = Uri.parse(
        'geo:${s.lat},${s.lng}?q=${s.lat},${s.lng}(${Uri.encodeComponent(s.name)})');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChargingProvider>();
    final station = provider.currentStation;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
          : provider.error != null || station == null
              ? _buildError(provider.error ?? 'Station not found')
              : _buildContent(station),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _circleButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 48),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back',
                    style: TextStyle(color: Color(0xFF00C853))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ChargingStation s) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(s),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildActionRow(s),
                const SizedBox(height: 16),
                _buildQuickFacts(s),
                const SizedBox(height: 16),
                _buildPorts(s),
                const SizedBox(height: 16),
                _buildAmenities(s),
                const SizedBox(height: 16),
                _buildHoursContact(s),
                const SizedBox(height: 24),
                _buildActionBar(s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(ChargingStation s) {
    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF0A0E1A)),
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Image.asset(
              s.chargerImage,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x66000000),
                  Color(0xE60A0E1A),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        color: Color(0xFFB8C7DA), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s.address,
                        style: const TextStyle(
                          color: Color(0xFFB8C7DA),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(ChargingStation s) {
    return Row(
      children: [
        _statusPill(s.statusLabel, s.statusTier),
        const Spacer(),
        _circleButton(
          icon: _saved ? Icons.bookmark : Icons.bookmark_border,
          onTap: () => setState(() => _saved = !_saved),
        ),
        const SizedBox(width: 8),
        _circleButton(icon: Icons.share_outlined, onTap: () {}),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _statusPill(String label, String tier) {
    Color bg;
    Color fg;
    switch (tier) {
      case 'busy':
        bg = const Color(0x33FFA000);
        fg = const Color(0xFFFFA000);
        break;
      case 'offline':
        bg = const Color(0x338892B0);
        fg = const Color(0xFF8892B0);
        break;
      default:
        bg = const Color(0x3300C853);
        fg = const Color(0xFF00C853);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: child,
    );
  }

  Widget _buildQuickFacts(ChargingStation s) {
    return _card(
      child: IntrinsicHeight(
        child: Row(
          children: [
            _quickFact('DISTANCE', '- km'),
            const VerticalDivider(color: Color(0xFF1F2937), width: 1),
            _quickFact('PRICE', 'KSh ${s.pricePerKwhKsh}\n/ kWh',
                valueColor: const Color(0xFF00C853)),
            const VerticalDivider(color: Color(0xFF1F2937), width: 1),
            _quickFact('MAX POWER', '${s.powerKw.toStringAsFixed(0)} kW'),
          ],
        ),
      ),
    );
  }

  Widget _quickFact(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8892B0),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPorts(ChargingStation s) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Ports',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x3300C853),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x6600C853)),
                ),
                child: Text('${s.portsAvailable} of ${s.portsTotal}',
                    style: const TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(s.portsTotal, (i) {
            // Alternate statuses for a realistic look
            final isAvailable = i < s.portsAvailable;
            final isLast = i == s.portsTotal - 1;
            return Column(
              children: [
                _portRow(i + 1, s.connectorType, isAvailable),
                if (!isLast)
                  const Divider(color: Color(0xFF1F2937), height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _portRow(int number, String connectorType, bool available) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: const Icon(Icons.ev_station,
                size: 16, color: Color(0xFF00C853)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Port $number - $connectorType',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  available ? 'AC Fast - 22 kW' : 'In Use',
                  style: const TextStyle(
                      color: Color(0xFF8892B0), fontSize: 11),
                ),
              ],
            ),
          ),
          _portStatusBadge(available ? 'Free' : 'In Use', available),
        ],
      ),
    );
  }

  Widget _portStatusBadge(String label, bool free) {
    final color = free ? const Color(0xFF00C853) : const Color(0xFFFFA000);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildAmenities(ChargingStation s) {
    final amenityIcons = {
      'Restroom': Icons.wc,
      'Cafe': Icons.local_cafe_outlined,
      'WiFi': Icons.wifi,
      'Parking': Icons.local_parking,
      '24/7 Access': Icons.access_time,
      'Security': Icons.shield_outlined,
    };

    final displayAmenities = s.amenities.isEmpty
        ? ['Parking', '24/7 Access', 'Security']
        : s.amenities;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Amenities',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: displayAmenities.map((a) {
              final icon = amenityIcons[a] ?? Icons.check_circle_outline;
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1F2937)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22, color: const Color(0xFF00C853)),
                    const SizedBox(height: 6),
                    Text(a,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFFB8C7DA), fontSize: 11)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursContact(ChargingStation s) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.business_outlined,
                  color: Color(0xFF00C853), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.operator,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Divider(color: Color(0xFF1F2937), height: 24),
          Row(
            children: [
              const Icon(Icons.call_outlined,
                  color: Color(0xFF00C853), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.phone,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              GestureDetector(
                onTap: () => _launchPhone(s.phone),
                child: const Text('Call',
                    style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ChargingStation s) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _launchNavigate(s),
              icon: const Icon(Icons.navigation_outlined, size: 18),
              label: const Text('Navigate Here',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27)),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _saved = !_saved),
              icon: Icon(
                  _saved ? Icons.bookmark : Icons.bookmark_border,
                  size: 18),
              label: Text(_saved ? 'Saved' : 'Save',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF1F2937)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}