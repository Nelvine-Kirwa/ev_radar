import 'package:flutter/foundation.dart';
import '../models/station_booking.dart';
import '../services/station_booking_service.dart';

class StationBookingProvider extends ChangeNotifier {
  final StationBookingService _service = StationBookingService();

  // Bookings for the currently-open station on the selected day
  List<StationBooking> _dayBookings = [];
  DateTime _selectedDay = DateTime.now();

  // The current user's own bookings
  List<StationBooking> _myBookings = [];

  // Station ids with an active CONFIRMED booking right now.
  Set<String> _busyStationIds = {};

  bool _loading = false;
  String? _error;

  List<StationBooking> get dayBookings => _dayBookings;
  DateTime get selectedDay => _selectedDay;
  List<StationBooking> get myBookings => _myBookings;
  bool get loading => _loading;
  Set<String> get busyStationIds => _busyStationIds;
  bool isStationBusy(String stationId) => _busyStationIds.contains(stationId);
  String? get error => _error;

  /// Fetches the set of stations that are BUSY right now (active booking).
  /// Called by StationsScreen on tab open and after each booking.
  Future<void> refreshBusyStations() async {
    final ids = await _service.getBusyStationIds(DateTime.now());
    _busyStationIds = ids;
    notifyListeners();
  }

  void setSelectedDay(DateTime d) {
    _selectedDay = DateTime(d.year, d.month, d.day);
    notifyListeners();
  }

  /// Load bookings for a station on [_selectedDay].
  Future<void> loadForStationOnDay(String stationId, DateTime day) async {
    _selectedDay = DateTime(day.year, day.month, day.day);
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _dayBookings = await _service.getBookingsForStationOnDay(
        stationId,
        _selectedDay,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load user's upcoming bookings.
  Future<void> loadMyBookings(String userId) async {
    try {
      _myBookings = await _service.getUserBookings(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('[StationBookingProvider] loadMy ERROR: $e');
    }
  }

  void clear() {
    _dayBookings = [];
    _myBookings = [];
    notifyListeners();
  }

  /// True if [slotStart, slotEnd] is taken by an existing booking.
  bool isSlotTaken(DateTime slotStart, DateTime slotEnd) {
    for (final b in _dayBookings) {
      // Overlap test
      if (b.startTime.isBefore(slotEnd) && b.endTime.isAfter(slotStart)) {
        return true;
      }
    }
    return false;
  }

  /// True if the given slot is in the past.
  bool isSlotPast(DateTime slotStart) {
    return slotStart.isBefore(DateTime.now());
  }

  /// Book a slot. Returns the new booking id, or null if it failed
  /// (e.g. conflict — checked again on the server just before writing).
  Future<String?> bookSlot({
    required String stationId,
    required String stationName,
    required String userId,
    required String userEmail,
    required DateTime start,
    required DateTime end,
  }) async {
    // Client-side check
    if (isSlotTaken(start, end)) {
      _error = 'That slot was just taken. Pick another.';
      notifyListeners();
      return null;
    }
    // Server-side check (race protection)
    final conflict = await _service.findConflict(
      stationId: stationId,
      start: start,
      end: end,
    );
    if (conflict != null) {
      _error = 'That slot was just taken. Pick another.';
      notifyListeners();
      // Refresh grid
      await loadForStationOnDay(stationId, _selectedDay);
      return null;
    }

    final id = await _service.createBooking(
      stationId: stationId,
      stationName: stationName,
      userId: userId,
      userEmail: userEmail,
      start: start,
      end: end,
    );
    if (id != null) {
      await loadForStationOnDay(stationId, _selectedDay);
      await loadMyBookings(userId);
    } else {
      _error = 'Could not create booking. Try again.';
      notifyListeners();
    }
    return id;
  }

  Future<bool> cancelBooking(String bookingId, String userId) async {
    final ok = await _service.cancelBooking(bookingId);
    if (ok) {
      await loadMyBookings(userId);
    }
    return ok;
  }

  /// Client-side expiry sweep (no Cloud Function needed).
  Future<void> expireStaleBookings(String userId) async {
    await _service.expireStaleBookingsForUser(userId);
    await loadMyBookings(userId);
  }
}