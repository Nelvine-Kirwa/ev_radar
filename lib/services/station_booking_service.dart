import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/station_booking.dart';

class StationBookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('station_bookings');

  Future<List<StationBooking>> getBookingsForStationOnDay(
    String stationId,
    DateTime day,
  ) async {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    try {
      final snap = await _col
          .where('stationId', isEqualTo: stationId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('startTime', isLessThan: Timestamp.fromDate(dayEnd))
          .where('status', isEqualTo: 'CONFIRMED')
          .get();
      return snap.docs.map(StationBooking.fromFirestore).toList();
    } catch (e) {
      debugPrint('[StationBookingService] getForDay ERROR: $e');
      return [];
    }
  }

  Future<List<StationBooking>> getUserBookings(String userId) async {
    try {
      final snap = await _col
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'CONFIRMED')
          .get();
      final list = snap.docs.map(StationBooking.fromFirestore).toList();
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    } catch (e) {
      debugPrint('[StationBookingService] getUserBookings ERROR: $e');
      return [];
    }
  }

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

  /// Creates a booking using a simple counter to avoid complex query indexes.
  Future<String?> createBookingTransaction({
    required String stationId,
    required String stationName,
    required String userId,
    required String userEmail,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final stationRef = _db.collection('stations').doc(stationId);
      final stationSnap = await stationRef.get();
      if (!stationSnap.exists) return null;
      
      final portsTotal = (stationSnap.data()?['portsTotal'] ?? 2) as int;

      final dateStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final hourStr = start.hour.toString().padLeft(2, '0');
      final slotKey = '${dateStr}_$hourStr';
      
      final slotRef = _db.collection('station_slots').doc('${stationId}_$slotKey');

      final bookingId = await _db.runTransaction<String>((transaction) async {
        final slotSnap = await transaction.get(slotRef);
        int currentCount = 0;
        
        if (slotSnap.exists) {
          currentCount = (slotSnap.data()?['count'] ?? 0) as int;
        }

        if (currentCount >= portsTotal) {
          throw Exception('FULL');
        }

        transaction.set(slotRef, {'count': currentCount + 1, 'stationId': stationId, 'slotKey': slotKey}, SetOptions(merge: true));

        final bookingRef = _col.doc();
        transaction.set(bookingRef, {
          'stationId': stationId,
          'stationName': stationName,
          'userId': userId,
          'userEmail': userEmail,
          'startTime': Timestamp.fromDate(start),
          'endTime': Timestamp.fromDate(end),
          'status': 'CONFIRMED',
          'createdAt': FieldValue.serverTimestamp(),
          'slotKey': slotKey,
        });

        return bookingRef.id;
      });

      return bookingId;
    } catch (e) {
      debugPrint('FIRESTORE ERROR: $e');
      if (e.toString().contains('FULL')) return 'FULL';
      return null;
    }
  }

  Future<StationBooking?> getBookingById(String bookingId) async {
    try {
      final doc = await _col.doc(bookingId).get();
      if (!doc.exists) return null;
      return StationBooking.fromFirestore(doc);
    } catch (e) {
      debugPrint('[StationBookingService] getBookingById ERROR: $e');
      return null;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      final doc = await _col.doc(bookingId).get();
      if (!doc.exists) return false;
      
      final data = doc.data();
      if (data == null) return false;

      final stationId = data['stationId'];
      final slotKey = data['slotKey'];

      if (stationId != null && slotKey != null) {
        final slotRef = _db.collection('station_slots').doc('${stationId}_$slotKey');
        try {
          await _db.runTransaction((transaction) async {
            final slotSnap = await transaction.get(slotRef);
            if (slotSnap.exists) {
              int currentCount = (slotSnap.data()?['count'] ?? 1) as int;
              if (currentCount > 0) {
                transaction.update(slotRef, {'count': currentCount - 1});
              }
            }
          });
        } catch (_) {}
      }

      await _col.doc(bookingId).update({'status': 'CANCELLED'});
      return true;
    } catch (e) {
      debugPrint('[StationBookingService] cancelBooking ERROR: $e');
      return false;
    }
  }

  Future<bool> markExpired(String bookingId) async {
    try {
      await _col.doc(bookingId).update({'status': 'EXPIRED'});
      return true;
    } catch (e) {
      debugPrint('[StationBookingService] markExpired ERROR: $e');
      return false;
    }
  }

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