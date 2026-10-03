import 'package:flutter/material.dart';

class ActiveTrip {
  final String destination;
  final double distanceKm;
  final int etaMinutes;
  final String originLabel;

  const ActiveTrip({
    required this.destination,
    required this.distanceKm,
    required this.etaMinutes,
    this.originLabel = 'Current Location',
  });
}

class TripProvider extends ChangeNotifier {
  ActiveTrip? _activeTrip;

  ActiveTrip? get activeTrip => _activeTrip;
  bool get hasActiveTrip => _activeTrip != null;

  void startTrip(ActiveTrip trip) {
    _activeTrip = trip;
    notifyListeners();
  }

  void endTrip() {
    _activeTrip = null;
    notifyListeners();
  }

  // Demo helper — used until real trip planning is wired
  void startDemoTrip() {
    _activeTrip = const ActiveTrip(
      destination: 'Karen, Nairobi',
      distanceKm: 12,
      etaMinutes: 18,
    );
    notifyListeners();
  }
}