import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class ChargingStation {
  final String id;
  final String name;
  final String operator;
  final String neighborhood;
  final String address;
  final double lat;
  final double lng;
  final String connectorType;
  final double powerKw;
  final int portsTotal;
  final int portsAvailable;
  final String status;
  final int pricePerKwhKsh;
  final String chargerImage;
  final String operatingHours;
  final String phone;
  final List<String> amenities;
  final String source;

  ChargingStation({
    required this.id,
    required this.name,
    required this.operator,
    required this.neighborhood,
    required this.address,
    required this.lat,
    required this.lng,
    required this.connectorType,
    required this.powerKw,
    required this.portsTotal,
    required this.portsAvailable,
    required this.status,
    required this.pricePerKwhKsh,
    required this.chargerImage,
    required this.operatingHours,
    required this.phone,
    required this.amenities,
    required this.source,
  });

  factory ChargingStation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChargingStation(
      id: doc.id,
      name: data['name'] ?? '',
      operator: data['operator'] ?? '',
      neighborhood: data['neighborhood'] ?? '',
      address: data['address'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      connectorType: data['connectorType'] ?? 'Type 2 AC',
      powerKw: (data['powerKw'] ?? 22).toDouble(),
      portsTotal: (data['portsTotal'] ?? 2).toInt(),
      portsAvailable: (data['portsAvailable'] ?? 2).toInt(),
      status: data['status'] ?? 'Operational',
      pricePerKwhKsh: (data['pricePerKwhKsh'] ?? 28).toInt(),
      chargerImage: data['chargerImage'] ?? 'assets/images/chargers/type2_ac.jpg',
      operatingHours: data['operatingHours'] ?? '24 hours',
      phone: data['phone'] ?? '',
      amenities: List<String>.from(data['amenities'] ?? const []),
      source: data['source'] ?? '',
    );
  }

  // Haversine distance in km from a given point
  double distanceFrom(double userLat, double userLng) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat - userLat);
    final dLng = _toRad(lng - userLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(userLat)) *
            math.cos(_toRad(lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRad(double deg) => deg * math.pi / 180.0;

  // A single label string for the connector (used in port rows)
  String get connectorLabel {
    return connectorType;
  }

  // Status pill label
  String get statusLabel {
    return status.toUpperCase();
  }

  // Status tier for color
  String get statusTier {
    switch (status.toLowerCase()) {
      case 'operational':
        return 'available';
      case 'busy':
        return 'busy';
      case 'offline':
        return 'offline';
      default:
        return 'available';
    }
  }
}