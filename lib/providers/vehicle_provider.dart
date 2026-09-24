import 'package:flutter/material.dart';
import '../models/car.dart';
import '../models/user_vehicle.dart';
import '../services/car_service.dart';

class VehicleProvider extends ChangeNotifier {
  final CarService _carService = CarService();

  // All 40 cars available in the app catalog
  List<Car> _availableCars = [];
  bool _loadingCatalog = false;
  String? _catalogError;

  // The user's saved vehicles
  List<UserVehicle> _userVehicles = [];
  int _currentVehicleIndex = 0;

  // Cached details of the currently selected car
  Car? _currentCar;

  // Battery level (0.0 - 1.0) — user-set or simulated until GPS is wired
  double _batteryLevel = 0.78;
  bool _isTracking = false;

  List<Car> get availableCars => _availableCars;
  bool get loadingCatalog => _loadingCatalog;
  String? get catalogError => _catalogError;

  List<UserVehicle> get userVehicles => _userVehicles;
  int get currentVehicleIndex => _currentVehicleIndex;
  Car? get currentCar => _currentCar;
  UserVehicle? get currentUserVehicle =>
      _userVehicles.isEmpty ? null : _userVehicles[_currentVehicleIndex];

  double get batteryLevel => _batteryLevel;
  bool get isTracking => _isTracking;

  bool get isLowBattery => _batteryLevel <= 0.25;
  bool get isCriticalBattery => _batteryLevel <= 0.15;

  /// Range in km based on current vehicle and battery level
  double get rangeKm {
    final car = _currentCar;
    if (car != null) return car.rangeAt(_batteryLevel);
    // Fallback if no car is selected yet
    return _batteryLevel * 376;
  }

  /// Max range at 100% for the current car (fallback 376)
  double get maxRangeKm => _currentCar?.rangeKm.toDouble() ?? 376;

  /// Catalog loading
  Future<void> loadAvailableCars() async {
    _loadingCatalog = true;
    _catalogError = null;
    notifyListeners();

    try {
      _availableCars = await _carService.getAllCars();
      if (_availableCars.isEmpty) {
        _catalogError = 'No cars in catalog';
      }
    } catch (e) {
      _catalogError = e.toString();
    } finally {
      _loadingCatalog = false;
      notifyListeners();
    }
  }

  /// Set the user's vehicle list (usually loaded from Firestore user doc)
  void setUserVehicles(List<UserVehicle> vehicles, {int index = 0}) {
    _userVehicles = vehicles;
    _currentVehicleIndex = index;
    _syncCurrentCar();
    notifyListeners();
  }

  void addUserVehicle(UserVehicle vehicle) {
    _userVehicles.add(vehicle);
    if (_userVehicles.length == 1) _currentVehicleIndex = 0;
    _syncCurrentCar();
    notifyListeners();
  }

  void removeUserVehicle(int index) {
    if (index < 0 || index >= _userVehicles.length) return;
    _userVehicles.removeAt(index);
    if (_currentVehicleIndex >= _userVehicles.length) {
      _currentVehicleIndex = _userVehicles.isEmpty ? 0 : _userVehicles.length - 1;
    }
    _syncCurrentCar();
    notifyListeners();
  }

  void switchVehicle(int index) {
    if (index < 0 || index >= _userVehicles.length) return;
    _currentVehicleIndex = index;
    _syncCurrentCar();
    notifyListeners();
  }

  void updateBattery(double level) {
    _batteryLevel = level.clamp(0.0, 1.0);
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

  /// Looks up the Car for the current user vehicle and stores it
  void _syncCurrentCar() {
    if (_userVehicles.isEmpty) {
      _currentCar = null;
      return;
    }
    final id = _userVehicles[_currentVehicleIndex].carId;
    try {
      _currentCar = _availableCars.firstWhere((c) => c.id == id);
    } catch (_) {
      _currentCar = null;
    }
  }
}