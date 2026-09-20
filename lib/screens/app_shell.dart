import 'package:flutter/material.dart';
import '../widgets/dark_bottom_nav.dart';
import 'cockpit_screen.dart';
import 'stations_screen.dart';
import 'planner_screen.dart';
import 'services_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: IndexedStack(
        index: _index,
        children: [
          const CockpitScreen(),
          const StationsScreen(),
          PlannerScreen(
            onStartNavigation: () {
              setState(() => _index = 1);
            },
          ),
          const ServicesScreen(),
        ],
      ),
      bottomNavigationBar: DarkBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}