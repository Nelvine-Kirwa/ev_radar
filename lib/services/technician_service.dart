import 'package:cloud_firestore/cloud_firestore.dart';

/// Single source of truth for approved technicians and their
/// real completed-installation counts.
///
/// Replaces the old hardcoded list in equipment_data.dart and the
/// per-technician N+1 queries that both the inline picker and the
/// See-all screen used to run independently.
class TechnicianService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Loads every user with role == 'technician', then counts COMPLETED
  /// bookings by `electricianName`. Two queries total, no matter how
  /// many technicians exist.
  ///
  /// Returns a list of maps sorted by `installations` (descending):
  ///   { name, license, rating, installations }
  Future<List<Map<String, dynamic>>> loadApprovedWithCounts() async {
    final techSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'technician')
        .get();

    final doneSnap = await _db
        .collection('bookings')
        .where('status', isEqualTo: 'COMPLETED')
        .get();

    final counts = <String, int>{};
    for (final d in doneSnap.docs) {
      final n = (d.data()['electricianName'] ?? '').toString();
      if (n.isEmpty) continue;
      counts[n] = (counts[n] ?? 0) + 1;
    }

    final list = techSnap.docs.map((d) {
      final data = d.data();
      final name = (data['name'] ?? '').toString();
      return <String, dynamic>{
        'name': name,
        'license': (data['epraLicense'] ?? 'EPRA pending').toString(),
        'rating': 5.0,
        'installations': counts[name] ?? 0,
      };
    }).where((t) => (t['name'] as String).isNotEmpty).toList()
      ..sort((a, b) =>
          (b['installations'] as int).compareTo(a['installations'] as int));

    return list;
  }
}
