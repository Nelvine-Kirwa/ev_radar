import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/equipment_data.dart';
import '../models/equipment.dart';
import '../providers/auth_provider.dart';
import '../services/booking_service.dart';
import 'booking_confirmation_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final Equipment equipment;
  const EquipmentDetailScreen({super.key, required this.equipment});

  @override
  State<EquipmentDetailScreen> createState() =>
      _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  final _addressController = TextEditingController(
    text: 'Kilimani, Nairobi',
  );
  int _selectedElectrician = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final e = Electricians.available[_selectedElectrician];
    final bookingId = await BookingService().createBooking(
      userId: user.uid,
      userEmail: user.email ?? '',
      equipment: widget.equipment,
      electricianName: e['name'],
      electricianRating: (e['rating'] as num).toDouble(),
      address: _addressController.text.trim(),
      bookingFeeKsh: 2500,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save booking. Please try again.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          bookingId: bookingId,
          equipment: widget.equipment,
          electricianName: e['name'],
          address: _addressController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configure Booking',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEquipmentCard(),
              const SizedBox(height: 16),
              _buildAddressCard(),
              const SizedBox(height: 16),
              _buildElectricianPicker(),
              const SizedBox(height: 16),
              _buildRefundNote(),
              const SizedBox(height: 20),
              _buildConfirmButton(),
              const SizedBox(height: 10),
              const Text(
                'By confirming, you agree to be contacted by an electrician within 24 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF8892B0), fontSize: 10, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: child,
    );
  }

  Widget _buildEquipmentCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              widget.equipment.imagePath,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          Text(widget.equipment.category,
              style: const TextStyle(
                  color: Color(0xFF8892B0),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(widget.equipment.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...widget.equipment.features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    const Icon(Icons.check,
                        color: Color(0xFF00C853), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f,
                          style: const TextStyle(
                              color: Color(0xFFB8C7DA), fontSize: 12)),
                    ),
                  ],
                ),
              )),
          const Divider(color: Color(0xFF1F2937), height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.equipment.priceLabel,
                  style: const TextStyle(
                      color: Color(0xFF8892B0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              Text('KSh ${widget.equipment.priceKsh}',
                  style: const TextStyle(
                      color: Color(0xFF00C853),
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('INSTALLATION ADDRESS',
              style: TextStyle(
                  color: Color(0xFF8892B0),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: TextField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Enter your address',
                hintStyle:
                    TextStyle(color: Color(0xFF4A5568), fontSize: 13),
                prefixIcon: Icon(Icons.place_outlined,
                    color: Color(0xFF00C853), size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectricianPicker() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CHOOSE ELECTRICIAN',
                  style: TextStyle(
                      color: Color(0xFF8892B0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4)),
              GestureDetector(
                onTap: () {
                  // Future: open full electrician list screen
                },
                child: const Row(
                  children: [
                    Text('See all',
                        style: TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    Icon(Icons.chevron_right,
                        color: Color(0xFF00C853), size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(Electricians.available.length, (i) {
            final e = Electricians.available[i];
            final selected = i == _selectedElectrician;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i == Electricians.available.length - 1 ? 0 : 8),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedElectrician = i),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0x1A00C853)
                        : const Color(0xFF0A0E1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF00C853)
                          : const Color(0xFF1F2937),
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: const Color(0xFF4A5568)),
                        ),
                        child: const Icon(Icons.person,
                            color: Color(0xFF8892B0), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['name'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              '${e['license']} - ${e['installations']} installations',
                              style: const TextStyle(
                                  color: Color(0xFF8892B0), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.star,
                          color: Color(0xFF00C853), size: 12),
                      const SizedBox(width: 3),
                      Text('${e['rating']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRefundNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1A00C853),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x6600C853)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: Color(0xFF00C853), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                    color: Color(0xFFB8C7DA),
                    fontSize: 11,
                    height: 1.5),
                children: [
                  TextSpan(text: 'Refundable '),
                  TextSpan(
                    text: 'KSh 2,500 booking fee',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        ' credited towards your final installation invoice upon completion of the free site assessment.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _confirmBooking,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.check_circle_outline, size: 18),
        label: Text(
          _isSubmitting ? 'Saving...' : 'Confirm Booking',
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C853),
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0x6600C853),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}