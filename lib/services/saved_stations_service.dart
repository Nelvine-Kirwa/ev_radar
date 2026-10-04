import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Handles saving stations (per-user) and liking stations (aggregate count).
class SavedStationsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- SAVED STATIONS ----------

  /// Returns the list of station ids the user has saved.
  Future<List<String>> getSavedStationIds(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return [];
      final list = (doc.data()?['savedStations'] as List?) ?? [];
      return list.cast<String>();
    } catch (e) {
      debugPrint('[SavedStationsService] getSaved ERROR: $e');
      return [];
    }
  }

    /// Replaces the entire savedStations list with the given IDs.
  /// This is atomic (single write) and avoids read-modify-write races.
  Future<bool> setSavedIds(String uid, List<String> ids) async {
    debugPrint('[SavedStationsService] setSavedIds uid=$uid ids=$ids');
    try {
      await _db.collection('users').doc(uid).set(
        {'savedStations': ids},
        SetOptions(merge: true),
      );
      debugPrint('[SavedStationsService] setSavedIds write OK');
      return true;
    } catch (e, st) {
      debugPrint('[SavedStationsService] setSavedIds ERROR: $e');
      debugPrint('[SavedStationsService] stack: $st');
      return false;
    }
  }

  // ---------- LIKES ----------

  /// Toggle a like on a station. Updates both the aggregate count and
  /// the likedBy list atomically.
  Future<void> toggleLike(String stationId, String uid) async {
    final ref = _db.collection('stations').doc(stationId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;

        final data = snap.data() ?? {};
        final likedBy =
            ((data['likedBy'] as List?) ?? []).cast<String>().toList();
        int likeCount = (data['likeCount'] as int?) ?? 0;

        if (likedBy.contains(uid)) {
          likedBy.remove(uid);
          likeCount = (likeCount - 1).clamp(0, 999999);
        } else {
          likedBy.add(uid);
          likeCount = likeCount + 1;
        }

        tx.update(ref, {'likeCount': likeCount, 'likedBy': likedBy});
      });
    } catch (e) {
      debugPrint('[SavedStationsService] toggleLike ERROR: $e');
    }
  }

  /// Fetch like count + whether this user has liked a station.
  Future<Map<String, dynamic>> getLikeStats(
      String stationId, String? uid) async {
    try {
      final doc = await _db.collection('stations').doc(stationId).get();
      if (!doc.exists) return {'likeCount': 0, 'likedByMe': false};
      final data = doc.data() ?? {};
      final likedBy =
          ((data['likedBy'] as List?) ?? []).cast<String>();
      return {
        'likeCount': (data['likeCount'] as int?) ?? likedBy.length,
        'likedByMe': uid != null && likedBy.contains(uid),
      };
    } catch (e) {
      debugPrint('[SavedStationsService] getLikeStats ERROR: $e');
      return {'likeCount': 0, 'likedByMe': false};
    }
  }
}