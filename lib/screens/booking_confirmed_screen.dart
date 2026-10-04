import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../models/station_booking.dart';
import '../providers/vehicle_provider.dart';

/// Reuses the same visual style as the installation booking confirmation,
/// but for a charging slot. Shows station, vehicle, plate, time, date.
class BookingConfirmedScreen extends StatelessWidget {
  final StationBooking booking;
  final String stationAddress;
  final String userEmail;
  final String userPhone;

  const BookingConfirmedScreen({
    super.key,
    required this.booking,
    required this.stationAddress,
    required this.userEmail,
    required this.userPhone,
  });

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleProvider>();
    final Car? car = vehicle.currentCar;
    final userVehicle = vehicle.currentUserVehicle;

    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final timeFmt = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // â”€â”€ Success icon â”€â”€
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Color(0x3300C853),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Color(0xFF00C853),
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Confirmed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your charging slot is reserved',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8892B0),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // â”€â”€ Details card â”€â”€
              _card(
                child: Column(
                  children: [
                    _row('Station', booking.stationName),
                    const SizedBox(height: 12),
                    _row('Address', stationAddress),
                    const SizedBox(height: 12),
                    _row('Vehicle',
                        car?.displayName ?? '--'),
                    const SizedBox(height: 12),
                    _row('Plate',
                        userVehicle?.plate ?? '--'),
                    const SizedBox(height: 12),
                    _row('Date',
                        dateFmt.format(booking.startTime)),
                    const SizedBox(height: 12),
                    _row('Time',
                        '${timeFmt.format(booking.startTime)} - ${timeFmt.format(booking.endTime)}'),
                    const SizedBox(height: 12),
                    _rowValue(
                      'Status',
                      booking.status,
                      const Color(0xFF00C853),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // â”€â”€ Contact card â”€â”€
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR CONTACT',
                      style: TextStyle(
                        color: Color(0xFFB8C7DA),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _row('Email',
                        userEmail.isEmpty ? '--' : userEmail),
                    const SizedBox(height: 8),
                    _row('Phone',
                        userPhone.isEmpty ? '--' : userPhone),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // â”€â”€ Done â”€â”€
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop back to the station detail screen.
                    Navigator.of(context).popUntil((r) => r.isFirst);
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: child,
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8892B0),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _rowValue(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8892B0),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
