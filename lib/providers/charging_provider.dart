import 'package:flutter/material.dart';
import '../models/charging_station.dart';
import '../services/charging_station_service.dart';

class ChargingProvider extends ChangeNotifier {
  final ChargingStationService _service = ChargingStationService();

  ChargingStation? _currentStation;
  List<ChargingStation> _stations = [];
  bool _isLoading = false;
  String? _error;

  ChargingStation? get currentStation => _currentStation;
  List<ChargingStation> get stations => _stations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStationById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentStation = await _service.getById(id);
      if (_currentStation == null) {
        _error = 'Station not found';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFirstStation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentStation = await _service.getFirst();
      if (_currentStation == null) {
        _error = 'No stations found';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllStations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stations = await _service.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentStation() {
    _currentStation = null;
    notifyListeners();
  }
}