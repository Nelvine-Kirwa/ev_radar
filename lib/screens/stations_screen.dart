import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/charging_provider.dart';
import '../providers/user_location_provider.dart';
import '../providers/saved_stations_provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/car.dart';
import '../utils/connector_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/car.dart';
import '../utils/connector_utils.dart';
import '../widgets/station_filter_chip.dart';
import '../widgets/station_list_row.dart';
import '../widgets/radar_overlay.dart';
import 'station_detail_screen.dart';
import '../widgets/station_map_view.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _myCarOnly = false;

  /// When true, only show stations whose connectors match the user's current vehicle.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureStationsLoaded();
    });
  }

  Future<void> _ensureStationsLoaded() async {
    final provider = context.read<ChargingProvider>();
    if (provider.allStations.isEmpty) {
      await provider.loadAllStations();
    }

    // Make sure we have the user's location so distances can render.
    // If splash's fetch failed silently, this retries on tab entry.
    if (mounted) {
      final ul = context.read<UserLocationProvider>();
      if (!ul.hasLocation && !ul.loading) {
        unawaited(ul.refresh());
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChargingProvider>();
    final saved = context.watch<SavedStationsProvider>();
    final userLoc = context.watch<UserLocationProvider>();
    final vehicle = context.watch<VehicleProvider>();
    final currentCar = vehicle.currentCar;

    final baseStations =
        provider.visibleStationsWith(savedIds: saved.savedIds);

    final stations = _myCarOnly && currentCar != null
        ? baseStations.where((s) {
            return ConnectorUtils.carMatchesStation(
              carConnectors: currentCar.connectorTypes,
              stationConnector: s.connectorType,
            );
          }).toList()
        : baseStations;

    return Column(
      children: [
        const SizedBox(height: 4),
        _buildSearchBar(),
        const SizedBox(height: 12),
        _buildFilterChips(provider),
        const SizedBox(height: 12),
        Expanded(
          child: Stack(
            children: [
              // Layer 1: Map (fills entire area, but only the top part is
              // actually touchable ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â the sheet covers the rest)
              Positioned.fill(
                child: _buildMapSection(provider),
              ),

              // Layer 2: Draggable sheet ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â original valid ratios
              DraggableScrollableSheet(
                initialChildSize: 0.42,
                minChildSize: 0.25,
                maxChildSize: 0.85,
                snap: true,
                snapSizes: const [0.25, 0.42, 0.85],
                builder: (context, scrollController) {
                  return Material(
                    color: const Color(0xFF111827),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        border: Border(
                          top: BorderSide(
                              color: Color(0xFF1F2937), width: 1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A5568),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 4, 20, 10),
                            child: Row(
                              children: [
                                Text(
                                  '${stations.length} stations in this view',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            color: Color(0xFF1F2937),
                            height: 1,
                            thickness: 1,
                          ),
                          Expanded(
                            child: provider.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF00C853),
                                    ),
                                  )
                                : stations.isEmpty
                                    ? _buildEmpty()
                                    : ListView.separated(
                                        controller: scrollController,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        itemCount: stations.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                          color: Color(0xFF1F2937),
                                          height: 1,
                                          thickness: 1,
                                          indent: 76,
                                        ),
                                        itemBuilder: (context, i) {
                                          final s = stations[i];
                                          final dist = (userLoc.lat != null &&
                                                  userLoc.lng != null)
                                              ? s.distanceFrom(
                                                  userLoc.lat!, userLoc.lng!)
                                              : null;
                                          return StationListRow(
                                            station: s,
                                            status: provider.pseudoStatus(s),
                                            distanceKm: dist,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      StationDetailScreen(
                                                    stationId: s.id,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (provider.isLoading && provider.allStations.isEmpty)
                const RadarOverlay(
                  statusText: 'SCANNING NEARBY STATIONS...',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (v) => context.read<ChargingProvider>().setSearch(v),
          decoration: const InputDecoration(
            hintText: 'Search stations, neighborhoods...',
            hintStyle: TextStyle(color: Color(0xFF4A5568), fontSize: 14),
            prefixIcon:
                Icon(Icons.search, color: Color(0xFF8892B0), size: 20),
            suffixIcon:
                Icon(Icons.tune, color: Color(0xFF8892B0), size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ChargingProvider provider) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _chip('All', StationFilter.all, provider),
          const SizedBox(width: 8),
          _chip('Available', StationFilter.available, provider),
          const SizedBox(width: 8),
          _chip('Fast Charging', StationFilter.fast, provider),
          const SizedBox(width: 8),
          _chip('Nearby', StationFilter.nearby, provider),
          const SizedBox(width: 8),
          StationFilterChip(
            label: 'My Car',
            isActive: _myCarOnly,
            onTap: () => setState(() => _myCarOnly = !_myCarOnly),
          ),
          const SizedBox(width: 8),
          _chip('Saved', StationFilter.saved, provider),
        ],
      ),
    );
  }

  Widget _chip(String label, StationFilter filter, ChargingProvider p) {
    return StationFilterChip(
      label: label,
      isActive: p.activeFilter == filter,
      onTap: () => p.setFilter(filter),
    );
  }

  Widget _buildMapSection(ChargingProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1620),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1F2937)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _GridPainter()),
              ),
              Positioned.fill(
                child: StationMapView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: Color(0xFF4A5568), size: 40),
          SizedBox(height: 12),
          Text('No stations match your search',
              style: TextStyle(color: Color(0xFF8892B0), fontSize: 14)),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F2937).withOpacity(0.4)
      ..strokeWidth = 0.6;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
