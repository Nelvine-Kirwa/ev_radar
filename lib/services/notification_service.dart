import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_item.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? relatedBookingId,
  }) async {
    try {
      await _db.collection('notifications').add({
        'recipientId': recipientId,
        'type': type,
        'title': title,
        'body': body,
        'relatedBookingId': relatedBookingId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  Future<void> notifyBookingConfirmed({
    required String userId,
    required String equipmentName,
    required String electricianName,
    required String address,
    required String bookingId,
    bool isChargingSlot = false,
  }) async {
    try {
      final message = isChargingSlot
          ? 'Your charging slot at ${equipmentName} is booked for ${address}.'
          : 'Your ${equipmentName} installation at ${address} is scheduled. ${electricianName} will contact you within 24 hours.';

      await createNotification(
        recipientId: userId,
        type: 'BOOKING_CONFIRMED',
        title: 'Booking Confirmed',
        body: message,
        relatedBookingId: bookingId,
      );
    } catch (_) {}
  }

  Future<void> notifyBookingCancelled({
    required String userId,
    required String equipmentName,
    required String address,
    required String bookingId,
  }) async {
    try {
      await createNotification(
        recipientId: userId,
        type: 'BOOKING_CANCELLED_BY_USER',
        title: 'Booking Cancelled',
        body: 'Your $equipmentName booking at $address has been cancelled.',
        relatedBookingId: bookingId,
      );
    } catch (_) {}
  }

  /// One-shot fetch used by pull-to-refresh
  Future<List<NotificationItem>> getForUser(String userId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snap.docs.map((doc) => NotificationItem.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({'read': true});
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _db.batch();
      final snapshot = await _db
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }
}