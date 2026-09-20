import '../models/equipment.dart';

const List<Equipment> kHardwareOptions = [
  Equipment(
    name: 'Home AC Charger 7 kW',
    category: 'LEVEL 2 - 32A',
    imagePath: 'assets/images/chargers/type2_ac.jpg',
    features: [
      'Single-phase 32A overnight',
      'KPLC residential meter ready',
    ],
    priceLabel: 'TURNKEY PACKAGE',
    priceKsh: 74900,
  ),
  Equipment(
    name: 'Universal Wallbox 11 kW',
    category: '3-PHASE - 16A',
    imagePath: 'assets/images/chargers/type2_ccs_combo.jpg',
    features: [
      'Three-phase 16A fast',
      'IP65 weatherproof enclosure',
    ],
    priceLabel: 'COMPLETE KIT',
    priceKsh: 98500,
  ),
  Equipment(
    name: 'Dual Port Wallbox 22 kW',
    category: 'DUAL PORT - 22A',
    imagePath: 'assets/images/chargers/type1_type2_combo.jpg',
    features: [
      'Two vehicles simultaneously',
      'Type 1 & Type 2 connectors',
    ],
    priceLabel: 'COMPLETE KIT',
    priceKsh: 128000,
  ),
];

class Electricians {
  static const List<Map<String, dynamic>> available = [
    {
      'name': 'Denis Kimtai',
      'license': 'EPRA/EM/2024/0472',
      'rating': 4.9,
      'installations': 128,
    },
    {
      'name': 'Nelvin Kipchirchir',
      'license': 'EPRA/EM/2023/0189',
      'rating': 4.6,
      'installations': 92,
    },
  ];
}