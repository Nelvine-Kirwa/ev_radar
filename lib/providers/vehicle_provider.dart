import 'package:flutter/material.dart';
import '../utils/constants.dart';

class VehicleProvider extends ChangeNotifier {
  double _batteryLevel = 0.8; // 80% default
  double _rangeKm = VehicleDefaults.maxRangeKm;
  bool _isTracking = false;

  double get batteryLevel => _batteryLevel;
  double get rangeKm => _rangeKm;
  bool get isTracking => _isTracking;

  bool get isLowBattery => _batteryLevel <= lowBatteryThreshold;
  bool get isCriticalBattery => _batteryLevel <= criticalBatteryThreshold;

  void updateBattery(double level) {
    _batteryLevel = level.clamp(0.0, 1.0);
    _rangeKm = _batteryLevel * VehicleDefaults.maxRangeKm;
    notifyListeners();
  }

  void startTracking() {
    _isTracking = true;
    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }
}