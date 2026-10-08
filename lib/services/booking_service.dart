import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/equipment.dart';

class BookingService {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('bookings');

  Future<String?> createBooking({
    required String userId,
    required String userEmail,
    required Equipment equipment,
    required String electricianName,
    required double electricianRating,
    required String address,
    required int bookingFeeKsh,
    required String userPhone,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final ref = await _col.add({
        'userId': userId,
        'userEmail': userEmail,
        'equipmentName': equipment.name,
        'equipmentCategory': equipment.category,
        'equipmentImage': equipment.imagePath,
        'equipmentPriceKsh': equipment.priceKsh,
        'electricianName': electricianName,
        'electricianRating': electricianRating,
        'address': address,
        'userPhone': userPhone,
        'status': 'SCHEDULED',
        'bookingFeeKsh': bookingFeeKsh,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      return null;
    }
  }

  /// Returns the most recent booking for the given user, or null.
  Future<Booking?> getLatestForUser(String userId) async {
    try {
      final snap = await _col
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      return Booking.fromFirestore(snap.docs.first);
    } catch (e) {
      print('Error fetching latest booking: $e');
      return null;
    }
  }

  /// All bookings for a user, most recent first.
  ///
  /// Reads from the server first so recent status changes (like a
  /// technician marking a job IN_PROGRESS or COMPLETED) show up
  /// without needing a full logout. Falls back to cache if the
  /// server is unreachable.
  Future<List<Booking>> getAllForUser(String userId) async {
    try {
      debugPrint('[BookingService] Querying bookings for userId: $userId (server)');
      final snap = await _col
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server));
      debugPrint('[BookingService] Got ${snap.docs.length} docs (server)');
      return snap.docs.map((d) => Booking.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('[BookingService] Server read failed, falling back to cache: $e');
      try {
        final cacheSnap = await _col
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get(const GetOptions(source: Source.cache));
        return cacheSnap.docs.map((d) => Booking.fromFirestore(d)).toList();
      } catch (cacheErr) {
        debugPrint('[BookingService] Cache read failed too: $cacheErr');
        return [];
      }
    }
  }

  /// Active bookings: PENDING + SCHEDULED + IN_PROGRESS
  Future<List<Booking>> getActiveForUser(String userId) async {
    final all = await getAllForUser(userId);
    const activeStatuses = ['PENDING', 'SCHEDULED', 'IN_PROGRESS'];
    return all.where((b) => activeStatuses.contains(b.status)).toList();
  }

  /// Set a booking status to CANCELLED. Called by the owner only.
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _col.doc(bookingId).update({'status': 'CANCELLED'});
      return true;
    } catch (e) {
      debugPrint('[BookingService] Cancel ERROR: $e');
      return false;
    }
  }
  /// Past bookings: COMPLETED + CANCELLED
  Future<List<Booking>> getHistoryForUser(String userId) async {
    final all = await getAllForUser(userId);
    const pastStatuses = ['COMPLETED', 'CANCELLED'];
    return all.where((b) => pastStatuses.contains(b.status)).toList();
  }
}