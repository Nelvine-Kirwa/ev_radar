import 'package:flutter/material.dart';
import '../screens/profile_support_screen.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EV RADAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00C853),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'NAIROBI - KPLC READY',
                    style: TextStyle(
                      color: Color(0xFF8892B0),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          _circleIcon(Icons.notifications_none, hasBadge: true),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileSupportScreen(),
                ),
              );
            },
            child: _circleIcon(Icons.person_outline),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, {bool hasBadge = false}) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF1A2332),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        if (hasBadge)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF00C853),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0A0E1A), width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}