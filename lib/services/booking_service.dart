import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../models/equipment.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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
        'status': 'SCHEDULED',
        'bookingFeeKsh': bookingFeeKsh,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      print('Error creating booking: $e');
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
}