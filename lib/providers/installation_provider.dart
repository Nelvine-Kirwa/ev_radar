import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class InstallationProvider extends ChangeNotifier {
  final BookingService _service = BookingService();

  List<Booking> _active = [];
  List<Booking> _history = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String _lastUserId = '';

  List<Booking> get active => _active;
  List<Booking> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActive => _active.isNotEmpty;
  bool get hasHistory => _history.isNotEmpty;

  /// One-shot fetch (used at splash and after login).
  Future<void> loadForUser(String userId) async {
    if (userId.isEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[InstallationProvider] loadForUser: $userId');
      final results = await Future.wait([
        _service.getActiveForUser(userId),
        _service.getHistoryForUser(userId),
      ]);
      _active = results[0];
      _history = results[1];
      debugPrint(
          '[InstallationProvider] Active: ${_active.length}, History: ${_history.length}');
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

  /// Live stream — every Firestore change to the user's bookings triggers
  /// a rebuild. Call when the Services tab opens.
  void subscribeForUser(String userId) {
    if (userId.isEmpty) return;
    if (_lastUserId == userId && _subscription != null) {
      // Already listening for this user.
      return;
    }
    _subscription?.cancel();
    _lastUserId = userId;

    _isLoading = true;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        final all =
            snap.docs.map((d) => Booking.fromFirestore(d)).toList();
        const activeStatuses = ['PENDING', 'SCHEDULED', 'IN_PROGRESS'];
        const pastStatuses = ['COMPLETED', 'CANCELLED'];
        _active =
            all.where((b) => activeStatuses.contains(b.status)).toList();
        _history =
            all.where((b) => pastStatuses.contains(b.status)).toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
        debugPrint(
            '[InstallationProvider] Snapshot: active=${_active.length}, history=${_history.length}');
      },
      onError: (e) {
        _isLoading = false;
        _error = e.toString();
        debugPrint('[InstallationProvider] Stream error: $e');
        notifyListeners();
      },
    );
  }

  void unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    _lastUserId = '';
  }

  Future<bool> cancelBooking(String bookingId, String userId) async {
    final ok = await _service.cancelBooking(bookingId);
    if (ok) {
      // If we're not streaming, do a one-shot refresh.
      if (_subscription == null) {
        await refresh(userId);
      }
    }
    return ok;
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _lastUserId = '';
    _active = [];
    _history = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}