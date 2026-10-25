import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/charging_station.dart';
import '../models/station_booking.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/notification_service.dart';
import '../services/station_booking_service.dart';
import '../screens/booking_confirmed_screen.dart';

class BookingSheet extends StatefulWidget {
  final ChargingStation station;
  const BookingSheet({super.key, required this.station});

  static Future<void> show(BuildContext context, ChargingStation station) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingSheet(station: station),
    );
  }

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  DateTime _selectedDay = DateTime.now();
  int? _selectedHour;
  bool _isSubmitting = false;

  List<DateTime> _days() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) => today.add(Duration(days: i)));
  }

  bool _isPast(int hour) {
    final now = DateTime.now();
    final slotStart = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, hour);
    return slotStart.isBefore(now);
  }

  String _slotLabel(int hour) {
    final start = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, hour);
    final end = start.add(const Duration(hours: 1));
    final fmt = DateFormat('h:mm a');
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }

  Future<void> _confirm() async {
    final hour = _selectedHour;
    if (hour == null) return;

    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    final email = auth.user?.email ?? '';
    if (uid == null || uid.isEmpty) return;

    setState(() => _isSubmitting = true);

    final start = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, hour);
    final end = start.add(const Duration(hours: 1));

    final service = StationBookingService();
    final id = await service.createBookingTransaction(
      stationId: widget.station.id,
      stationName: widget.station.name,
      userId: uid,
      userEmail: email,
      start: start,
      end: end,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (id == 'FULL') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That slot was just fully booked. Pick another.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not book that slot. Please try again.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // 1. Send notification to the USER
    try {
      await NotificationService().createNotification(
        recipientId: uid,
        type: 'BOOKING_CONFIRMED',
        title: 'Booking Confirmed',
        body: 'Your charging slot at  is booked for .',
        relatedBookingId: id,
      );
    } catch (e) {
      debugPrint('User notification failed: ');
    }

    // 2. Send notification to the OPERATOR
    try {
      final stationDoc = await FirebaseFirestore.instance.collection('stations').doc(widget.station.id).get();
      final operatorId = stationDoc.data()?['operatorId'] as String?;

      if (operatorId != null && operatorId.isNotEmpty && operatorId != uid) {
        // Get vehicle info for the operator's notification
        String carLine = '';
        try {
          final vp = context.read<VehicleProvider>();
          final car = vp.currentCar;
          final plate = vp.currentUserVehicle?.plate;
          if (car != null) {
            carLine = car.displayName;
            if (plate != null && plate.isNotEmpty) {
              carLine = carLine + ' (' + plate + ')';
            }
          }
        } catch (_) {}

        final contact = email.isEmpty ? '' : '  Contact: ' + email;
        final bodyText = carLine.isEmpty
            ? 'A customer booked  at .' + contact
            : carLine + ' booked  at .' + contact;

        await NotificationService().createNotification(
          recipientId: operatorId,
          type: 'NEW_CHARGING_BOOKING',
          title: 'New Charging Booking',
          body: bodyText,
        );
      }
    } catch (e) {
      debugPrint('Operator notification failed: ');
    }

    final confirmed = StationBooking(
      id: id,
      stationId: widget.station.id,
      stationName: widget.station.name,
      userId: uid,
      userEmail: email,
      startTime: start,
      endTime: end,
      status: 'CONFIRMED',
      createdAt: DateTime.now(),
    );

    final rootNav = Navigator.of(context, rootNavigator: true);
    Navigator.pop(context);
    rootNav.push(MaterialPageRoute(
      builder: (_) => BookingConfirmedScreen(
        booking: confirmed,
        stationAddress: widget.station.address,
        userEmail: email,
        userPhone: auth.displayPhone,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dayStart = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final dayStr = '${dayStart.year}-${dayStart.month.toString().padLeft(2, '0')}-${dayStart.day.toString().padLeft(2, '0')}';
    final totalPorts = widget.station.portsTotal > 0 ? widget.station.portsTotal : 2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFF4A5568), borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Book a charging slot', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(widget.station.name, style: const TextStyle(color: Color(0xFF8892B0), fontSize: 13)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _days().length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final d = _days()[i];
                      final selected = d.year == _selectedDay.year && d.month == _selectedDay.month && d.day == _selectedDay.day;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDay = d;
                            _selectedHour = null;
                          });
                        },
                        child: Container(
                          width: 64,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF00C853) : const Color(0xFF0A0E1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selected ? const Color(0xFF00C853) : const Color(0xFF1F2937)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(DateFormat('EEE').format(d), style: TextStyle(color: selected ? Colors.black : const Color(0xFF8892B0), fontSize: 11, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(DateFormat('d').format(d), style: TextStyle(color: selected ? Colors.black : Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFF1F2937), height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('station_slots')
                        .where('stationId', isEqualTo: widget.station.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)));
                      }

                      final Map<int, int> slotCounts = {};
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final key = data['slotKey'] as String?;
                          if (key != null && key.startsWith(dayStr)) {
                            final hour = int.tryParse(key.split('_').last) ?? 0;
                            slotCounts[hour] = (data['count'] as num?)?.toInt() ?? 0;
                          }
                        }
                      }

                      return ListView.separated(
                        key: const PageStorageKey('booking_slots_list'),
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: 24,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final bookedCount = slotCounts[i] ?? 0;
                          final fullyBooked = bookedCount >= totalPorts;
                          final past = _isPast(i);
                          final selected = _selectedHour == i;
                          final disabled = fullyBooked || past;

                          Color bg;
                          Color fg;
                          String trailing;
                          
                          if (past) {
                            bg = const Color(0x228892B0);
                            fg = const Color(0xFF8892B0);
                            trailing = 'Past';
                          } else if (fullyBooked) {
                            bg = const Color(0x33D32F2F);
                            fg = const Color(0xFFD32F2F);
                            trailing = 'Fully Booked ($bookedCount/$totalPorts)';
                          } else if (selected) {
                            bg = const Color(0xFF00C853);
                            fg = Colors.black;
                            trailing = 'Selected';
                          } else {
                            bg = const Color(0xFF0A0E1A);
                            fg = Colors.white;
                            trailing = 'Free ($bookedCount/$totalPorts)';
                          }

                          return GestureDetector(
                            onTap: disabled ? null : () { setState(() => _selectedHour = selected ? null : i); },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: selected ? const Color(0xFF00C853) : const Color(0xFF1F2937), width: selected ? 2 : 1),
                              ),
                              child: Row(
                                children: [
                                  Text(_slotLabel(i), style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  Text(trailing, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF1F2937)))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedHour == null ? 'Select a time slot' : _slotLabel(_selectedHour!),
                            style: TextStyle(color: _selectedHour == null ? const Color(0xFF8892B0) : Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: (_selectedHour == null || _isSubmitting) ? null : _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: const Color(0xFF1F2937),
                            disabledForegroundColor: const Color(0xFF8892B0),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: _isSubmitting 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text('Confirm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}