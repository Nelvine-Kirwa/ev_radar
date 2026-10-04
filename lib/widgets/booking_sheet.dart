import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/charging_station.dart';
import '../models/station_booking.dart';
import '../providers/auth_provider.dart';
import '../providers/station_booking_provider.dart';
import '../screens/booking_confirmed_screen.dart';

/// A modal bottom sheet for picking a 1-hour charging slot at [station].
/// Slot grid shows 24 hourly rows (00:00 -> 23:00) for the selected day.
///
/// This step (C2a) renders the UI and slot selection highlight only.
/// Booking creation happens in C2b.
class BookingSheet extends StatefulWidget {
  final ChargingStation station;
  const BookingSheet({super.key, required this.station});

  /// Show the sheet. Call from Station Detail's Book button.
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
  int? _selectedHour; // 0..23

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    await context
        .read<StationBookingProvider>()
        .loadForStationOnDay(widget.station.id, _selectedDay);
  }

  /// Confirms the currently selected slot: creates a booking in Firestore,
  /// then pushes the confirmation screen.
  Future<void> _confirm() async {
    final hour = _selectedHour;
    if (hour == null) return;

    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    final email = auth.user?.email ?? '';
    if (uid == null || uid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to book a slot.')),
      );
      return;
    }

    final start = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day, hour);
    final end = start.add(const Duration(hours: 1));

    final provider = context.read<StationBookingProvider>();
    final id = await provider.bookSlot(
      stationId: widget.station.id,
      stationName: widget.station.name,
      userId: uid,
      userEmail: email,
      start: start,
      end: end,
    );

    if (!mounted) return;

    if (id == null) {
      final err = provider.error ?? 'Could not book that slot. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
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
    final emailForCard = email;
    final phoneForCard = auth.displayPhone;
    final address = widget.station.address;

    Navigator.pop(context);

    rootNav.push(
      MaterialPageRoute(
        builder: (_) => BookingConfirmedScreen(
          booking: confirmed,
          stationAddress: address,
          userEmail: emailForCard,
          userPhone: phoneForCard,
        ),
      ),
    );
  }

  List<DateTime> _days() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) => today.add(Duration(days: i)));
  }

  bool _isPast(int hour) {
    final now = DateTime.now();
    final slotStart = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day, hour);
    return slotStart.isBefore(now);
  }

  bool _isTaken(int hour) {
    final start = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day, hour);
    final end = start.add(const Duration(hours: 1));
    return context
        .read<StationBookingProvider>()
        .isSlotTaken(start, end);
  }

  bool _isMyBooking(int hour) {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return false;
    final start = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day, hour);
    final end = start.add(const Duration(hours: 1));
    return context
        .read<StationBookingProvider>()
        .dayBookings
        .any((b) =>
            b.userId == uid &&
            b.startTime.isBefore(end) &&
            b.endTime.isAfter(start));
  }

  String _slotLabel(int hour) {
    final start = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day, hour);
    final end = start.add(const Duration(hours: 1));
    final fmt = DateFormat('h:mm a');
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<StationBookingProvider>();
    final loading = bookings.loading;

    return DraggableScrollableSheet(
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
              // â”€â”€ Handle â”€â”€
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A5568),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // â”€â”€ Header â”€â”€
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Book a charging slot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.station.name,
                      style: const TextStyle(
                        color: Color(0xFF8892B0),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // â”€â”€ Date strip â”€â”€
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _days().length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final d = _days()[i];
                    final selected = d.year == _selectedDay.year &&
                        d.month == _selectedDay.month &&
                        d.day == _selectedDay.day;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = d;
                          _selectedHour = null;
                        });
                        _load();
                      },
                      child: Container(
                        width: 64,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF00C853)
                              : const Color(0xFF0A0E1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF00C853)
                                : const Color(0xFF1F2937),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEE').format(d),
                              style: TextStyle(
                                color: selected
                                    ? Colors.black
                                    : const Color(0xFF8892B0),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('d').format(d),
                              style: TextStyle(
                                color: selected
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
              const Divider(color: Color(0xFF1F2937), height: 1),

              // â”€â”€ Slot grid â”€â”€
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00C853)),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: 24,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final taken = _isTaken(i);
                          final past = _isPast(i);
                          final mine = _isMyBooking(i);
                          final selected = _selectedHour == i;
                          final disabled = taken || past;

                          Color bg;
                          Color fg;
                          String trailing;
                          if (taken && mine) {
                            bg = const Color(0x334FA3E8);
                            fg = const Color(0xFF4FA3E8);
                            trailing = 'Your booking';
                          } else if (taken) {
                            bg = const Color(0x33D32F2F);
                            fg = const Color(0xFFD32F2F);
                            trailing = 'Booked';
                          } else if (past) {
                            bg = const Color(0x228892B0);
                            fg = const Color(0xFF8892B0);
                            trailing = 'Past';
                          } else if (selected) {
                            bg = const Color(0xFF00C853);
                            fg = Colors.black;
                            trailing = 'Selected';
                          } else {
                            bg = const Color(0xFF0A0E1A);
                            fg = Colors.white;
                            trailing = 'Free';
                          }

                          return GestureDetector(
                            onTap: disabled
                                ? null
                                : () {
                                    setState(() =>
                                        _selectedHour = selected ? null : i);
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF00C853)
                                      : const Color(0xFF1F2937),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _slotLabel(i),
                                    style: TextStyle(
                                      color: fg,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    trailing,
                                    style: TextStyle(
                                      color: fg,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // â”€â”€ Confirm bar â”€â”€
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFF1F2937)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedHour == null
                              ? 'Select a time slot'
                              : _slotLabel(_selectedHour!),
                          style: TextStyle(
                            color: _selectedHour == null
                                ? const Color(0xFF8892B0)
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _selectedHour == null
                            ? null
                            : _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFF1F2937),
                          disabledForegroundColor:
                              const Color(0xFF8892B0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
