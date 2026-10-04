import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/station_booking.dart';

/// Handles station slot bookings in Firestore.
///
/// Data shape: station_bookings/{bookingId} ->
///   stationId, stationName, userId, userEmail,
///   startTime, endTime, status, createdAt
class StationBookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('station_bookings');

  /// Returns confirmed bookings for a station on a given day.
  /// Used to render the slot grid (green/red).
  Future<List<StationBooking>> getBookingsForStationOnDay(
    String stationId,
    DateTime day,
  ) async {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    try {
      final snap = await _col
          .where('stationId', isEqualTo: stationId)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('startTime', isLessThan: Timestamp.fromDate(dayEnd))
          .where('status', isEqualTo: 'CONFIRMED')
          .get();
      return snap.docs.map(StationBooking.fromFirestore).toList();
    } catch (e) {
      debugPrint('[StationBookingService] getForDay ERROR: $e');
      return [];
    }
  }

  /// Returns a user's own upcoming + active bookings.
  Future<List<StationBooking>> getUserBookings(String userId) async {
    try {
      final snap = await _col
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'CONFIRMED')
          .orderBy('startTime')
          .get();
      return snap.docs.map(StationBooking.fromFirestore).toList();
    } catch (e) {
      debugPrint('[StationBookingService] getUserBookings ERROR: $e');
      return [];
    }
  }

  /// Returns whether a specific station is busy *right now*.
  /// Used for the "Busy" indicator on list/map.
  Future<StationBooking?> getActiveBookingForStation(
      String stationId, DateTime now) async {
    try {
      final snap = await _col
          .where('stationId', isEqualTo: stationId)
          .where('status', isEqualTo: 'CONFIRMED')
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endTime', isGreaterThan: Timestamp.fromDate(now))
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return StationBooking.fromFirestore(snap.docs.first);
    } catch (e) {
      debugPrint('[StationBookingService] getActive ERROR: $e');
      return null;
    }
  }

  /// Checks whether [start]–[end] conflicts with any existing booking.
  /// Returns the conflicting booking if any, or null.
  Future<StationBooking?> findConflict({
    required String stationId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // Overlap: existing.start < new.end AND existing.end > new.start
      final snap = await _col
          .where('stationId', isEqualTo: stationId)
          .where('status', isEqualTo: 'CONFIRMED')
          .where('startTime', isLessThan: Timestamp.fromDate(end))
          .where('endTime', isGreaterThan: Timestamp.fromDate(start))
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return StationBooking.fromFirestore(snap.docs.first);
    } catch (e) {
      debugPrint('[StationBookingService] findConflict ERROR: $e');
      return null;
    }
  }

  /// Creates a new booking. Returns the booking id, or null on failure.
  Future<String?> createBooking({
    required String stationId,
    required String stationName,
    required String userId,
    required String userEmail,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final ref = await _col.add({
        'stationId': stationId,
        'stationName': stationName,
        'userId': userId,
        'userEmail': userEmail,
        'startTime': Timestamp.fromDate(start),
        'endTime': Timestamp.fromDate(end),
        'status': 'CONFIRMED',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      debugPrint('[StationBookingService] createBooking ERROR: $e');
      return null;
    }
  }

  /// Cancels a booking (owner only — enforced in rules).
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _col.doc(bookingId).update({'status': 'CANCELLED'});
      return true;
    } catch (e) {
      debugPrint('[StationBookingService] cancelBooking ERROR: $e');
      return false;
    }
  }

  /// Marks a booking as EXPIRED (client-side cleanup).
  Future<bool> markExpired(String bookingId) async {
    try {
      await _col.doc(bookingId).update({'status': 'EXPIRED'});
      return true;
    } catch (e) {
      debugPrint('[StationBookingService] markExpired ERROR: $e');
      return false;
    }
  }

  /// Returns a Set of stationIds that are BUSY right now
  /// (i.e. have a CONFIRMED booking covering the current moment).
  /// Used by the Stations list to reflect real availability.
  Future<Set<String>> getBusyStationIds(DateTime now) async {
    try {
      final snap = await _col
          .where('status', isEqualTo: 'CONFIRMED')
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endTime', isGreaterThan: Timestamp.fromDate(now))
          .get();
      return snap.docs
          .map((d) => d.data()['stationId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('[StationBookingService] getBusyStationIds ERROR: $e');
      return <String>{};
    }
  }

  /// Scans the user's CONFIRMED bookings and marks expired ones.
  /// Called on app open (Station tab entry / splash) since we don't
  /// have a Cloud Function for scheduled expiry.
  Future<void> expireStaleBookingsForUser(String userId) async {
    final now = DateTime.now();
    try {
      final snap = await _col
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'CONFIRMED')
          .get();
      final batch = _db.batch();
      bool any = false;
      for (final doc in snap.docs) {
        final b = StationBooking.fromFirestore(doc);
        if (b.isExpiredBy(now)) {
          batch.update(doc.reference, {'status': 'EXPIRED'});
          any = true;
        }
      }
      if (any) await batch.commit();
    } catch (e) {
      debugPrint('[StationBookingService] expireStale ERROR: $e');
    }
  }
}