import 'package:flutter/material.dart';
import '../models/equipment.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String bookingId;
  final Equipment equipment;
  final String electricianName;
  final String address;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.equipment,
    required this.electricianName,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0x1A00C853),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Color(0xFF00C853), size: 50),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Confirmed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your installation has been scheduled',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8892B0),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1F2937)),
                ),
                child: Column(
                  children: [
                    _row('Equipment', equipment.name),
                    const SizedBox(height: 12),
                    _row('Electrician', electricianName),
                    const SizedBox(height: 12),
                    _row('Address', address),
                    const SizedBox(height: 12),
                    _row('Status', 'SCHEDULED',
                        valueColor: const Color(0xFF00C853)),
                    const SizedBox(height: 12),
                    _row('Booking Fee',
                        'KSh 2,500 (refundable)',
                        valueColor: const Color(0xFF00C853)),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFF8892B0), fontSize: 11)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}