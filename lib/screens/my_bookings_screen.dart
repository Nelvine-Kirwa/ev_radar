import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../models/station_booking.dart';
import '../providers/auth_provider.dart';
import '../providers/station_booking_provider.dart';
import '../services/booking_service.dart';

/// Shows all of the current user's bookings — charging slots and
/// installation services — in two tabs.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Charging bookings state
  List<StationBooking> _charging = [];
  bool _chargingLoading = true;

  // Installation bookings state
  List<Booking> _installations = [];
  bool _installationsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null || uid.isEmpty) {
      setState(() {
        _chargingLoading = false;
        _installationsLoading = false;
      });
      return;
    }

    // Charging bookings
    try {
      final bp = context.read<StationBookingProvider>();
      await bp.loadMyBookings(uid);
      setState(() {
        _charging = bp.myBookings;
        _chargingLoading = false;
      });
    } catch (_) {
      setState(() => _chargingLoading = false);
    }

    // Installation bookings
    try {
      final list = await BookingService().getAllForUser(uid);
      setState(() {
        _installations = list;
        _installationsLoading = false;
      });
    } catch (_) {
      setState(() => _installationsLoading = false);
    }
  }

  Future<void> _cancelCharging(StationBooking b) async {
    final confirmed = await _confirm(
      'Cancel booking?',
      'You are about to cancel ${b.stationName} on '
          '${DateFormat('EEE, d MMM').format(b.startTime)}.',
    );
    if (!confirmed) return;

    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) return;

    final ok = await context
        .read<StationBookingProvider>()
        .cancelBooking(b.id, uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Booking cancelled' : 'Could not cancel')),
    );
    if (ok) _loadAll();
  }

  Future<void> _cancelInstallation(Booking b) async {
    final confirmed = await _confirm(
      'Cancel booking?',
      'You are about to cancel ${b.equipmentName} '
          'at ${b.address}.',
    );
    if (!confirmed) return;

    final ok = await BookingService().cancelBooking(b.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Booking cancelled' : 'Could not cancel')),
    );
    if (ok) _loadAll();
  }

  Future<bool> _confirm(String title, String body) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body,
            style: const TextStyle(color: Color(0xFFB8C7DA))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep',
                style: TextStyle(color: Color(0xFF8892B0))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Booking',
                style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        title: const Text('My Bookings',
            style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF00C853),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF8892B0),
          tabs: const [
            Tab(text: 'Charging'),
            Tab(text: 'Installations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildChargingTab(),
          _buildInstallationsTab(),
        ],
      ),
    );
  }

  Widget _buildChargingTab() {
    if (_chargingLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C853)),
      );
    }
    // Show upcoming/active first, then past.
    final now = DateTime.now();
    _charging.sort((a, b) {
      final aPast = a.endTime.isBefore(now);
      final bPast = b.endTime.isBefore(now);
      if (aPast != bPast) return aPast ? 1 : -1;
      return a.startTime.compareTo(b.startTime);
    });

    if (_charging.isEmpty) {
      return _empty('No charging bookings yet.',
          'Book a slot from any station detail screen.');
    }

    return RefreshIndicator(
      color: const Color(0xFF00C853),
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _charging.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _chargingCard(_charging[i]),
      ),
    );
  }

  Widget _chargingCard(StationBooking b) {
    final now = DateTime.now();
    final active = b.isCurrentlyActive(now);
    final upcoming = b.startTime.isAfter(now);
    final cancelled = b.status == 'CANCELLED';
    final expired = b.status == 'EXPIRED';

    Color statusColor;
    String statusLabel;
    if (cancelled) {
      statusColor = const Color(0xFF8892B0);
      statusLabel = 'CANCELLED';
    } else if (expired) {
      statusColor = const Color(0xFF8892B0);
      statusLabel = 'EXPIRED';
    } else if (active) {
      statusColor = const Color(0xFF00C853);
      statusLabel = 'ACTIVE';
    } else if (upcoming) {
      statusColor = const Color(0xFF4FA3E8);
      statusLabel = 'UPCOMING';
    } else {
      statusColor = const Color(0xFF8892B0);
      statusLabel = 'PAST';
    }

    final canCancel = b.status == 'CONFIRMED' && b.startTime.isAfter(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.ev_station,
                  color: Color(0xFF00C853), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  b.stationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row('Date', DateFormat('EEE, d MMM yyyy').format(b.startTime)),
          _row('Time',
              '${DateFormat('h:mm a').format(b.startTime)} - ${DateFormat('h:mm a').format(b.endTime)}'),
          if (canCancel) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _cancelCharging(b),
                icon: const Icon(Icons.cancel_outlined,
                    size: 16, color: Color(0xFFD32F2F)),
                label: const Text(
                  'CANCEL BOOKING',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstallationsTab() {
    if (_installationsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C853)),
      );
    }
    if (_installations.isEmpty) {
      return _empty('No installation bookings yet.',
          'Book one from the Services tab.');
    }
    return RefreshIndicator(
      color: const Color(0xFF00C853),
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _installations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _installCard(_installations[i]),
      ),
    );
  }

  Widget _installCard(Booking b) {
    final statusColor = b.status == 'CANCELLED'
        ? const Color(0xFF8892B0)
        : const Color(0xFF00C853);
    final canCancel = b.status == 'SCHEDULED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.electrical_services,
                  color: Color(0xFF00C853), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  b.equipmentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  b.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row('Technician', b.electricianName),
          _row('Address', b.address),
          _row('Fee', 'KSh ${b.bookingFeeKsh}'),
          if (canCancel) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _cancelInstallation(b),
                icon: const Icon(Icons.cancel_outlined,
                    size: 16, color: Color(0xFFD32F2F)),
                label: const Text(
                  'CANCEL BOOKING',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                  color: Color(0xFF8892B0), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_note,
                color: Color(0xFF4A5568), size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF8892B0), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}