import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class UserLocationProvider extends ChangeNotifier {
  Position? _position;
  bool _loading = false;
  String? _error;
  bool _permissionDenied = false;

  Position? get position => _position;
  double? get lat => _position?.latitude;
  double? get lng => _position?.longitude;
  bool get loading => _loading;
  String? get error => _error;
  bool get permissionDenied => _permissionDenied;
  bool get hasLocation => _position != null;

  Future<void> ensureLoaded() async {
    if (_position != null || _loading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final pos = await LocationService().getCurrentLocation();
      if (pos == null) {
        _permissionDenied = true;
        _error = 'Location permission denied';
      } else {
        _position = pos;
        _permissionDenied = false;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}