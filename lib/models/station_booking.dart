import 'package:cloud_firestore/cloud_firestore.dart';

/// A user's booking for a charging slot at a station.
///
/// A booking covers a contiguous time range — the app uses 1-hour slots,
/// so [startTime] and [endTime] are always whole hours, but the model
/// itself doesn't enforce that.
class StationBooking {
  final String id;
  final String stationId;
  final String stationName;
  final String userId;
  final String userEmail;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // CONFIRMED, CANCELLED, EXPIRED, COMPLETED
  final DateTime? createdAt;

  const StationBooking({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.userId,
    required this.userEmail,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.createdAt,
  });

  bool get isCancellable => status == 'CONFIRMED';

  /// True if `now` is within [startTime, endTime).
  bool isCurrentlyActive(DateTime now) {
    return status == 'CONFIRMED' &&
        now.isAfter(startTime) &&
        now.isBefore(endTime);
  }

  /// True if this booking's expiry window has passed.
  /// A user must arrive within 35 minutes of [startTime] or the booking
  /// auto-expires. In this app expiry is evaluated client-side.
  bool isExpiredBy(DateTime now) {
    if (status != 'CONFIRMED') return false;
    return now.isAfter(startTime.add(const Duration(minutes: 35)));
  }

  factory StationBooking.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StationBooking(
      id: doc.id,
      stationId: d['stationId'] ?? '',
      stationName: d['stationName'] ?? '',
      userId: d['userId'] ?? '',
      userEmail: d['userEmail'] ?? '',
      startTime: (d['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (d['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: d['status'] ?? 'CONFIRMED',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'stationId': stationId,
        'stationName': stationName,
        'userId': userId,
        'userEmail': userEmail,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'status': status,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };
}