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
      print('Error fetching station $id: $e');
      return null;
    }
  }

  Future<ChargingStation?> getFirst() async {
    try {
      final snap = await _db.collection('stations').limit(1).get();
      if (snap.docs.isEmpty) return null;
      return ChargingStation.fromFirestore(snap.docs.first);
    } catch (e) {
      print('Error fetching first station: $e');
      return null;
    }
  }

  Future<List<ChargingStation>> getAll() async {
    try {
      final snap = await _db.collection('stations').get();
      return snap.docs
          .map((doc) => ChargingStation.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching stations: $e');
      return [];
    }
  }

  Future<List<ChargingStation>> getByNeighborhood(String neighborhood) async {
    try {
      final snap = await _db
          .collection('stations')
          .where('neighborhood', isEqualTo: neighborhood)
          .get();
      return snap.docs
          .map((doc) => ChargingStation.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching stations in $neighborhood: $e');
      return [];
    }
  }
}