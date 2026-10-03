import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String id;
  final String recipientId;
  final String type; // NEW_BOOKING, BOOKING_CANCELLED, SYSTEM
  final String title;
  final String body;
  final String? relatedBookingId;
  final bool read;
  final DateTime? createdAt;

  const NotificationItem({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedBookingId,
    required this.read,
    this.createdAt,
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationItem(
      id: doc.id,
      recipientId: d['recipientId'] ?? '',
      type: d['type'] ?? 'SYSTEM',
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      relatedBookingId: d['relatedBookingId'],
      read: d['read'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}