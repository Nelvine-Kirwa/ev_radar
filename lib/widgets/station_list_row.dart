import 'package:flutter/material.dart';
import '../models/charging_station.dart';

class StationListRow extends StatelessWidget {
  final ChargingStation station;
  final String status;
  final double? distanceKm;
  final VoidCallback onTap;

  const StationListRow({
    super.key,
    required this.station,
    required this.status,
    required this.onTap,
    this.distanceKm,
  });

  Color get _statusColor {
    switch (status) {
      case 'available':
        return const Color(0xFF00C853);
      case 'busy':
        return const Color(0xFFFFA000);
      case 'offline':
      default:
        return const Color(0xFF8892B0);
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'available':
        return 'Available';
      case 'busy':
        return 'Busy';
      case 'offline':
      default:
        return 'Offline';
    }
  }

  String get _distanceText {
    if (distanceKm == null) return '-- km';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x3300C853),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x6600C853)),
              ),
              child: const Icon(
                Icons.ev_station,
                color: Color(0xFF00C853),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _distanceText,
                        style: const TextStyle(
                          color: Color(0xFF8892B0),
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        ' - ',
                        style: TextStyle(
                          color: Color(0xFF8892B0),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        ' - ',
                        style: TextStyle(
                          color: Color(0xFF8892B0),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${station.powerKw.toStringAsFixed(0)} kW',
                        style: const TextStyle(
                          color: Color(0xFF8892B0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'KSh ${station.pricePerKwhKsh}',
                  style: const TextStyle(
                    color: Color(0xFF00C853),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '/kWh',
                  style: TextStyle(
                    color: Color(0xFF8892B0),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF8892B0),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}