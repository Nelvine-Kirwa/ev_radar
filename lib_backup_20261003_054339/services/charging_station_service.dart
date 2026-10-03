import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/charging_station.dart';

class ChargingStationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<ChargingStation?> getById(String id) async {
    try {
      final doc = await _db.collection('stations').doc(id).get();
      if (!doc.exists) return null;
      return ChargingStation.fromFirestore(doc);
    } catch (e) {
      try {
        final doc = await _db
            .collection('stations')
            .doc(id)
            .get(const GetOptions(source: Source.cache));
        if (doc.exists) return ChargingStation.fromFirestore(doc);
      } catch (_) {}
      rethrow;
    }
  }

  Future<ChargingStation?> getFirst() async {
    try {
      final snap = await _db.collection('stations').limit(1).get();
      if (snap.docs.isNotEmpty) {
        return ChargingStation.fromFirestore(snap.docs.first);
      }
    } catch (_) {}

    try {
      final cache = await _db
          .collection('stations')
          .limit(1)
          .get(const GetOptions(source: Source.cache));
      if (cache.docs.isNotEmpty) {
        return ChargingStation.fromFirestore(cache.docs.first);
      }
    } catch (_) {}

    return null;
  }

  /// Loads all stations with multi-attempt server retries and cache fallback.
  Future<List<ChargingStation>> getAll() async {
    // Try server up to 5 times with increasing backoff
    const delays = [400, 800, 1200, 1600, 2000, 2400, 2800, 3200, 3600, 4000];
    for (int i = 0; i < delays.length; i++) {
      try {
        final snap = await _db.collection('stations').get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map(ChargingStation.fromFirestore).toList();
        }
        // Empty response â€” treat as failure, retry
      } catch (_) {
        // Fall through to retry
      }
      if (i < delays.length - 1) {
        await Future.delayed(Duration(milliseconds: delays[i]));
      }
    }

    // All server attempts failed â€” fall back to cache
    try {
      final cacheSnap = await _db
          .collection('stations')
          .get(const GetOptions(source: Source.cache));
      return cacheSnap.docs.map(ChargingStation.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ChargingStation>> getFromCacheFirst() async {
    try {
      final cacheSnap = await _db
          .collection('stations')
          .get(const GetOptions(source: Source.cache));
      return cacheSnap.docs.map(ChargingStation.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ChargingStation>> getFromServer() async {
    final snap = await _db
        .collection('stations')
        .get(const GetOptions(source: Source.server));
    return snap.docs.map(ChargingStation.fromFirestore).toList();
  }

  Future<List<ChargingStation>> getByNeighborhood(String neighborhood) async {
    try {
      final snap = await _db
          .collection('stations')
          .where('neighborhood', isEqualTo: neighborhood)
          .get();
      return snap.docs.map(ChargingStation.fromFirestore).toList();
    } catch (e) {
      return [];
    }
  }
}