import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class InstallationProvider extends ChangeNotifier {
  final BookingService _service = BookingService();

  List<Booking> _active = [];
  List<Booking> _history = [];
  bool _isLoading = false;
  String? _error;

  List<Booking> get active => _active;
  List<Booking> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActive => _active.isNotEmpty;
  bool get hasHistory => _history.isNotEmpty;

  Future<void> loadForUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[InstallationProvider] Loading for userId: $userId');
      final results = await Future.wait([
        _service.getActiveForUser(userId),
        _service.getHistoryForUser(userId),
      ]);
      _active = results[0];
      _history = results[1];
      debugPrint('[InstallationProvider] Active: ${_active.length}, History: ${_history.length}');
    } catch (e) {
      _error = e.toString();
      debugPrint('[InstallationProvider] ERROR: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String userId) async {
    await loadForUser(userId);
  }

  Future<bool> cancelBooking(String bookingId, String userId) async {
    final ok = await _service.cancelBooking(bookingId);
    if (ok) {
      await refresh(userId);
    }
    return ok;
  }
  void clear() {
    _active = [];
    _history = [];
    notifyListeners();
  }
}