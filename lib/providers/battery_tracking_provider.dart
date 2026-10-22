import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks battery drain from GPS distance covered.
class BatteryTrackingProvider extends ChangeNotifier {
  static const double _defaultKmPerPercent = 3.76;
  static const double _minSegmentKm = 0.02; // ignore GPS jitter

  StreamSubscription<Position>? _positionSub;
  double? _lastLat;
  double? _lastLng;

  bool _isTracking = false;
  DateTime? _startedAt;
  double _startPercent = 0.0;
  double _currentPercent = 0.0;
  double _distanceCoveredKm = 0.0;
  double _kmPerPercent = _defaultKmPerPercent;

  // ── Today's aggregate totals (survive restarts, reset at midnight) ──
  double _todayDistanceKm = 0.0;
  double _todayEnergyKwh = 0.0;
  DateTime? _todayDate; // the calendar day the above totals belong to
  double _batteryKwh = 60.0; // from vehicle; updated by setBatteryKwh

  bool get isTracking => _isTracking;
  DateTime? get startedAt => _startedAt;
  double get startPercent => _startPercent;
  double get currentPercent => _currentPercent;
  double get distanceCoveredKm => _distanceCoveredKm;
  double get kmPerPercent => _kmPerPercent;

  // Today's aggregates (updated during tracking, reset at midnight)
  double get todayDistanceKm => _todayDistanceKm;
  double get todayEnergyKwh => _todayEnergyKwh;

  /// Real efficiency measured from the session:
  /// distance travelled per kWh of battery actually consumed.
  /// Returns null if there is not enough data yet.
  double? get todayEfficiencyKmPerKwh {
    if (_todayEnergyKwh <= 0.0) return null;
    return _todayDistanceKm / _todayEnergyKwh;
  }

  /// Called from the cockpit when the current vehicle changes.
  /// Updates the battery size used to convert % drops into kWh.
  void setBatteryKwh(double kwh) {
    if (kwh <= 0) return;
    if (_batteryKwh == kwh) return;
    _batteryKwh = kwh;
    notifyListeners();
  }

  void _rollTodayIfNeeded() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_todayDate == null || _todayDate != today) {
      _todayDate = today;
      _todayDistanceKm = 0.0;
      _todayEnergyKwh = 0.0;
    }
  }

  double get drainProgress {
    if (_startPercent <= 0) return 0.0;
    final drained = _startPercent - _currentPercent;
    return (drained / _startPercent).clamp(0.0, 1.0);
  }

  void setKmPerPercent(double value) {
    if (value <= 0) return;
    _kmPerPercent = value;
    notifyListeners();
  }

  Future<void> startTracking(double currentPercent) async {
    _rollTodayIfNeeded();
    _isTracking = true;
    _startedAt = DateTime.now();
    _startPercent = currentPercent.clamp(0.0, 1.0);
    _currentPercent = _startPercent;
    _distanceCoveredKm = 0.0;
    _lastLat = null;
    _lastLng = null;
    notifyListeners();
    await _persist();
    await _attachGps();
  }

  Future<void> pauseTracking() async {
    _isTracking = false;
    await _detachGps();
    notifyListeners();
    await _persist();
  }

  Future<void> updateCurrentPercent(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    _currentPercent = clamped;
    if (_isTracking) {
      _startPercent = clamped;
      _distanceCoveredKm = 0.0;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _attachGps() async {
    await _detachGps();
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(_handlePosition, onError: (_) {});
    } catch (_) {}
  }

  Future<void> _detachGps() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  void _handlePosition(Position pos) {
    if (!_isTracking) return;
    if (_lastLat == null || _lastLng == null) {
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
      return;
    }
    final deltaKm = _haversineKm(
        _lastLat!, _lastLng!, pos.latitude, pos.longitude);
    if (deltaKm < _minSegmentKm) {
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
      return;
    }
    _distanceCoveredKm += deltaKm;
    _lastLat = pos.latitude;
    _lastLng = pos.longitude;

    final drainPercent = _distanceCoveredKm / _kmPerPercent / 100.0;
    _currentPercent = (_startPercent - drainPercent).clamp(0.0, 1.0);

    // ── Update today's aggregates ──
    _rollTodayIfNeeded();
    final deltaKmLocal = deltaKm; // the increment for this GPS tick
    // energy this tick: convert distance to kWh via the vehicle efficiency implied by kmPerPercent.
    // kmPerPercent is km per 1% of battery. 1% = batteryKwh/100 kWh.
    // So kWh per km = (batteryKwh/100) / kmPerPercent.
    final kwhPerKm = (_batteryKwh / 100.0) / _kmPerPercent;
    _todayDistanceKm += deltaKmLocal;
    _todayEnergyKwh += deltaKmLocal * kwhPerKm;

    notifyListeners();
    _persist();
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double d) => d * math.pi / 180.0;

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('battery_tracking_active', _isTracking);
      if (_startedAt != null) {
        await prefs.setInt('battery_tracking_started_at',
            _startedAt!.millisecondsSinceEpoch);
      }
      await prefs.setDouble('battery_tracking_start_pct', _startPercent);
      await prefs.setDouble('battery_tracking_current_pct', _currentPercent);
      await prefs.setDouble('battery_tracking_distance_km', _distanceCoveredKm);
      await prefs.setDouble('battery_tracking_today_distance_km', _todayDistanceKm);
      await prefs.setDouble('battery_tracking_today_energy_kwh', _todayEnergyKwh);
      if (_todayDate != null) {
        await prefs.setString(
            'battery_tracking_today_date', _todayDate!.toIso8601String());
      }
    } catch (_) {}
  }

  Future<void> loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTracking = prefs.getBool('battery_tracking_active') ?? false;
      final startedMs = prefs.getInt('battery_tracking_started_at');
      _startedAt = startedMs != null
          ? DateTime.fromMillisecondsSinceEpoch(startedMs)
          : null;
      _startPercent = prefs.getDouble('battery_tracking_start_pct') ?? 0.0;
      _currentPercent = prefs.getDouble('battery_tracking_current_pct') ?? 0.0;
      _distanceCoveredKm =
          prefs.getDouble('battery_tracking_distance_km') ?? 0.0;
      _todayDistanceKm =
          prefs.getDouble('battery_tracking_today_distance_km') ?? 0.0;
      _todayEnergyKwh =
          prefs.getDouble('battery_tracking_today_energy_kwh') ?? 0.0;
      final dayStr = prefs.getString('battery_tracking_today_date');
      _todayDate = dayStr != null ? DateTime.tryParse(dayStr) : null;
      // Reset today's totals if the calendar day changed while the app was off.
      _rollTodayIfNeeded();
      if (_isTracking) {
        await _attachGps();
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> clear() async {
    _isTracking = false;
    _startedAt = null;
    _startPercent = 0.0;
    _currentPercent = 0.0;
    _distanceCoveredKm = 0.0;
    _todayDistanceKm = 0.0;
    _todayEnergyKwh = 0.0;
    _todayDate = null;
    _lastLat = null;
    _lastLng = null;
    await _detachGps();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('battery_tracking_active');
      await prefs.remove('battery_tracking_started_at');
      await prefs.remove('battery_tracking_start_pct');
      await prefs.remove('battery_tracking_current_pct');
      await prefs.remove('battery_tracking_distance_km');
      await prefs.remove('battery_tracking_today_distance_km');
      await prefs.remove('battery_tracking_today_energy_kwh');
      await prefs.remove('battery_tracking_today_date');
    } catch (_) {}
  }

  @override
  void dispose() {
    _detachGps();
    super.dispose();
  }
}