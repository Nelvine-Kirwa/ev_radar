import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('notifications');

  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? relatedBookingId,
  }) async {
    try {
      await _col.add({
        'recipientId': recipientId,
        'type': type,
        'title': title,
        'body': body,
        if (relatedBookingId != null) 'relatedBookingId': relatedBookingId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[NotificationService] Create ERROR: $e');
    }
  }

  Future<List<NotificationItem>> getForUser(String userId) async {
    try {
      final snap = await _col
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snap.docs.map((d) => NotificationItem.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('[NotificationService] Query ERROR: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _col.doc(notificationId).update({'read': true});
    } catch (e) {
      debugPrint('[NotificationService] Mark read ERROR: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final snap = await _col
          .where('recipientId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[NotificationService] Mark all read ERROR: $e');
    }
  }
}