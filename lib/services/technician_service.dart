import 'package:cloud_firestore/cloud_firestore.dart';

/// Single source of truth for approved technicians, their real
/// completed-installation counts, and their aggregate star rating.
class TechnicianService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Loads every user with role == 'technician', counts COMPLETED
  /// bookings by `electricianName`, and computes the average rating
  /// from the `ratings` collection.
  ///
  /// Returns a list of maps sorted by `installations` (descending):
  ///   { name, license, rating, ratingCount, installations }
  Future<List<Map<String, dynamic>>> loadApprovedWithCounts() async {
    final techSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'technician')
        .get();

    final doneSnap = await _db
        .collection('bookings')
        .where('status', isEqualTo: 'COMPLETED')
        .get();

    // Aggregate ratings by technician name.
    final ratingAgg = <String, List<int>>{};
    try {
      final ratingSnap = await _db.collection('ratings').get();
      for (final d in ratingSnap.docs) {
        final name = (d.data()['technicianName'] ?? '').toString();
        final stars = (d.data()['stars'] as num?)?.toInt() ?? 0;
        if (name.isEmpty || stars < 1 || stars > 5) continue;
        (ratingAgg[name] ??= []).add(stars);
      }
    } catch (_) {
      // Ratings collection may not exist yet — fine, fall back to 0.
    }

    // Count COMPLETED bookings per technician.
    final counts = <String, int>{};
    for (final d in doneSnap.docs) {
      final n = (d.data()['electricianName'] ?? '').toString();
      if (n.isEmpty) continue;
      counts[n] = (counts[n] ?? 0) + 1;
    }

    final list = techSnap.docs.where((d) {
      // Skip suspended technicians.
      final data = d.data();
      if (data['suspended'] == true) return false;
      return true;
    }).map((d) {
      final data = d.data();
      final name = (data['name'] ?? '').toString();

      // Try every plausible field name for the EPRA license.
      final license = (data['epraLicense']
              ?? data['license']
              ?? data['epraNumber']
              ?? data['permitOrLicense']
              ?? '')
          .toString()
          .trim();

      final ratings = ratingAgg[name] ?? const <int>[];
      final avgRating = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;

      return <String, dynamic>{
        'name': name,
        'license': license.isEmpty ? 'EPRA pending' : license,
        'rating': avgRating,
        'ratingCount': ratings.length,
        'installations': counts[name] ?? 0,
      };
    }).where((t) => (t['name'] as String).isNotEmpty).toList()
      ..sort((a, b) =>
          (b['installations'] as int).compareTo(a['installations'] as int));

    return list;
  }
}