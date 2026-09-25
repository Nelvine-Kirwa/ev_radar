import 'package:flutter/material.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/dark_bottom_nav.dart';
import 'cockpit_screen.dart';
import 'stations_screen.dart';
import 'planner_screen.dart';
import 'services_screen.dart';
import 'vehicle_picker_screen.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Column(
        children: [
          const SafeArea(bottom: false, child: AppTopBar()),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                CockpitScreen(
                  onSeeAllStations: () => _goTo(1),
                  onViewTripDetails: () => _goTo(2),
                  onManageVehicle: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const VehiclePickerScreen()),
                    );
                  },
                ),
                const StationsScreen(),
                PlannerScreen(onStartNavigation: () => _goTo(1)),
                const ServicesScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DarkBottomNav(
        currentIndex: _index,
        onTap: _goTo,
      ),
    );
  }
}