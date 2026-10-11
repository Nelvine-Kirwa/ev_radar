import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles per-booking technician ratings.
///
/// Document id is deterministic: `${bookingId}_${raterId}` — a user can
/// rate the same booking only once (repeat submits overwrite).
class RatingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> hasRated(String bookingId, String raterId) async {
    final doc = await _db
        .collection('ratings')
        .doc('${bookingId}_$raterId')
        .get();
    return doc.exists;
  }

  Future<int> getUserStars(String bookingId, String raterId) async {
    final doc = await _db
        .collection('ratings')
        .doc('${bookingId}_$raterId')
        .get();
    return (doc.data()?['stars'] as num?)?.toInt() ?? 0;
  }

  Future<void> submitRating({
    required String bookingId,
    required String technicianName,
    required String raterId,
    required int stars,
  }) async {
    if (stars < 1 || stars > 5) {
      throw ArgumentError('stars must be between 1 and 5');
    }
    await _db.collection('ratings').doc('${bookingId}_$raterId').set({
      'bookingId': bookingId,
      'technicianName': technicianName,
      'raterId': raterId,
      'stars': stars,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}