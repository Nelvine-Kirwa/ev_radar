import 'package:flutter/material.dart';

class DarkBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const DarkBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.speed, label: 'Cockpit'),
    _NavItem(icon: Icons.ev_station, label: 'Stations'),
    _NavItem(icon: Icons.alt_route, label: 'Planner'),
    _NavItem(icon: Icons.work_outline, label: 'Services'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E1A),
        border: Border(
          top: BorderSide(color: Color(0xFF1F2937), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: onTap != null ? () => onTap!(i) : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: isActive
                            ? const Color(0xFF00C853)
                            : const Color(0xFF8892B0),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF00C853)
                              : const Color(0xFF8892B0),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 20,
                        height: 2,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF00C853)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}