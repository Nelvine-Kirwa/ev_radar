import 'package:flutter/material.dart';

class TripProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _trips = [];
  Map<String, dynamic>? _activeTrip;

  List<Map<String, dynamic>> get trips => _trips;
  Map<String, dynamic>? get activeTrip => _activeTrip;
  bool get hasActiveTrip => _activeTrip != null;

  void startTrip(String destination, double distanceKm) {
    _activeTrip = {
      'destination': destination,
      'distanceKm': distanceKm,
      'startedAt': DateTime.now().toIso8601String(),
    };
    notifyListeners();
  }

  void endTrip() {
    if (_activeTrip != null) {
      _activeTrip!['endedAt'] = DateTime.now().toIso8601String();
      _trips.add(_activeTrip!);
      _activeTrip = null;
      notifyListeners();
    }
  }
}