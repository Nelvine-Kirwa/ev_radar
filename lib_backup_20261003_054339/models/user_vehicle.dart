/// A user's saved vehicle — references a Car from the cars collection
/// plus the user-provided plate.
class UserVehicle {
  final String carId;   // Firestore doc id from 'cars' collection
  final String plate;   // e.g. "KDA 123A"
  final String? nickname; // optional, e.g. "Family car"

  const UserVehicle({
    required this.carId,
    required this.plate,
    this.nickname,
  });

  Map<String, dynamic> toMap() => {
        'carId': carId,
        'plate': plate,
        if (nickname != null) 'nickname': nickname,
      };

  factory UserVehicle.fromMap(Map<String, dynamic> m) => UserVehicle(
        carId: m['carId'] ?? '',
        plate: m['plate'] ?? '',
        nickname: m['nickname'],
      );
}