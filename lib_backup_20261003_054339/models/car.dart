import 'package:cloud_firestore/cloud_firestore.dart';

class Car {
  final String id;
  final String make;
  final String model;
  final String displayName;
  final double batteryKwh;
  final int rangeKm;
  final double consumptionKwhPer100km;
  final int maxChargeKw;
  final List<String> connectorTypes;

  const Car({
    required this.id,
    required this.make,
    required this.model,
    required this.displayName,
    required this.batteryKwh,
    required this.rangeKm,
    required this.consumptionKwhPer100km,
    required this.maxChargeKw,
    required this.connectorTypes,
  });

  factory Car.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Car(
      id: doc.id,
      make: d['make'] ?? '',
      model: d['model'] ?? '',
      displayName: d['displayName'] ?? '',
      batteryKwh: (d['batteryKwh'] ?? 0).toDouble(),
      rangeKm: (d['rangeKm'] ?? 0).toInt(),
      consumptionKwhPer100km:
          (d['consumptionKwhPer100km'] ?? 0).toDouble(),
      maxChargeKw: (d['maxChargeKw'] ?? 0).toInt(),
      connectorTypes:
          List<String>.from(d['connectorTypes'] ?? const []),
    );
  }

  /// Estimated range given a battery percentage (0.0 - 1.0)
  double rangeAt(double batteryLevel) {
    return rangeKm * batteryLevel.clamp(0.0, 1.0);
  }
}