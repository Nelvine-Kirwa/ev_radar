import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/charging_provider.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/battery_gauge.dart';
import '../widgets/quick_stat_card.dart';
import '../widgets/vehicle_card.dart';
import 'station_detail_screen.dart';

class CockpitScreen extends StatefulWidget {
  final VoidCallback? onSeeAllStations;
  const CockpitScreen({super.key, this.onSeeAllStations});

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
    });
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
    final percent = vehicle.batteryLevel;
    final range = vehicle.rangeKm;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              GestureDetector(
                onTap: () {
                  // Placeholder — tracking toggle coming later
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Connect Vehicle',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(child: BatteryGauge(percent: percent, size: 180)),
          const SizedBox(height: 20),
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: range.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Color(0xFF00C853),
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const TextSpan(
                    text: ' km',
                    style: TextStyle(
                      color: Color(0xFF00C853),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Tracking',
                style: TextStyle(color: Color(0xFF8892B0), fontSize: 12),
              ),
              Text(
                'Inactive',
                style: TextStyle(
                  color: Color(0xFF8892B0),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
              widthFactor: 0.15,
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
            value: '24',
            unit: 'km',
            icon: Icons.route_outlined,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: QuickStatCard(
            label: 'Energy Used',
            value: '3.8',
            unit: 'kWh',
            icon: Icons.bolt_outlined,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: QuickStatCard(
            label: 'Vehicles Efficiency',
            value: '6.3',
            unit: 'km/kWh',
            icon: Icons.speed_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard() {
    return VehicleCard(
      imagePath: 'assets/images/vehicle/my_vehicle.jpg',
      modelName: 'Tesla Model 3',
      trim: 'Long Range',
      plate: 'KDA 123A',
      rangeKm: 376,
      onManage: () {},
      onConnect: () {},
    );
  }

  Widget _buildActiveTripCard() {
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
          const Text(
            'Karen, Nairobi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '12 km remaining  -  18 min ETA',
            style: TextStyle(color: Color(0xFF8892B0), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.65,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'View Details',
                style: TextStyle(
                  color: Color(0xFF00C853),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD32F2F)),
                ),
                child: const Text(
                  'End Trip',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyCharging(List<dynamic> nearby) {
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

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x1A00C853),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x6600C853)),
              ),
              child: Icon(icon, color: const Color(0xFF00C853), size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}