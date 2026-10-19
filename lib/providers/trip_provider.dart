import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActiveTrip {
  final String destination;
  final double distanceKm;
  final int etaMinutes;
  final String originLabel;
  final double destLat;
  final double destLng;

  const ActiveTrip({
    required this.destination,
    required this.distanceKm,
    required this.etaMinutes,
    this.originLabel = 'Current Location',
    this.destLat = 0.0,
    this.destLng = 0.0,
  });
}

class TripProvider extends ChangeNotifier {
  ActiveTrip? _activeTrip;

  ActiveTrip? get activeTrip => _activeTrip;
  bool get hasActiveTrip => _activeTrip != null;

  void startTrip(ActiveTrip trip) {
    _activeTrip = trip;
    notifyListeners();
    _persistTrip(trip);
  }

  void endTrip() {
    _activeTrip = null;
    notifyListeners();
    _clearPersistedTrip();
  }

  // Demo helper â€” used until real trip planning is wired
  void startDemoTrip() {
    _activeTrip = const ActiveTrip(
      destination: 'Karen, Nairobi',
      distanceKm: 12,
      etaMinutes: 18,
      destLat: -1.3300,
      destLng: 36.7000,
    );
    notifyListeners();
  }

  Future<void> _persistTrip(ActiveTrip trip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_trip_destination', trip.destination);
      await prefs.setDouble('active_trip_distance', trip.distanceKm);
      await prefs.setInt('active_trip_eta', trip.etaMinutes);
      await prefs.setString('active_trip_origin', trip.originLabel);
      await prefs.setDouble('active_trip_lat', trip.destLat);
      await prefs.setDouble('active_trip_lng', trip.destLng);
    } catch (_) {}
  }

  Future<void> _clearPersistedTrip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_trip_destination');
      await prefs.remove('active_trip_distance');
      await prefs.remove('active_trip_eta');
      await prefs.remove('active_trip_origin');
      await prefs.remove('active_trip_lat');
      await prefs.remove('active_trip_lng');
    } catch (_) {}
  }

  Future<void> loadPersistedTrip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dest = prefs.getString('active_trip_destination');
      if (dest == null) return;
      final dist = prefs.getDouble('active_trip_distance') ?? 0;
      final eta = prefs.getInt('active_trip_eta') ?? 0;
      final origin = prefs.getString('active_trip_origin') ?? 'Current Location';
      final lat = prefs.getDouble('active_trip_lat') ?? 0;
      final lng = prefs.getDouble('active_trip_lng') ?? 0;
      _activeTrip = ActiveTrip(
        destination: dest,
        distanceKm: dist,
        etaMinutes: eta,
        originLabel: origin,
        destLat: lat,
        destLng: lng,
      );
      notifyListeners();
    } catch (_) {}
  }
}