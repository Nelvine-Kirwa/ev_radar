import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/charging_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/battery_tracking_provider.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/battery_gauge.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/quick_stat_card.dart';
import '../widgets/vehicle_card.dart';
import 'station_detail_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/user_location_provider.dart';
import 'navigation_screen.dart';

class CockpitScreen extends StatefulWidget {
  final VoidCallback? onSeeAllStations;
  final VoidCallback? onViewTripDetails;
  final VoidCallback? onManageVehicle;
  const CockpitScreen({
    super.key,
    this.onSeeAllStations,
    this.onViewTripDetails,
    this.onManageVehicle,
  });

  @override
  State<CockpitScreen> createState() => _CockpitScreenState();
}

class _CockpitScreenState extends State<CockpitScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ChargingProvider>();
      if (p.allStations.isEmpty) {
        p.loadAllStations();
      }
      final vp = context.read<VehicleProvider>();
      if (vp.availableCars.isEmpty) {
        vp.loadAvailableCars();
      }
      if (vp.userVehicles.isEmpty) {
        _reloadUserVehicles();
      }
    });
  }

  Future<void> _reloadUserVehicles() async {
    final auth = context.read<AuthProvider>();
    final vp = context.read<VehicleProvider>();
    try {
      final vehicles = await auth.loadVehicles();
      final idx = await auth.loadCurrentVehicleIndex();
      if (vehicles.isNotEmpty) {
        vp.setUserVehicles(vehicles, index: idx);
      }
    } catch (_) {}
  }
  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleProvider>();
    final charging = context.watch<ChargingProvider>();
    final nearby = charging.visibleStations.take(2).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBatteryCard(vehicle),
                const SizedBox(height: 16),
                _buildStatsRow(),
                const SizedBox(height: 16),
                _buildVehicleCard(),
                const SizedBox(height: 16),
                _buildActiveTripCard(),
                const SizedBox(height: 16),
                _buildNearbyCharging(nearby),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryCard(VehicleProvider vehicle) {
    final bt = context.watch<BatteryTrackingProvider>();
    final hasCar = vehicle.currentCar != null;

    // Effective battery: tracking state overrides static value
    final effectivePercent =
        bt.isTracking ? bt.currentPercent : vehicle.batteryLevel;

    final tier = effectivePercent <= 0.15
        ? 2
        : effectivePercent <= 0.30
            ? 1
            : 0;
    final Color tierColor = tier == 2
        ? const Color(0xFFD32F2F)
        : tier == 1
            ? const Color(0xFFFFA000)
            : const Color(0xFF00C853);

    final percent = effectivePercent;
    final rangeText = hasCar
        ? (vehicle.maxRangeKm * effectivePercent).toStringAsFixed(0) + ' km'
        : '-- km';

    // Green line: fill based on current battery % (full when 100%, empty at 0%)
    final greenLineFill = hasCar ? effectivePercent : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'BATTERY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              hasCar
                  ? BatteryIndicator(
                      percent: percent,
                      color: tierColor,
                      width: 92,
                      height: 34,
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0E1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1F2937)),
                      ),
                      child: const Text(
                        '-- %',
                        style: TextStyle(
                            color: Color(0xFF8892B0),
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: BatteryGauge(
              percent: percent,
              size: 180,
              displayText: rangeText,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tracking',
                  style: TextStyle(
                      color: Color(0xFF8892B0), fontSize: 12)),
              Text(
                bt.isTracking ? 'Active' : 'Inactive',
                style: TextStyle(
                    color: bt.isTracking
                        ? const Color(0xFF00C853)
                        : const Color(0xFF8892B0),
                    fontSize: 12,
                    fontWeight: bt.isTracking
                        ? FontWeight.w700
                        : FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: greenLineFill.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatsRow() {
    return Row(
      children: const [
        Expanded(
          child: QuickStatCard(
            label: 'Distance Today',
            value: '--',
            unit: 'km',
            icon: Icons.route_outlined,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: QuickStatCard(
            label: 'Energy Used',
            value: '--',
            unit: 'kWh',
            icon: Icons.bolt_outlined,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: QuickStatCard(
            label: 'Vehicle Efficiency',
            value: '--',
            unit: 'km/kWh',
            icon: Icons.speed_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard() {
    final vp = context.watch<VehicleProvider>();
    final car = vp.currentCar;
    final userVehicle = vp.currentUserVehicle;

    if (car == null || userVehicle == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'MY VEHICLE',
              style: TextStyle(
                color: Color(0xFF8892B0),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'No vehicle added',
                style: TextStyle(
                  color: Color(0xFF8892B0),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: widget.onManageVehicle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF00C853), width: 1.2),
                  ),
                  child: const Text(
                    'Add Vehicle',
                    style: TextStyle(
                      color: Color(0xFF00C853),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return VehicleCard(
      imagePath: 'assets/images/vehicle/my_vehicle.jpg',
      modelName: car.displayName,
      trim: car.model,
      plate: userVehicle.plate,
      rangeKm: car.rangeKm,
      onManage: widget.onManageVehicle,
      onConnect: () => _showBatterySlider(context),
    );
  }
  Future<void> _resumeNavigation(BuildContext context, dynamic trip) async {
    final loc = context.read<UserLocationProvider>();
    if (loc.position == null) {
      await loc.ensureLoaded();
    }
    final pos = loc.position;
    if (pos == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for location… try again in a moment')),
      );
      return;
    }
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationScreen.toPlace(
          origin: LatLng(pos.latitude, pos.longitude),
          destinationLatLng: LatLng(trip.destLat, trip.destLng),
          destinationName: trip.destination,
          destinationAddress: trip.destination,
        ),
      ),
    );
  }

  void _showBatterySlider(BuildContext context) {
    final vp = context.read<VehicleProvider>();
    double draftValue = vp.batteryLevel;
    final justUpdated = ValueNotifier<bool>(false);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111827),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<BatteryTrackingProvider>(
          builder: (ctx, bt, _) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                final pct = (draftValue * 100).round();
                return SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Set Current Battery',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close,
                                  color: Color(0xFFD32F2F), size: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$pct%',
                          style: TextStyle(
                            color: pct <= 15
                                ? const Color(0xFFD32F2F)
                                : pct <= 30
                                    ? const Color(0xFFFFA000)
                                    : const Color(0xFF00C853),
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Slider(
                          value: draftValue,
                          min: 0.05,
                          max: 1.0,
                          divisions: 95,
                          activeColor: const Color(0xFF00C853),
                          inactiveColor: const Color(0xFF1F2937),
                          onChanged: (v) {
                            setSheetState(() => draftValue = v);
                            if (justUpdated.value) {
                              justUpdated.value = false;
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    vp.updateBattery(draftValue);
                                    if (bt.isTracking) {
                                      await bt.updateCurrentPercent(draftValue);
                                    }
                                    justUpdated.value = true;
                                    setSheetState(() {});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1F2937),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      side: const BorderSide(
                                        color: Color(0xFF00C853),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: justUpdated,
                                    builder: (c, updated, _) => Text(
                                      updated ? 'Updated' : 'Update',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (bt.isTracking) {
                                      await bt.pauseTracking();
                                    } else {
                                      vp.updateBattery(draftValue);
                                      await bt.startTracking(draftValue);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1F2937),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      side: BorderSide(
                                        color: bt.isTracking
                                            ? const Color(0xFFD32F2F)
                                            : const Color(0xFF00C853),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    bt.isTracking
                                        ? 'Pause Tracking'
                                        : 'Track',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() => justUpdated.dispose());
  }

  Widget _buildActiveTripCard() {
    final trip = context.watch<TripProvider>().activeTrip;
    final hasTrip = trip != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  CircleAvatar(
                      radius: 4, backgroundColor: Color(0xFF00C853)),
                  SizedBox(width: 8),
                  Text(
                    'ACTIVE TRIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Text(
                'Navigation',
                style: TextStyle(color: Color(0xFF8892B0), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasTrip) ...[
            Text(
              trip.destination,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${trip.distanceKm.toStringAsFixed(0)} km remaining  -  ${trip.etaMinutes} min ETA',
              style: const TextStyle(
                  color: Color(0xFF8892B0), fontSize: 12),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final maxW = constraints.maxWidth;
                final progress = trip.originalDistanceKm > 0
                    ? ((trip.originalDistanceKm - trip.distanceKm) /
                            trip.originalDistanceKm)
                        .clamp(0.0, 1.0)
                    : 0.0;
                final thumbX = (maxW * progress).clamp(6.0, maxW - 6.0);
                return SizedBox(
                  height: 14,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 5,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 5,
                        child: Container(
                          height: 4,
                          width: maxW * progress,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        left: thumbX - 6,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF0A0E1A), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _outlineButton(
                  label: 'View Trip',
                  color: const Color(0xFF00C853),
                  onTap: () => _resumeNavigation(context, trip),
                ),
                _outlineButton(
                  label: 'End Trip',
                  color: const Color(0xFFD32F2F),
                  onTap: () {
                    context.read<TripProvider>().endTrip();
                  },
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'No active trip',
                style: TextStyle(
                  color: Color(0xFF8892B0),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: _outlineButton(
                label: 'Plan New Trip',
                color: const Color(0xFF00C853),
                onTap: widget.onViewTripDetails ?? () {},
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }  Widget _buildNearbyCharging(List<dynamic> nearby) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Charging',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GestureDetector(
                onTap: widget.onSeeAllStations,
                child: const Row(
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: Color(0xFF00C853), size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (nearby.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Loading nearby stations...',
                style: TextStyle(color: Color(0xFF8892B0), fontSize: 12),
              ),
            )
          else
            ...nearby.map((s) => _stationRow(s)),
        ],
      ),
    );
  }

  Widget _stationRow(dynamic s) {
    final status = s.statusTier == 'available'
        ? 'Available'
        : (s.statusTier == 'busy' ? 'Busy' : 'Offline');
    final statusColor = s.statusTier == 'available'
        ? const Color(0xFF00C853)
        : (s.statusTier == 'busy'
            ? const Color(0xFFFFA000)
            : const Color(0xFF8892B0));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StationDetailScreen(stationId: s.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.neighborhood}  -  ${s.powerKw.toStringAsFixed(0)} kW',
                    style: const TextStyle(
                      color: Color(0xFF8892B0),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: Color(0xFF8892B0), size: 18),
          ],
        ),
      ),
    );
  }

}