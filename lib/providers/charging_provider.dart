import 'package:flutter/material.dart';

class ChargingProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _stations = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get stations => _stations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNearbyStations(double lat, double lng) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: integrate Open Charge Map API in Chapter 3
      await Future.delayed(const Duration(milliseconds: 500));
      _stations = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}