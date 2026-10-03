import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String userEmail;
  final String equipmentName;
  final String equipmentCategory;
  final String equipmentImage;
  final int equipmentPriceKsh;
  final String electricianName;
  final double electricianRating;
  final String address;
  final String status;
  final int bookingFeeKsh;
  final DateTime? createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.equipmentName,
    required this.equipmentCategory,
    required this.equipmentImage,
    required this.equipmentPriceKsh,
    required this.electricianName,
    required this.electricianRating,
    required this.address,
    required this.status,
    required this.bookingFeeKsh,
    this.createdAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      equipmentName: data['equipmentName'] ?? '',
      equipmentCategory: data['equipmentCategory'] ?? '',
      equipmentImage: data['equipmentImage'] ?? '',
      equipmentPriceKsh: (data['equipmentPriceKsh'] ?? 0).toInt(),
      electricianName: data['electricianName'] ?? '',
      electricianRating: (data['electricianRating'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      status: data['status'] ?? 'SCHEDULED',
      bookingFeeKsh: (data['bookingFeeKsh'] ?? 2500).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}