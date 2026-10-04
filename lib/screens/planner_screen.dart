import 'package:flutter/material.dart';
import '../models/trip_plan.dart';
import '../services/trip_planner_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/station_booking_provider.dart';
import '../providers/auth_provider.dart';
import '../models/station_booking.dart';
import 'my_bookings_screen.dart';

class PlannerScreen extends StatefulWidget {
  final VoidCallback? onStartNavigation;
  const PlannerScreen({super.key, this.onStartNavigation});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late final TripPlan _plan;

  @override
  void initState() {
    super.initState();
    _plan = TripPlannerService().getNairobiToMombasa();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
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
                _buildTripInput(),
                const SizedBox(height: 16),
                _buildRouteSummary(),
                const SizedBox(height: 16),
                _buildBookingsSection(),
                _buildChargingStops(),
                const SizedBox(height: 16),
                _buildTimeline(),
                const SizedBox(height: 20),
                _buildStartNavigationCta(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Loads the user's upcoming charging bookings when the Planner opens.
  Future<void> _loadBookings() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null || uid.isEmpty) return;
    await context.read<StationBookingProvider>().loadMyBookings(uid);
  }

  Widget _buildBookingsSection() {
    return Consumer<StationBookingProvider>(
      builder: (ctx, bp, _) {
        final now = DateTime.now();
        final upcoming = bp.myBookings
            .where((b) =>
                b.status == 'CONFIRMED' && b.endTime.isAfter(now))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'UPCOMING BOOKINGS',
                    style: TextStyle(
                      color: Color(0xFFB8C7DA),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyBookingsScreen(),
                        ),
                      ).then((_) => _loadBookings());
                    },
                    child: const Text(
                      'See all >',
                      style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (upcoming.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No bookings yet',
                    style: TextStyle(
                        color: Color(0xFF8892B0), fontSize: 13),
                  ),
                )
              else
                ...upcoming.take(3).map((b) => _bookingRow(b)),
            ],
          ),
        );
      },
    );
  }

  Widget _bookingRow(StationBooking b) {
    final dateFmt = DateFormat('EEE, d MMM');
    final timeFmt = DateFormat('h:mm a');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00C853),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.stationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${dateFmt.format(b.startTime)}  ·  ' +
                      '${timeFmt.format(b.startTime)} – ' +
                      '${timeFmt.format(b.endTime)}',
                  style: const TextStyle(
                    color: Color(0xFF8892B0),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildTripInput() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _inputRow(Icons.place_outlined, 'FROM', _plan.origin),
          const SizedBox(height: 10),
          _inputRow(Icons.flag_outlined, 'TO', _plan.destination),
          const SizedBox(height: 14),
          Row(
            children: [
              _chip(_plan.vehicleName),
              const SizedBox(width: 8),
              _chip('${_plan.startBatteryPercent}%'),
              const SizedBox(width: 8),
              _chip(_plan.departureLabel),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.route, size: 18),
              label: const Text(
                'Calculate Route',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00C853), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF8892B0),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Color(0xFFB8C7DA),
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildRouteSummary() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Route Summary',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              if (_plan.routeViable)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x1A00C853),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x6600C853)),
                  ),
                  child: const Text('Route viable',
                      style: TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryBlock('${_plan.distanceKm} km', '5h 45m'),
              ),
              Expanded(
                child: _summaryBlock(
                  '${_plan.stopsCount} stop',
                  '${_plan.totalChargingMin} min',
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF1F2937), height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _projectionValue('START', '${_plan.startBatteryPercent}%',
                  valueColor: Colors.white),
              _projectionValue(
                  'ON ARRIVAL', '${_plan.arrivalBatteryPercent}%',
                  valueColor: const Color(0xFF00C853)),
              _projectionValue(
                  'ENERGY NEEDED', '${_plan.energyNeededKwh} kWh',
                  valueColor: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryBlock(String primary, String secondary,
      {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(primary,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(secondary,
            style: const TextStyle(
                color: Color(0xFF8892B0), fontSize: 12)),
      ],
    );
  }

  Widget _projectionValue(String label, String value,
      {required Color valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8892B0),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildChargingStops() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Charging Stops',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_plan.stopsCount} stop',
                    style: const TextStyle(
                        color: Color(0xFF8892B0),
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._plan.chargingStops.map((s) => _stopCard(s)),
          const Divider(color: Color(0xFF1F2937), height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated charging cost',
                  style: TextStyle(
                      color: Color(0xFF8892B0), fontSize: 12)),
              Text('KSh ${_plan.estimatedTotalCostKsh}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stopCard(ChargingStop s) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0x1A00C853),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('1',
                    style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.stationName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${s.location} - ${s.powerDetail}',
                        style: const TextStyle(
                            color: Color(0xFF8892B0), fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Color(0xFF8892B0), size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Arrive ${s.arrivalSoc}%  -  Charge ${s.chargeDurationMin} min  -  Depart ${s.departureSoc}%',
            style: const TextStyle(
                color: Color(0xFFB8C7DA), fontSize: 11),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00C853)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('View Station',
                  style: TextStyle(
                      color: Color(0xFF00C853),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Route Timeline',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ...List.generate(_plan.timelineSteps.length, (i) {
            final step = _plan.timelineSteps[i];
            final isLast = i == _plan.timelineSteps.length - 1;
            return _timelineRow(step, isLast);
          }),
        ],
      ),
    );
  }

  Widget _timelineRow(TimelineStep step, bool isLast) {
    Color markerColor;
    if (step.isArrival) {
      markerColor = const Color(0xFF00C853);
    } else if (step.isCharging) {
      markerColor = const Color(0xFF00C853);
    } else {
      markerColor = const Color(0xFF1F2937);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: step.isArrival || step.isCharging
                      ? const Color(0x1A00C853)
                      : const Color(0xFF0A0E1A),
                  shape: BoxShape.circle,
                  border: Border.all(color: markerColor, width: 2),
                ),
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
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(step.subtitle,
                      style: const TextStyle(
                          color: Color(0xFF8892B0), fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartNavigationCta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.onStartNavigation != null) {
                widget.onStartNavigation!();
              }
            },
            icon: const Icon(Icons.navigation_outlined, size: 18),
            label: const Text(
              'START NAVIGATION',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Estimated 1 stop - 35 min total charging',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8892B0), fontSize: 11),
        ),
      ],
    );
  }
}
