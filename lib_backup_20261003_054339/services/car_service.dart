import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car.dart';

class CarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Car>> getAllCars() async {
    // Try server with retries (same pattern as station service)
    const delays = [400, 800, 1200, 1600, 2000];
    for (int i = 0; i < delays.length; i++) {
      try {
        final snap = await _db
            .collection('cars')
            .orderBy('displayName')
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map(Car.fromFirestore).toList();
        }
      } catch (_) {}
      if (i < delays.length - 1) {
        await Future.delayed(Duration(milliseconds: delays[i]));
      }
    }

    // Fall back to cache
    try {
      final cacheSnap = await _db
          .collection('cars')
          .orderBy('displayName')
          .get(const GetOptions(source: Source.cache));
      return cacheSnap.docs.map(Car.fromFirestore).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Car?> getCarById(String id) async {
    try {
      final doc = await _db.collection('cars').doc(id).get();
      if (!doc.exists) return null;
      return Car.fromFirestore(doc);
    } catch (_) {
      try {
        final doc = await _db
            .collection('cars')
            .doc(id)
            .get(const GetOptions(source: Source.cache));
        if (!doc.exists) return null;
        return Car.fromFirestore(doc);
      } catch (_) {
        return null;
      }
    }
  }
}